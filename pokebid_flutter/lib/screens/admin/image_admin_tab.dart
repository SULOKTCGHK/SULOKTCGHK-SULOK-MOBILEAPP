import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/supabase_service.dart';
import '../../utils/image_crop.dart';
import '../../data/series_options.dart';
import 'admin_set_cards_screen.dart';

/// 後台圖片管理：像圖鑑一樣瀏覽系列 → 改 logo 或進去管理卡片圖
class ImageAdminTab extends StatefulWidget {
  const ImageAdminTab({super.key});
  @override
  State<ImageAdminTab> createState() => _ImageAdminTabState();
}

class _ImageAdminTabState extends State<ImageAdminTab> {
  final _searchCtrl = TextEditingController();
  bool _onlyMissing = false;
  List<Map<String, dynamic>> _sets = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await SupabaseService.getCachedSets();
    final kw = _searchCtrl.text.trim().toLowerCase();
    var list = all;
    if (_onlyMissing) {
      list = list.where((s) => (s['logo_image'] as String?)?.isNotEmpty != true).toList();
    }
    if (kw.isNotEmpty) {
      list = list.where((s) => (s['name'] as String? ?? '').toLowerCase().contains(kw)
          || (s['id'] as String).toLowerCase().contains(kw)).toList();
    }
    if (mounted) setState(() { _sets = list; _loading = false; });
  }

  Future<void> _changeLogo(Map<String, dynamic> s) async {
    final file = await pickAndCropImage(imageQuality: 90);
    if (file == null) return;
    setState(() => _busyId = s['id'] as String);
    final bytes = await file.readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final branch = setBranch(s['id'] as String, s['name'] as String? ?? '');
    final cat = (s['series_id'] as String?)?.isNotEmpty == true ? s['series_id'] : 'uncategorized';
    final url = await SupabaseService.uploadAdminImage(bytes, '$branch/$cat/${s['id']}/logo_$ts.jpg');
    final ok = url != null && await SupabaseService.setSetLogo(s['id'] as String, url);
    if (!mounted) return;
    setState(() => _busyId = null);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '已更新系列 logo' : '上傳失敗（確認你是 admin）')));
    if (ok) _load();
  }

  // 新增 / 編輯系列（含分類 series_id）。existing 為 null = 新增
  Future<void> _editSet(Map<String, dynamic>? existing) async {
    final isNew = existing == null;
    final idCtrl = TextEditingController(text: existing?['id'] as String? ?? '');
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    String seriesId = (existing?['series_id'] as String?) ??
        (kSeriesOptions.keys.isNotEmpty ? kSeriesOptions.keys.first : 'sv');
    if (!kSeriesOptions.containsKey(seriesId)) seriesId = kSeriesOptions.keys.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isNew ? '新增系列' : '編輯系列', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: idCtrl, enabled: isNew,
                  decoration: const InputDecoration(labelText: '系列 ID（唯一，如 m2-inferno-x-...）', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '系列名稱', isDense: true)),
              const SizedBox(height: 14),
              const Text('分類（歸到哪個系列）', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              DropdownButton<String>(
                value: seriesId, isExpanded: true,
                items: kSeriesOptions.entries.map((e) =>
                    DropdownMenuItem(value: e.key, child: Text('${e.value}（${e.key}）', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setD(() => seriesId = v ?? seriesId),
              ),
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
      ),
    );
    if (ok != true) return;
    final id = idCtrl.text.trim();
    if (id.isEmpty || nameCtrl.text.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請填 系列 ID 與名稱')));
      return;
    }
    final row = {
      'id': id,
      'name': nameCtrl.text.trim(),
      'series': kSeriesOptions[seriesId],
      'series_id': seriesId,
      'language': existing?['language'] ?? 'ja',
      'cached_at': DateTime.now().millisecondsSinceEpoch,
      if (existing?['logo_image'] != null) 'logo_image': existing!['logo_image'],
    };
    final saved = await SupabaseService.saveCachedSet(row);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved ? (isNew ? '已新增系列' : '已更新系列') : '儲存失敗（確認你是 admin）')));
    if (saved) _load();
  }

  void _onTapSet(Map<String, dynamic> s) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Text(s['name'] as String? ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
        ListTile(
          leading: const Icon(Icons.edit_outlined, color: Color(0xFF16A34A)),
          title: const Text('編輯系列資料 / 分類'),
          onTap: () { Navigator.pop(ctx); _editSet(s); },
        ),
        ListTile(
          leading: const Icon(Icons.image_outlined, color: Color(0xFFE8A52A)),
          title: const Text('更換系列 logo'),
          onTap: () { Navigator.pop(ctx); _changeLogo(s); },
        ),
        ListTile(
          leading: const Icon(Icons.style_outlined, color: Color(0xFF2980B9)),
          title: const Text('管理此系列的卡片圖'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) =>
                AdminSetCardsScreen(
                    setId: s['id'] as String,
                    setName: s['name'] as String? ?? '',
                    seriesId: s['series_id'] as String? ?? '')));
          },
        ),
        const SizedBox(height: 8),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: '搜尋系列', prefixIcon: const Icon(Icons.search, size: 20),
              filled: true, fillColor: Colors.white, isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () { setState(() => _onlyMissing = !_onlyMissing); _load(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: _onlyMissing ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10)),
              child: Text('只看缺logo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: _onlyMissing ? Colors.white : const Color(0xFF6B7280))),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _editSet(null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 15, color: Colors.white),
                SizedBox(width: 2),
                Text('系列', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
            : _sets.isEmpty
                ? const Center(child: Text('無符合系列', style: TextStyle(color: Color(0xFF9CA3AF))))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82),
                    itemCount: _sets.length,
                    itemBuilder: (_, i) => _setCard(_sets[i]),
                  ),
      ),
    ]);
  }

  Widget _setCard(Map<String, dynamic> s) {
    final logo = s['logo_image'] as String?;
    final busy = _busyId == s['id'];
    return GestureDetector(
      onTap: () => _onTapSet(s),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDEFF2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: Container(
            decoration: const BoxDecoration(color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(13))),
            clipBehavior: Clip.antiAlias,
            child: busy
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8A52A)))
                : (logo != null && logo.isNotEmpty)
                    ? CachedNetworkImage(imageUrl: logo, fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Color(0xFFD1D5DB)))
                    : const Center(child: Icon(Icons.image_not_supported_outlined, size: 28, color: Color(0xFFD1D5DB))),
          )),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(s['name'] as String? ?? s['id'] as String,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}
