import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';

/// 管理某系列的卡片圖（像圖鑑卡片格，點卡可換圖）
class AdminSetCardsScreen extends StatefulWidget {
  final String setId;
  final String setName;
  const AdminSetCardsScreen({super.key, required this.setId, required this.setName});

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

  Future<void> _changeImage(Map<String, dynamic> c) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    setState(() => _busyId = c['id'] as String);
    final bytes = await file.readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = await SupabaseService.uploadAdminImage(bytes, 'admin/card_${c['id']}_$ts.jpg');
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
      onTap: busy ? null : () => _changeImage(c),
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
