import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import '../services/listing_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../data/set_name_zh.dart';

class PostListingSheet extends StatefulWidget {
  final Function(PokemonCard) onSubmit;

  const PostListingSheet({super.key, required this.onSubmit});

  @override
  State<PostListingSheet> createState() => _PostListingSheetState();
}

class _PostListingSheetState extends State<PostListingSheet> {
  // 商品類型
  String _cardCondition = 'raw'; // 'raw' or 'graded'

  // 鑑定資訊
  String _gradingCompany = 'PSA';
  String _gradeScore = '10';

  bool _submitting = false;
  final List<String> _meetupLocations = [];
  final List<XFile> _images = [];
  final List<Uint8List> _imageBytes = [];
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85, limit: 4);
    if (picked.isNotEmpty) {
      final newImages = picked.take(4 - _images.length).toList();
      final newBytes = await Future.wait(newImages.map((x) => x.readAsBytes()));
      setState(() {
        _images.addAll(newImages);
        _imageBytes.addAll(newBytes);
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    final client = Supabase.instance.client;
    final List<String> urls = [];
    for (final img in _images) {
      final bytes = await img.readAsBytes();
      final ext = img.name.split('.').last.toLowerCase();
      final path = 'listings/${DateTime.now().millisecondsSinceEpoch}_${img.name}';
      await client.storage.from('card-images').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );
      final url = client.storage.from('card-images').getPublicUrl(path);
      urls.add(url);
    }
    return urls;
  }

  // 從圖鑑選卡（選填）
  Map<String, dynamic>? _selectedDexCard; // cached_cards 行

  // 表單
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _setIdCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _setSearchCtrl = TextEditingController();
  final _certCtrl = TextEditingController();
  bool _showSetPicker = false;
  String _setSearchQuery = '';

  // 從 kSetNameZh 生成可選清單
  List<MapEntry<String, String>> get _filteredSets {
    final q = _setSearchQuery.toLowerCase();
    return kSetNameZh.entries.where((e) =>
        q.isEmpty ||
        e.key.toLowerCase().contains(q) ||
        e.value.contains(q)).toList();
  }

  final List<String> _gradingCompanies = ['PSA', 'BGS', 'CGC', 'SGC', 'ACE'];

  final Map<String, List<String>> _gradeScores = {
    'PSA': ['10', '9', '8', '7', '6', '5', '4', '3', '2', '1'],
    'BGS': ['10', '9.5', '9', '8.5', '8', '7.5', '7', '6.5', '6'],
    'CGC': ['10', '9.5', '9', '8.5', '8', '7.5', '7', '6.5', '6'],
    'SGC': ['10', '9.5', '9', '8.5', '8', '7.5', '7'],
    'ACE': ['10', '9', '8', '7', '6', '5'],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _setIdCtrl.dispose();
    _cardNumberCtrl.dispose();
    _setSearchCtrl.dispose();
    _certCtrl.dispose();
    super.dispose();
  }

  // 從圖鑑選卡
  Future<void> _pickFromDex() async {
    final card = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DexCardPickerSheet(),
    );
    if (card == null || !mounted) return;
    setState(() {
      _selectedDexCard = card;
      _nameCtrl.text = card['name'] as String? ?? '';
      _setIdCtrl.text = card['set_id'] as String? ?? '';
      _cardNumberCtrl.text = card['number'] as String? ?? '';
    });
  }

  void _clearDexCard() {
    setState(() {
      _selectedDexCard = null;
      _nameCtrl.clear();
      _setIdCtrl.clear();
      _cardNumberCtrl.clear();
    });
  }

  // 背景抓取 PSA Pop（不阻塞 UI）
  void _fetchPsaPopByCert(String cert) {
    SupabaseService.fetchPsaPopByCert(
      cert,
      cachedCardId: _selectedDexCard?['id'] as String?,
      setId: _setIdCtrl.text.trim().isEmpty ? null : _setIdCtrl.text.trim().toLowerCase(),
      cardNumber: _cardNumberCtrl.text.trim().isEmpty ? null : _cardNumberCtrl.text.trim(),
    );
  }

  String get _gradeLabel {
    if (_cardCondition == 'raw') return 'Raw';
    return '$_gradingCompany $_gradeScore';
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text);
    if (name.isEmpty) { _showError('請輸入卡牌名稱'); return; }
    if (price == null || price < 1) { _showError('請輸入有效價格'); return; }

    setState(() => _submitting = true);

    final imageUrls = await _uploadImages();

    final ok = await ListingService.insertListing(
      name: name,
      grade: _gradeLabel,
      condition: _cardCondition == 'raw' ? 'Raw' : 'Graded',
      price: price,
      description: _descCtrl.text.trim(),
      imageUrls: imageUrls,
      setId: _setIdCtrl.text.trim().isEmpty ? null : _setIdCtrl.text.trim().toLowerCase(),
      cardNumber: _cardNumberCtrl.text.trim().isEmpty ? null : _cardNumberCtrl.text.trim(),
      psaCert: (_cardCondition == 'graded' && _gradingCompany == 'PSA')
          ? (_certCtrl.text.trim().isEmpty ? null : _certCtrl.text.trim())
          : null,
      cachedCardId: _selectedDexCard?['id'] as String?,
      meetupLocations: _meetupLocations,
    );

    // 若有 PSA cert，背景抓取 Pop（不阻塞上架流程）
    final cert = _certCtrl.text.trim();
    if (ok && cert.isNotEmpty && _gradingCompany == 'PSA') {
      _fetchPsaPopByCert(cert);
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) { _showError('上架失敗，請稍後再試'); return; }

    // Pass a placeholder card so onSubmit callback triggers the refresh
    widget.onSubmit(PokemonCard(
      id: 0, name: name, grade: _gradeLabel,
      type: CardType.normal, price: price,
      condition: _cardCondition == 'raw' ? 'Raw' : 'Graded',
      seller: Seller(
        name: AuthService.isLoggedIn ? AuthService.displayName : '匿名賣家',
        rating: 5.0, sales: 0,
      ),
      listingType: ListingType.fixedPrice,
      timeInfo: '剛上架',
    ));
    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE74C3C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(children: [
                  const Text('上架掛售',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo upload
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_images.isNotEmpty) ...[
                            SizedBox(
                              height: 90,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length + (_images.length < 4 ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  if (i == _images.length) {
                                    return GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 80, height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                                        ),
                                        child: const Icon(Icons.add, color: Color(0xFF9CA3AF), size: 28),
                                      ),
                                    );
                                  }
                                  return Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        _imageBytes[i],
                                        width: 80, height: 80, fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2, right: 2,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _images.removeAt(i);
                                          _imageBytes.removeAt(i);
                                        }),
                                        child: Container(
                                          width: 20, height: 20,
                                          decoration: const BoxDecoration(
                                            color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 12),
                                        ),
                                      ),
                                    ),
                                  ]);
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${_images.length}/4 張照片',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          ] else
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                                ),
                                child: const Column(children: [
                                  Icon(Icons.add_a_photo_outlined, size: 28, color: Color(0xFF9CA3AF)),
                                  SizedBox(height: 6),
                                  Text('上傳卡牌照片（最多4張）',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                                ]),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 從圖鑑選卡（選填）
                      if (_selectedDexCard != null)
                        _DexCardChip(
                          card: _selectedDexCard!,
                          onClear: _clearDexCard,
                        )
                      else
                        GestureDetector(
                          onTap: _pickFromDex,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF9EC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                            ),
                            child: Row(children: [
                              const Icon(Icons.search, size: 16, color: Color(0xFFE8A52A)),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('從圖鑑選卡（選填）',
                                  style: TextStyle(fontSize: 13, color: Color(0xFFB45309), fontWeight: FontWeight.w500))),
                              const Icon(Icons.chevron_right, size: 16, color: Color(0xFFE8A52A)),
                            ]),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Card name
                      _label('卡牌名稱'),
                      _textField(_nameCtrl, '例如：リザードン ex / 初版 リザードン'),
                      const SizedBox(height: 16),

                      // ── 商品類型 ──────────────────────────────────────
                      _label('商品類型'),
                      Row(children: [
                        Expanded(
                          child: _conditionBtn(
                            value: 'raw',
                            label: 'RAW 未鑑定',
                            icon: Icons.style_outlined,
                            desc: '原卡，未經鑑定',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _conditionBtn(
                            value: 'graded',
                            label: '鑑定卡',
                            icon: Icons.verified_outlined,
                            desc: 'PSA / BGS / CGC 等',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── 鑑定資訊（只在鑑定卡時顯示）────────────────
                      if (_cardCondition == 'graded') ...[
                        _label('鑑定公司'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _gradingCompanies.map((company) {
                              final active = _gradingCompany == company;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _gradingCompany = company;
                                  // Reset score if not available
                                  final scores = _gradeScores[company] ?? [];
                                  if (!scores.contains(_gradeScore)) {
                                    _gradeScore = scores.first;
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? const Color(0xFFE8A52A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: active
                                          ? const Color(0xFFE8A52A)
                                          : const Color(0xFFD1D5DB),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    company,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.white
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _label('鑑定分數'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_gradeScores[_gradingCompany] ?? []).map((score) {
                            final active = _gradeScore == score;
                            // Highlight PSA 10 / BGS 9.5+ as special
                            final isTop = score == '10' ||
                                score == '9.5' && _gradingCompany != 'PSA';
                            return GestureDetector(
                              onTap: () => setState(() => _gradeScore = score),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 62,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFFE8A52A)
                                      : (isTop
                                          ? const Color(0xFFFEF9EC)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: active
                                        ? const Color(0xFFE8A52A)
                                        : (isTop
                                            ? const Color(0xFFFDE68A)
                                            : const Color(0xFFE5E7EB)),
                                    width: active ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      score,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? Colors.white
                                            : (isTop
                                                ? const Color(0xFFE8A52A)
                                                : const Color(0xFF374151)),
                                      ),
                                    ),
                                    if (isTop && !active) ...[
                                      const SizedBox(height: 2),
                                      Text('★',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: const Color(0xFFE8A52A)
                                                  .withOpacity(0.7))),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),

                        // Grade preview
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFBBF7D0), width: 0.5),
                          ),
                          child: Row(children: [
                            const Icon(Icons.verified, size: 16,
                                color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              '鑑定等級：$_gradingCompany $_gradeScore',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),

                        // PSA Cert Number（選填，只限 PSA）
                        if (_gradingCompany == 'PSA') ...[
                          Row(children: [
                            const Text('PSA Cert Number',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151))),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(4)),
                              child: const Text('選填',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _certCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: '例：12345678',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                              prefixIcon: const Icon(Icons.numbers, size: 18, color: Color(0xFF9CA3AF)),
                              filled: true, fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('輸入後系統自動抓取 PSA Pop · 同時填寫系列 + 卡號可讓圖鑑也顯示 Pop',
                              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          const SizedBox(height: 12),
                        ],
                      ],

                      // Price
                      _label('直購價格 (HK\$)'),
                      _textField(_priceCtrl, '0', isNumber: true),
                      const SizedBox(height: 14),

                      // ── 系列 + 卡號（選填）─────────────────────────────
                      _label('系列 + 卡號（選填）'),
                      _setAndNumberRow(),
                      const SizedBox(height: 14),

                      // Description
                      _label('商品說明（選填）'),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF111827)),
                        decoration: InputDecoration(
                          hintText: '版本資訊、包裝狀況、交易方式...',
                          hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB), width: 0.5)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB), width: 0.5)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE8A52A), width: 1)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 面交地點
                      _MeetupLocationPicker(
                        selected: _meetupLocations,
                        onChanged: (locs) => setState(() {
                          _meetupLocations
                            ..clear()
                            ..addAll(locs);
                        }),
                      ),
                      const SizedBox(height: 20),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8A52A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('確認上架',
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _conditionBtn({
    required String value,
    required String label,
    required IconData icon,
    required String desc,
  }) {
    final active = _cardCondition == value;
    return GestureDetector(
      onTap: () => setState(() => _cardCondition = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFEF9EC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFFE8A52A) : const Color(0xFFE5E7EB),
            width: active ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon,
                  size: 20,
                  color: active
                      ? const Color(0xFFE8A52A)
                      : const Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? const Color(0xFFE8A52A)
                          : const Color(0xFF374151),
                    )),
              ),
              if (active)
                const Icon(Icons.check_circle,
                    size: 16, color: Color(0xFFE8A52A)),
            ]),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _setAndNumberRow() {
    final selectedName = _setIdCtrl.text.isNotEmpty
        ? kSetNameZh[_setIdCtrl.text.toLowerCase()] ?? _setIdCtrl.text.toUpperCase()
        : null;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 系列 selector
      Expanded(
        flex: 3,
        child: GestureDetector(
          onTap: _openSetPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _setIdCtrl.text.isNotEmpty
                    ? const Color(0xFFE8A52A)
                    : const Color(0xFFD1D5DB),
                width: _setIdCtrl.text.isNotEmpty ? 1 : 0.5,
              ),
            ),
            child: Row(children: [
              Expanded(child: selectedName != null
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, children: [
                      Text(selectedName,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827))),
                      Text(_setIdCtrl.text.toUpperCase(),
                          style: const TextStyle(fontSize: 10,
                              color: Color(0xFFE8A52A))),
                    ])
                  : const Text('選擇系列',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))),
              Icon(Icons.expand_more,
                  size: 18,
                  color: _setIdCtrl.text.isNotEmpty
                      ? const Color(0xFFE8A52A)
                      : const Color(0xFF9CA3AF)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 10),
      // 卡號 input
      Expanded(
        flex: 2,
        child: TextField(
          controller: _cardNumberCtrl,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: '卡號，如 217',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    ]);
  }

  void _openSetPicker() {
    _setSearchCtrl.clear();
    setState(() => _setSearchQuery = '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            // Handle
            Container(margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2))),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: [
                const Text('選擇系列',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
                const Spacer(),
                if (_setIdCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() => _setIdCtrl.clear());
                      Navigator.pop(ctx);
                    },
                    child: const Text('清除',
                        style: TextStyle(fontSize: 13, color: Color(0xFFE74C3C))),
                  ),
              ]),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _setSearchCtrl,
                autofocus: true,
                onChanged: (v) => setModalState(() => _setSearchQuery = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '搜尋系列名稱或 ID，如 sv8a',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _filteredSets.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 0.5, color: Color(0xFFF3F4F6)),
                itemBuilder: (_, i) {
                  final entry = _filteredSets[i];
                  final selected = _setIdCtrl.text == entry.key;
                  return InkWell(
                    onTap: () {
                      setState(() => _setIdCtrl.text = entry.key);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFE8A52A)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(entry.key.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              )),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(entry.value,
                            style: const TextStyle(fontSize: 14,
                                color: Color(0xFF111827)))),
                        if (selected)
                          const Icon(Icons.check_circle,
                              size: 18, color: Color(0xFFE8A52A)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151))),
  );

  Widget _textField(TextEditingController ctrl, String hint,
      {bool isNumber = false}) =>
      TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFD1D5DB), width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFD1D5DB), width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE8A52A), width: 1)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

