import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/listing_service.dart';
import '../utils/image_crop.dart';
import '../data/meetup_locations.dart';
import 'post_listing_sheet.dart' show DexCardPickerSheet;

/// 輕量批量上架：選多張卡 → 共同欄位(狀態/面交)設一次 → 每張補價格+照片 → 一次送出
class BatchListingSheet extends StatefulWidget {
  final VoidCallback onDone;
  const BatchListingSheet({super.key, required this.onDone});

  @override
  State<BatchListingSheet> createState() => _BatchListingSheetState();
}

class _BatchItem {
  final Map<String, dynamic> card;
  final bool manual;
  final priceCtrl = TextEditingController();
  final certCtrl = TextEditingController();
  final nameCtrl = TextEditingController(); // 手動：卡名
  final setCtrl = TextEditingController();  // 手動：系列
  final numCtrl = TextEditingController();  // 手動：卡號
  XFile? coverImage;                        // 自訂封面（覆蓋圖鑑圖）
  Uint8List? coverBytes;
  final List<XFile> photos = [];            // 內文圖片
  final List<Uint8List> photoBytes = [];
  String rawGrade = 'A';
  String gradeScore = '10';
  _BatchItem(this.card, {this.manual = false});

  String get name => manual ? nameCtrl.text.trim() : (card['name'] as String? ?? '');
  // 從圖鑑選的卡才有預設圖片（raw 用作封面）
  String? get dexImage {
    if (manual) return null;
    final u = card['image_small'] as String?;
    return (u != null && u.isNotEmpty) ? u : null;
  }
  String? get setId => manual
      ? (setCtrl.text.trim().isEmpty ? null : setCtrl.text.trim())
      : card['set_id'] as String?;
  String? get number => manual
      ? (numCtrl.text.trim().isEmpty ? null : numCtrl.text.trim())
      : card['number'] as String?;
}

class _BatchListingSheetState extends State<BatchListingSheet> {
  String _condition = 'raw'; // 共同：raw / graded
  String _gradingCompany = 'PSA'; // 共同鑑定公司
  final List<String> _meetup = [];
  bool _meetupOpen = false;
  final List<_BatchItem> _items = [];
  bool _submitting = false;

  static const _rawGrades = ['A', 'B', 'C', '流通品'];
  static const _companies = ['PSA', 'BGS', 'CGC', 'SGC', 'ACE'];
  static const _scores = {
    'PSA': ['10', '9', '8', '7', '6', '5'],
    'BGS': ['10', '9.5', '9', '8.5', '8'],
    'CGC': ['10', '9.5', '9', '8.5', '8'],
    'SGC': ['10', '9.5', '9', '8.5', '8'],
    'ACE': ['10', '9', '8', '7'],
  };

