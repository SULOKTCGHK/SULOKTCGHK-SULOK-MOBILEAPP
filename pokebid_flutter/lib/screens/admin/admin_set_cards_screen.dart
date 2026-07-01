import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/image_crop.dart';
import '../../data/series_options.dart';
import '../../services/supabase_service.dart';

/// 管理某系列的卡片圖（像圖鑑卡片格，點卡可換圖）
class AdminSetCardsScreen extends StatefulWidget {
  final String setId;
  final String setName;
  final String seriesId; // 分類（storage 資料夾用）
  const AdminSetCardsScreen({super.key, required this.setId, required this.setName, this.seriesId = ''});

  @override
  State<AdminSetCardsScreen> createState() => _AdminSetCardsScreenState();
}

class _AdminSetCardsScreenState extends State<AdminSetCardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;
  bool _onlyMissing = false;
  String? _busyId;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await SupabaseService.getCachedCardsForSet(widget.setId);
    if (mounted) setState(() { _cards = res; _loading = false; });
  }

  List<Map<String, dynamic>> get _shown => _onlyMissing
      ? _cards.where((c) => (c['image_small'] as String?)?.isNotEmpty != true).toList()
      : _cards;

  void _onTapCard(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(c['name'] as String? ?? '',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFF16A34A)),
            title: const Text('編輯卡片資料'),
            onTap: () { Navigator.pop(ctx); _editCard(c); },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move_outline, color: Color(0xFF8B5CF6)),
            title: const Text('移到其他系列'),
            onTap: () { Navigator.pop(ctx); _moveCard(c); },
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined, color: Color(0xFFE8A52A)),
            title: const Text('更換卡片圖'),
            onTap: () { Navigator.pop(ctx); _changeImage(c); },
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined, color: Color(0xFF2980B9)),
            title: const Text('設定 PSA SpecID'),
            subtitle: Text(c['psa_spec_id'] as String? ?? '未設定',
                style: const TextStyle(fontSize: 12)),
            onTap: () { Navigator.pop(ctx); _setPsaSpecId(c); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _setPsaSpecId(Map<String, dynamic> c) async {
    final ctrl = TextEditingController(text: c['psa_spec_id'] as String? ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('PSA SpecID\n${c['name']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '輸入 PSA SpecID',
              filled: true, fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          const Text('儲存後會自動抓取 PSA Pop 數量',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8A52A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('儲存並抓取', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final specId = ctrl.text.trim();
    if (specId.isEmpty) return;

    setState(() => _busyId = c['id'] as String);
    final okSpec = await SupabaseService.setCardSpecId(c['id'] as String, specId);
    if (!okSpec) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定失敗')));
      }
      setState(() => _busyId = null);
      return;
    }
    // 觸發 edge function 抓 pop
    final pop = await SupabaseService.fetchPsaPop(specId);
    if (!mounted) return;
    setState(() {
      _busyId = null;
      c['psa_spec_id'] = specId;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pop != null
          ? 'PSA Pop 抓取成功！PSA 10: ${pop['pop_10']}'
          : 'SpecID 已儲存，但 Pop 抓取失敗（確認 SpecID 正確）'),
    ));
  }

  // 新增 / 編輯卡片資料。existing 為 null = 新增
  Future<void> _editCard(Map<String, dynamic>? existing) async {
    final isNew = existing == null;
    final numCtrl = TextEditingController(text: existing?['number'] as String? ?? '');
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final rarityCtrl = TextEditingController(text: existing?['rarity'] as String? ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isNew ? '新增卡片' : '編輯卡片', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: numCtrl, decoration: const InputDecoration(labelText: '卡號（如 110/80）', isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '卡片名稱', isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: rarityCtrl, decoration: const InputDecoration(labelText: '稀有度（選填）', isDense: true)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8A52A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('儲存', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok != true) return;
    final num = numCtrl.text.trim();
    final name = nameCtrl.text.trim();
    if (num.isEmpty || name.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請填 卡號 與 名稱')));
      return;
    }
    final id = existing?['id'] as String? ?? '${widget.setId}-$num';
    final row = {
      'id': id,
      'name': name,
      'number': num,
      'rarity': rarityCtrl.text.trim(),
      'set_id': widget.setId,
      'set_name': widget.setName,
      'language': existing?['language'] ?? 'ja',
      'cached_at': DateTime.now().millisecondsSinceEpoch,
      if (existing?['image_small'] != null) 'image_small': existing!['image_small'],
      if (existing?['image_large'] != null) 'image_large': existing!['image_large'],
    };
    final saved = await SupabaseService.saveCachedCard(row);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved ? (isNew ? '已新增卡片' : '已更新卡片') : '儲存失敗（確認你是 admin）')));
    if (saved) _load();
  }

  // 把卡片移到其他系列
  Future<void> _moveCard(Map<String, dynamic> c) async {
    final sets = await SupabaseService.getCachedSets();
    if (!mounted) return;
    final searchCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final kw = searchCtrl.text.trim().toLowerCase();
        final list = kw.isEmpty ? sets : sets.where((s) =>
            (s['name'] as String? ?? '').toLowerCase().contains(kw) ||
            (s['id'] as String).toLowerCase().contains(kw)).toList();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(children: [
              const Padding(padding: EdgeInsets.all(14),
                  child: Text('移到其他系列', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(controller: searchCtrl, onChanged: (_) => setS(() {}),
                    decoration: const InputDecoration(hintText: '搜尋系列', prefixIcon: Icon(Icons.search, size: 20), isDense: true))),
              const SizedBox(height: 8),
              Expanded(child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final s = list[i];
                  return ListTile(
                    title: Text(s['name'] as String? ?? s['id'] as String, style: const TextStyle(fontSize: 13.5)),
                    subtitle: Text(s['id'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    onTap: () => Navigator.pop(ctx, s),
                  );
                })),
            ])),
        );
      }),
    ).then((picked) async {
      if (picked == null) return;
      final s = picked as Map<String, dynamic>;
      final ok = await SupabaseService.updateCardSet(
          c['id'] as String, s['id'] as String, s['name'] as String? ?? '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? '已移至「${s['name']}」' : '移動失敗')));
      if (ok) _load();
    });
  }

  Future<void> _changeImage(Map<String, dynamic> c) async {
    final file = await pickAndCropImage(imageQuality: 90);
    if (file == null) return;
    setState(() => _busyId = c['id'] as String);
    final bytes = await file.readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final branch = setBranch(widget.setId, widget.setName);
    final cat = widget.seriesId.isNotEmpty ? widget.seriesId : 'uncategorized';
    final url = await SupabaseService.uploadAdminImage(
        bytes, '$branch/$cat/${widget.setId}/${c['id']}_$ts.jpg');
    final ok = url != null && await SupabaseService.setCardImage(c['id'] as String, url);
    if (!mounted) return;
    setState(() {
      _busyId = null;
      if (ok) c['image_small'] = url; // 即時更新縮圖
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '已更新卡片圖' : '上傳失敗（確認你是 admin）')));
  }

  @override
  Widget build(BuildContext context) {
    final list = _shown;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5, foregroundColor: const Color(0xFF111827),
        title: Text(widget.setName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => setState(() => _onlyMissing = !_onlyMissing),
              child: Text(_onlyMissing ? '全部' : '只看缺圖',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFFE8A52A), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF16A34A),
        onPressed: () => _editCard(null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增卡片', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
          : list.isEmpty
              ? const Center(child: Text('無卡片', style: TextStyle(color: Color(0xFF9CA3AF))))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.66),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _cardTile(list[i]),
                ),
    );
  }

  Widget _cardTile(Map<String, dynamic> c) {
    final img = c['image_small'] as String?;
    final busy = _busyId == c['id'];
    return GestureDetector(
      onTap: busy ? null : () => _onTapCard(c),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEDEFF2))),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: Stack(fit: StackFit.expand, children: [
            Container(color: const Color(0xFFF9FAFB),
              child: busy
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8A52A)))
                  : (img != null && img.isNotEmpty)
                      ? CachedNetworkImage(imageUrl: img, fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Color(0xFFE74C3C))))
                      : const Center(child: Icon(Icons.image_not_supported_outlined, size: 22, color: Color(0xFFD1D5DB)))),
            const Positioned(right: 4, bottom: 4,
                child: CircleAvatar(radius: 11, backgroundColor: Colors.black54,
                    child: Icon(Icons.edit, size: 12, color: Colors.white))),
          ])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Text(c['name'] as String? ?? '',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}