// 已選卡片的顯示 chip
class _DexCardChip extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onClear;
  const _DexCardChip({required this.card, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final img = card['image_small'] as String?;
    final name = card['name'] as String? ?? '';
    final setId = card['set_id'] as String? ?? '';
    final number = card['number'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(children: [
        if (img != null && img.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(img, width: 32, height: 44, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 32)),
          ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: Color(0xFF065F46)), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('$setId · $number', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ])),
        const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onClear,
          child: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
        ),
      ]),
    );
  }
}

// 圖鑑選卡 bottom sheet
class _DexCardPickerSheet extends StatefulWidget {
  const _DexCardPickerSheet();

  @override
  State<_DexCardPickerSheet> createState() => _DexCardPickerSheetState();
}

class _DexCardPickerSheetState extends State<_DexCardPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final res = await SupabaseService.searchCachedCards(q);
    if (mounted) setState(() { _results = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Text('從圖鑑選卡', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Color(0xFF6B7280)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: '搜尋卡片名稱（輸入 2 字以上）',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
              filled: true, fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
            : _results.isEmpty
                ? Center(child: Text(
                    _searchCtrl.text.length < 2 ? '輸入卡片名稱搜尋' : '找不到卡片',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final c = _results[i];
                      final img = c['image_small'] as String?;
                      final name = c['name'] as String? ?? '';
                      final setId = c['set_id'] as String? ?? '';
                      final number = c['number'] as String? ?? '';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                        leading: img != null && img.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(4),
                                child: Image.network(img, width: 36, height: 50, fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined,
                                        size: 24, color: Color(0xFFD1D5DB))))
                            : const Icon(Icons.style_outlined, size: 24, color: Color(0xFFD1D5DB)),
                        title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$setId · $number',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        onTap: () => Navigator.pop(context, c),
                      );
                    }),
        ),
      ]),
    );
  }
}