  Future<void> _addCard() async {
    final picked = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const DexCardPickerSheet(multiSelect: true),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() { for (final c in picked) { _items.add(_BatchItem(c)); } });
  }

  // 手動加入：直接生成一條空白列，之後再補資料
  void _addManual() => setState(() => _items.add(_BatchItem(const {}, manual: true)));

  // 更改封面（換成自己的相片）
  Future<void> _pickCover(_BatchItem it) async {
    final f = await pickAndCropImage(imageQuality: 85);
    if (f == null) return;
    final b = await f.readAsBytes();
    if (!mounted) return;
    setState(() { it.coverImage = f; it.coverBytes = b; });
  }

  // 新增一張內文圖片（最多 4 張）
  Future<void> _addPhoto(_BatchItem it) async {
    if (it.photos.length >= 4) return;
    final f = await pickAndCropImage(imageQuality: 85);
    if (f == null) return;
    final b = await f.readAsBytes();
    if (!mounted) return;
    setState(() { it.photos.add(f); it.photoBytes.add(b); });
  }

  Future<String> _uploadOne(XFile img, Uint8List bytes) async {
    final client = Supabase.instance.client;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'listings/${ts}_${img.name}';
    await client.storage.from('card-images').uploadBinary(
      path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
    return client.storage.from('card-images').getPublicUrl(path);
  }

  Future<void> _submit() async {
    if (_items.isEmpty) { _err('請先加入卡片'); return; }
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.name.isEmpty) { _err('第 ${i + 1} 張未填卡名'); return; }
      if (int.tryParse(it.priceCtrl.text.trim()) == null) { _err('第 ${i + 1} 張未填有效價格'); return; }
      // 封面：自訂 > 圖鑑圖(raw)；沒有就要自己上傳
      final hasCover = it.coverImage != null || (_condition == 'raw' && it.dexImage != null);
      if (!hasCover && it.photos.isEmpty) { _err('第 ${i + 1} 張未上傳圖片'); return; }
    }
    setState(() => _submitting = true);
    int ok = 0;
    for (final it in _items) {
      final coverUrl = it.coverImage != null
          ? await _uploadOne(it.coverImage!, it.coverBytes!)
          : (_condition == 'raw' ? it.dexImage : null);
      final contentUrls = <String>[];
      for (var k = 0; k < it.photos.length; k++) {
        contentUrls.add(await _uploadOne(it.photos[k], it.photoBytes[k]));
      }
      final grade = _condition == 'raw' ? it.rawGrade : '$_gradingCompany ${it.gradeScore}';
      final done = await ListingService.insertListing(
        name: it.name,
        grade: grade,
        condition: _condition == 'raw' ? 'Raw' : 'Graded',
        price: int.parse(it.priceCtrl.text.trim()),
        imageUrls: [
          if (coverUrl != null) coverUrl, // 封面放最前
          ...contentUrls,
        ],
        setId: it.setId?.toLowerCase(),
        cardNumber: it.number,
        psaCert: (_condition == 'graded' && _gradingCompany == 'PSA' && it.certCtrl.text.trim().isNotEmpty)
            ? it.certCtrl.text.trim() : null,
        cachedCardId: it.manual ? null : it.card['id'] as String?,
        meetupLocations: _meetup,
      );
      if (done) ok++;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('已上架 $ok / ${_items.length} 張'),
      backgroundColor: const Color(0xFF16A34A)));
    widget.onDone();
    Navigator.pop(context);
  }

  void _err(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFFDC2626)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5, foregroundColor: const Color(0xFF111827),
        title: const Text('批量上架', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8A52A)))
                  : Text('上架(${_items.length})', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE8A52A))),
            )),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ── 共同欄位 ──
        _label('共同設定（套用到所有卡）'),
        const SizedBox(height: 8),
        Row(children: [
          _seg('raw', '未鑑定 (Raw)'), const SizedBox(width: 8), _seg('graded', '鑑定卡'),
        ]),
        if (_condition == 'graded') ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: _companies.map((c) {
            final on = _gradingCompany == c;
            return GestureDetector(
              onTap: () => setState(() {
                _gradingCompany = c;
                for (final it in _items) {
                  if (!(_scores[c] ?? []).contains(it.gradeScore)) it.gradeScore = (_scores[c] ?? ['10']).first;
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: on ? const Color(0xFF2980B9) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                child: Text(c, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? Colors.white : const Color(0xFF6B7280))),
              ),
            );
          }).toList()),
        ],
        const SizedBox(height: 14),
        _meetupPicker(),
        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // ── 每張卡 ──
        _label('卡片（每張填價格 + 圖片）'),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((e) => _cardRow(e.key, e.value)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _addCard,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9EC), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8A52A), width: 1)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add, size: 18, color: Color(0xFFE8A52A)),
                SizedBox(width: 6),
                Text('從圖鑑加入', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFFB8860B))),
              ]),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: _addManual,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B7280)),
                SizedBox(width: 6),
                Text('手動加入', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)));

  Widget _seg(String v, String label) {
    final on = _condition == v;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _condition = v),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: on ? Colors.white : const Color(0xFF6B7280))),
      ),
    ));
  }

  Widget _meetupPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 標題列：點一下展開/收合
      GestureDetector(
        onTap: () => setState(() => _meetupOpen = !_meetupOpen),
        behavior: HitTestBehavior.opaque,
        child: Row(children: [
          Expanded(child: _label('面交地點（選填，套用全部）'
              '${_meetup.isNotEmpty ? '  已選 ${_meetup.length}' : ''}')),
          Icon(_meetupOpen ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF9CA3AF)),
        ]),
      ),
      const SizedBox(height: 8),
      if (!_meetupOpen && _meetup.isNotEmpty)
        // 收合時只顯示已選的
        Wrap(spacing: 6, runSpacing: 6, children: _meetup.map((loc) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8A52A), borderRadius: BorderRadius.circular(20)),
          child: Text(loc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        )).toList()),
      if (_meetupOpen) ...[
        for (final region in kMeetupRegions.entries) ...[
          Text(region.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: region.value.map((loc) {
            final on = _meetup.contains(loc);
            return GestureDetector(
              onTap: () => setState(() { on ? _meetup.remove(loc) : _meetup.add(loc); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: on ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? const Color(0xFFE8A52A) : const Color(0xFFE5E7EB))),
                child: Text(loc, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: on ? Colors.white : const Color(0xFF6B7280))),
              ),
            );
          }).toList()),
          const SizedBox(height: 10),
        ],
        // 收起按鈕
        Center(child: TextButton(
          onPressed: () => setState(() => _meetupOpen = false),
          child: const Text('收起', style: TextStyle(color: Color(0xFFE8A52A), fontWeight: FontWeight.w600)),
        )),
      ],
    ]);
  }

  Widget _cardRow(int i, _BatchItem it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEDEFF2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: it.manual
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(controller: it.nameCtrl,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        labelText: '卡片名稱（點此輸入）',
                        hintText: '例：Pikachu ex',
                        isDense: true,
                        prefixIcon: Icon(Icons.edit, size: 15, color: Color(0xFFE8A52A)),
                        prefixIconConstraints: BoxConstraints(minWidth: 26),
                      )),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: TextField(controller: it.setCtrl,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(labelText: '系列(選填)', isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: it.numCtrl,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(labelText: '卡號(選填)', isDense: true))),
                  ]),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.card['name'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if ((it.card['set_id'] ?? it.card['number']) != null)
                    Text('${it.card['set_id'] ?? ''}${it.card['number'] != null ? ' · ${it.card['number']}' : ''}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
          GestureDetector(onTap: () => setState(() => _items.removeAt(i)), child: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF))),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 封面（點擊更改成自己的相片）
          GestureDetector(
            onTap: () => _pickCover(it),
            child: Container(
              width: 64, height: 88,
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD1D5DB))),
              clipBehavior: Clip.antiAlias,
              child: it.coverBytes != null
                  ? Stack(fit: StackFit.expand, children: [
                      Image.memory(it.coverBytes!, fit: BoxFit.cover),
                      _coverTag('封面'),
                    ])
                  : (_condition == 'raw' && it.dexImage != null
                      ? Stack(fit: StackFit.expand, children: [
                          Image.network(it.dexImage!, fit: BoxFit.cover),
                          _coverTag('圖鑑封面'),
                        ])
                      : const Icon(Icons.add_a_photo_outlined, size: 22, color: Color(0xFF9CA3AF))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: it.priceCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: 'HK\$ ', hintText: '價格', isDense: true),
            ),
            const SizedBox(height: 6),
            if (_condition == 'raw')
              Wrap(spacing: 6, children: _rawGrades.map((g) {
                final on = it.rawGrade == g;
                return GestureDetector(
                  onTap: () => setState(() => it.rawGrade = g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: on ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                    child: Text(g, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: on ? Colors.white : const Color(0xFF6B7280))),
                  ),
                );
              }).toList())
            else ...[
              Wrap(spacing: 6, children: (_scores[_gradingCompany] ?? []).map((s) {
                final on = it.gradeScore == s;
                return GestureDetector(
                  onTap: () => setState(() => it.gradeScore = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: on ? const Color(0xFF2980B9) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                    child: Text('$_gradingCompany $s', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: on ? Colors.white : const Color(0xFF6B7280))),
                  ),
                );
              }).toList()),
              if (_gradingCompany == 'PSA') ...[
                const SizedBox(height: 6),
                TextField(controller: it.certCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'PSA Cert（選填）', isDense: true)),
              ],
            ],
          ])),
        ]),
        const SizedBox(height: 8),
        _contentStrip(it),
      ]),
    );
  }

  // 封面小標籤
  Widget _coverTag(String t) => Positioned(left: 0, right: 0, bottom: 0, child: Container(
    color: Colors.black54, padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(t, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w600)),
  ));

  // 內文圖片：縮圖 + 新增
  Widget _contentStrip(_BatchItem it) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Text('內文圖', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      const SizedBox(width: 6),
      Expanded(child: SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var k = 0; k < it.photos.length; k++)
            Padding(padding: const EdgeInsets.only(right: 6), child: Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(6),
                  child: Image.memory(it.photoBytes[k], width: 40, height: 40, fit: BoxFit.cover)),
              Positioned(top: -4, right: -4, child: GestureDetector(
                onTap: () => setState(() { it.photos.removeAt(k); it.photoBytes.removeAt(k); }),
                child: Container(width: 16, height: 16,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 10, color: Colors.white)),
              )),
            ])),
          if (it.photos.length < 4)
            GestureDetector(onTap: () => _addPhoto(it), child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD1D5DB))),
              child: const Icon(Icons.add, size: 18, color: Color(0xFF9CA3AF)),
            )),
        ]),
      )),
    ]);
  }
}