// ── 面交地點選擇器 ──────────────────────────────────────────────────────────────
class _MeetupLocationPicker extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  static const _hkLocations = [
    '中環', '金鐘', '灣仔', '銅鑼灣', '天后', '北角',
    '油麻地', '旺角', '太子', '深水埗', '長沙灣', '荔枝角',
    '尖沙咀', '紅磡', '黃埔', '九龍灣', '牛頭角', '觀塘',
    '沙田', '大圍', '馬鞍山', '將軍澳', '調景嶺', '坑口',
    '荃灣', '葵芳', '葵興', '青衣', '屯門', '元朗',
    '天水圍', '上水', '粉嶺', '大埔', '火炭',
  ];

  const _MeetupLocationPicker({
    required this.selected,
    required this.onChanged,
  });

  void _showPicker(BuildContext context) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationPickerSheet(initial: List.from(selected)),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('優先面交地點', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(width: 6),
        const Text('（選填，可多選）', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        const Spacer(),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: const Text('選擇', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE8A52A))),
        ),
      ]),
      if (selected.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: selected.map((loc) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8A52A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8A52A).withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(loc, style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  final updated = List<String>.from(selected)..remove(loc);
                  onChanged(updated);
                },
                child: const Icon(Icons.close, size: 14, color: Color(0xFFB45309)),
              ),
            ]),
          )).toList(),
        ),
      ] else ...[
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB), width: 0.5),
            ),
            child: const Center(
              child: Text('點擊選擇面交地點', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final List<String> initial;
  const _LocationPickerSheet({required this.initial});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late final List<String> _selected;

  static const _hkLocations = _MeetupLocationPicker._hkLocations;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            const Text('選擇面交地點', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: Text('完成（${_selected.length}）', style: const TextStyle(color: Color(0xFFE8A52A), fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        // Grid
        SizedBox(
          height: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hkLocations.map((loc) {
                final sel = _selected.contains(loc);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) _selected.remove(loc);
                    else _selected.add(loc);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? const Color(0xFFE8A52A) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      loc,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}
