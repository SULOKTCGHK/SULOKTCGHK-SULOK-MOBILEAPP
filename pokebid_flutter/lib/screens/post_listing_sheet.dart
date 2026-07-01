import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import '../services/listing_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../data/meetup_locations.dart';
import 'pokemon_dex_screen.dart';

class PostListingSheet extends StatefulWidget {
  final Function(PokemonCard) onSubmit;

  const PostListingSheet({super.key, required this.onSubmit});

  @override
  State<PostListingSheet> createState() => _PostListingSheetState();
}

class _PostListingSheetState extends State<PostListingSheet> {
  // 商品類型
  String _cardCondition = 'raw'; // 'raw' or 'graded'

  // 未鑑定(raw)品相分級
  String _rawGrade = 'A';
  final List<String> _rawGrades = ['A', 'B', 'C', '流通品'];

  // 鑑定資訊
  String _gradingCompany = 'PSA';
  String _gradeScore = '10';

  bool _submitting = false;
  final List<String> _meetupLocations = [];
  final List<XFile> _images = [];       // 內文圖片
  final List<Uint8List> _imageBytes = [];
  XFile? _coverImage;                    // 用戶自訂封面（可覆蓋圖鑑圖）
  Uint8List? _coverBytes;
  final _picker = ImagePicker();

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    final b = await x.readAsBytes();
    if (!mounted) return;
    setState(() { _coverImage = x; _coverBytes = b; });
  }

  Future<String> _uploadOne(XFile img) async {
    final client = Supabase.instance.client;
    final bytes = await img.readAsBytes();
    final ext = img.name.split('.').last.toLowerCase();
    final path = 'listings/${DateTime.now().millisecondsSinceEpoch}_${img.name}';
    await client.storage.from('card-images').uploadBinary(
      path, bytes, fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));
    return client.storage.from('card-images').getPublicUrl(path);
  }

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

  // 裁切某張圖片（讓用戶自訂位置/大小，顯示更精準）
  Future<void> _cropImage(int i) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: _images[i].path,
      uiSettings: [
        IOSUiSettings(title: '裁切圖片', aspectRatioLockEnabled: false, resetAspectRatioEnabled: true),
        AndroidUiSettings(toolbarTitle: '裁切圖片', lockAspectRatio: false,
            toolbarColor: const Color(0xFFE8A52A), toolbarWidgetColor: const Color(0xFFFFFFFF)),
      ],
    );
    if (cropped == null) return;
    final bytes = await cropped.readAsBytes();
    if (!mounted) return;
    setState(() {
      _images[i] = XFile(cropped.path);
      _imageBytes[i] = bytes;
    });
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

  // raw 卡且有選圖鑑卡 → 用圖鑑圖片當預設封面
  String? get _dexCoverUrl {
    if (_cardCondition != 'raw') return null;
    final u = _selectedDexCard?['image_small'] as String?;
    return (u != null && u.isNotEmpty) ? u : null;
  }

  // 表單
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _setIdCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _certCtrl = TextEditingController();

  // PSA Pop 即時預覽（輸入 cert 後抓取顯示）
  Map<String, dynamic>? _psaPop;
  bool _psaPopLoading = false;
  String? _lastPsaCert;

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
    _certCtrl.dispose();
    super.dispose();
  }

  // 從圖鑑選卡
  Future<void> _pickFromDex() async {
    final card = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DexCardPickerSheet(),
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

  // 輸入 cert 後即時抓取 PSA Pop 顯示在表單
  Future<void> _loadPsaPopPreview(String cert) async {
    cert = cert.trim();
    if (cert.length < 7) {
      if (_psaPop != null || _psaPopLoading) {
        setState(() { _psaPop = null; _psaPopLoading = false; });
      }
      _lastPsaCert = null;
      return;
    }
    if (cert == _lastPsaCert) return;
    _lastPsaCert = cert;
    setState(() => _psaPopLoading = true);
    final pop = await SupabaseService.getPsaPopForListing(psaCert: cert);
    if (mounted && cert == _lastPsaCert) {
      setState(() { _psaPop = pop; _psaPopLoading = false; });
    }
  }

  // PSA Pop 即時預覽卡
  Widget _psaPopPreview(Map<String, dynamic> pop) {
    int v(String k) => (pop[k] as num?)?.toInt() ?? 0;
    final name = pop['card_name'] as String?;
    final cells = [
      ('PSA 10', v('pop_10'), const Color(0xFFE8A52A)),
      ('PSA 9', v('pop_9'), const Color(0xFF2980B9)),
      ('PSA 8', v('pop_8'), const Color(0xFF6B7280)),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8A52A).withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('PSA Pop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB8860B))),
          const Spacer(),
          Text('總計 ${v('total')} 張', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ]),
        if (name != null && name.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Row(children: [
          for (final c in cells)
            Expanded(child: Column(children: [
              Text(c.$1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.$3)),
              const SizedBox(height: 2),
              Text('${c.$2}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.$3)),
            ])),
        ]),
      ]),
    );
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
    if (_cardCondition == 'raw') return _rawGrade;
    return '$_gradingCompany $_gradeScore';
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text);
    if (name.isEmpty) { _showError(L.errEnterName); return; }
    if (price == null || price < 1) { _showError(L.errEnterPrice); return; }
    // 封面：用戶自訂 > 圖鑑圖(raw)；內文圖片附在後面
    final hasCover = _coverBytes != null || _dexCoverUrl != null;
    if (!hasCover && _images.isEmpty) { _showError('請至少上傳 1 張圖片'); return; }

    setState(() => _submitting = true);

    final coverUrl = _coverImage != null ? await _uploadOne(_coverImage!) : _dexCoverUrl;
    final contentUrls = await _uploadImages();
    final imageUrls = [
      if (coverUrl != null) coverUrl, // 封面放最前
      ...contentUrls,
    ];

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

    if (!ok) { _showError(L.errPostFailed); return; }

    // Pass a placeholder card so onSubmit callback triggers the refresh
    widget.onSubmit(PokemonCard(
      id: 0, name: name, grade: _gradeLabel,
      type: CardType.normal, price: price,
      condition: _cardCondition == 'raw' ? 'Raw' : 'Graded',
      seller: Seller(
        name: AuthService.isLoggedIn ? AuthService.displayName : L.anonymousSeller,
        rating: 5.0, sales: 0,
      ),
      listingType: ListingType.fixedPrice,
      timeInfo: L.justListed,
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
                  Text(L.postListingTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
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
                          // 封面（raw 預設圖鑑圖，可換成自己的相片）
                          if (_dexCoverUrl != null || _coverBytes != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _coverBytes != null
                                      ? Image.memory(_coverBytes!, width: 48, height: 48, fit: BoxFit.cover)
                                      : Image.network(_dexCoverUrl!, width: 48, height: 48, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                      _coverBytes != null ? '已用你的相片作封面' : '封面：圖鑑圖片',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF15803D))),
                                ),
                                TextButton(
                                  onPressed: _pickCover,
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
                                  child: const Text('更改封面', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE8A52A))),
                                ),
                                if (_coverBytes != null)
                                  GestureDetector(
                                    onTap: () => setState(() { _coverImage = null; _coverBytes = null; }),
                                    child: const Padding(padding: EdgeInsets.only(left: 2),
                                        child: Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF))),
                                  ),
                              ]),
                            ),
                            const SizedBox(height: 6),
                            const Text('內文圖片（選填，最多 4 張）',
                                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                            const SizedBox(height: 6),
                          ],
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
                                    // 裁切按鈕（調整位置/大小）
                                    Positioned(
                                      bottom: 2, right: 2,
                                      child: GestureDetector(
                                        onTap: () => _cropImage(i),
                                        child: Container(
                                          width: 20, height: 20,
                                          decoration: const BoxDecoration(
                                            color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.crop, color: Colors.white, size: 12),
                                        ),
                                      ),
                                    ),
                                  ]);
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(L.photosCount(_images.length),
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
                                child: Column(children: [
                                  const Icon(Icons.add_a_photo_outlined, size: 28, color: Color(0xFF9CA3AF)),
                                  const SizedBox(height: 6),
                                  Text(L.uploadPhotos,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
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
                              Expanded(child: Text(L.pickFromDex,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFFB45309), fontWeight: FontWeight.w500))),
                              const Icon(Icons.chevron_right, size: 16, color: Color(0xFFE8A52A)),
                            ]),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Card name
                      _label(L.cardName),
                      _textField(_nameCtrl, ''),
                      const SizedBox(height: 16),

                      // ── 商品類型 ──────────────────────────────────────
                      _label(L.productType),
                      Row(children: [
                        Expanded(
                          child: _conditionBtn(
                            value: 'raw',
                            label: L.rawUngraded,
                            icon: Icons.style_outlined,
                            desc: L.rawDesc,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _conditionBtn(
                            value: 'graded',
                            label: L.gradedCard,
                            icon: Icons.verified_outlined,
                            desc: L.gradedDesc,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── 未鑑定品相分級（只在 raw 時顯示）──────────────
                      if (_cardCondition == 'raw') ...[
                        _label('品相分級'),
                        Wrap(spacing: 8, runSpacing: 8, children: _rawGrades.map((g) {
                          final active = _rawGrade == g;
                          return GestureDetector(
                            onTap: () => setState(() => _rawGrade = g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active ? const Color(0xFFE8A52A) : const Color(0xFFE5E7EB),
                                  width: active ? 1 : 0.5),
                              ),
                              child: Text(g,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: active ? Colors.white : const Color(0xFF6B7280))),
                            ),
                          );
                        }).toList()),
                        const SizedBox(height: 6),
                        const Text('分級僅供參考用途，實際品相以圖片為準',
                            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        const SizedBox(height: 16),
                      ],

                      // ── 鑑定資訊（只在鑑定卡時顯示）────────────────
                      if (_cardCondition == 'graded') ...[
                        _label(L.gradingCompany),
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

                        _label(L.gradeScore),
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
                                                  .withValues(alpha: 0.7))),
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
                              L.gradeLevel(_gradingCompany, _gradeScore),
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
                              child: Text(L.optional,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _certCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 14),
                            onChanged: _loadPsaPopPreview,
                            decoration: InputDecoration(
                              hintText: L.certHint,
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
                          Text(L.certHelper,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          if (_psaPopLoading) ...[
                            const SizedBox(height: 8),
                            const Row(children: [
                              SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8A52A))),
                              SizedBox(width: 8),
                              Text('查詢 PSA Pop 中...',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
                            ]),
                          ] else if (_psaPop != null) ...[
                            const SizedBox(height: 8),
                            _psaPopPreview(_psaPop!),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ],

                      // Price
                      _label(L.buyPriceLabel),
                      _textField(_priceCtrl, '0', isNumber: true),
                      const SizedBox(height: 14),

                      // ── 系列 + 卡號（選填）─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Text(L.setAndNumber,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151))),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _showSetNumberHelp,
                            child: const Icon(Icons.help_outline,
                                size: 15, color: Color(0xFF9CA3AF)),
                          ),
                        ]),
                      ),
                      _setAndNumberRow(),
                      const SizedBox(height: 14),

                      // Description
                      _label(L.description),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF111827)),
                        decoration: InputDecoration(
                          hintText: '',
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
                              : Text(L.confirmPost,
                                  style: const TextStyle(
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

  void _showSetNumberHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.help_outline, size: 20, color: Color(0xFFE8A52A)),
          const SizedBox(width: 8),
          Expanded(child: Text(L.setNumberHelpTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
        ]),
        content: Text(L.setNumberHelpBody,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF374151))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(L.ok)),
        ],
      ),
    );
  }

  Widget _setAndNumberRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 系列：用戶自行填寫
      Expanded(
        flex: 3,
        child: TextField(
          controller: _setIdCtrl,
          keyboardType: TextInputType.text,
          onChanged: (_) => setState(() {}),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: L.setIdHint,
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
      const SizedBox(width: 10),
      // 卡號 input
      Expanded(
        flex: 2,
        child: TextField(
          controller: _cardNumberCtrl,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: L.cardNumberHint,
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
class DexCardPickerSheet extends StatefulWidget {
  final bool multiSelect; // true = 可多選，完成時回傳 List<Map>
  const DexCardPickerSheet({super.key, this.multiSelect = false});

  @override
  State<DexCardPickerSheet> createState() => DexCardPickerSheetState();
}

class DexCardPickerSheetState extends State<DexCardPickerSheet> {
  final _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _picked = []; // 多選模式已選的卡

  String _keyOf(Map<String, dynamic> c) =>
      (c['id'] as String?) ?? '${c['set_id']}-${c['number']}-${c['name']}';
  bool _isPicked(Map<String, dynamic> c) => _picked.any((p) => _keyOf(p) == _keyOf(c));

  // 點卡：單選 → 直接回傳；多選 → 加入/移除清單
  void _pick(Map<String, dynamic> c) {
    if (!widget.multiSelect) { Navigator.pop(context, c); return; }
    setState(() {
      final k = _keyOf(c);
      final idx = _picked.indexWhere((p) => _keyOf(p) == k);
      if (idx >= 0) { _picked.removeAt(idx); } else { _picked.add(c); }
    });
  }
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _mode = 'search'; // 'search' | 'pokemon' | 'set'

  // 系列圖鑑瀏覽
  final _setSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _sets = [];
  bool _setsLoading = false;
  String _setQuery = '';
  String? _selSet;
  String? _selSetName;
  List<Map<String, dynamic>> _setCards = [];
  bool _setCardsLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _setSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSets() async {
    if (_sets.isNotEmpty || _setsLoading) return;
    setState(() => _setsLoading = true);
    final s = await SupabaseService.getCachedSets();
    if (mounted) setState(() { _sets = s; _setsLoading = false; });
  }

  Future<void> _openSet(String id, String name) async {
    setState(() { _selSet = id; _selSetName = name; _setCardsLoading = true; _setCards = []; });
    final cards = await SupabaseService.getCachedCardsForSet(id);
    if (mounted) setState(() { _setCards = cards; _setCardsLoading = false; });
  }

  List<Map<String, dynamic>> get _filteredSets {
    final q = _setQuery.trim().toLowerCase();
    if (q.isEmpty) return _sets;
    return _sets.where((s) =>
        (s['name'] as String? ?? '').toLowerCase().contains(q) ||
        (s['id'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  // 精靈圖鑑選到的卡（ApiCard）→ 刊登頁要的 Map
  Map<String, dynamic> _cardToMap(ApiCard c) => {
        'id': c.id,
        'name': c.name,
        'set_id': c.setId,
        'set_name': c.setName,
        'number': c.number,
        'image_small': c.imageSmall,
        'image_large': c.imageLarge,
      };

  Widget _modeBtn(String value, String label) {
    final active = _mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _mode = value);
          if (value == 'set') _loadSets();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : const Color(0xFF6B7280))),
        ),
      ),
    );
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
            Text(L.pickFromDexTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (widget.multiSelect)
              GestureDetector(
                onTap: () => Navigator.pop(context, List<Map<String, dynamic>>.from(_picked)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFE8A52A), borderRadius: BorderRadius.circular(8)),
                  child: Text('完成 (${_picked.length})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              )
            else
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Color(0xFF6B7280)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        // 模式切換：搜尋 / 精靈圖鑑
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _modeBtn('search', L.search),
            const SizedBox(width: 8),
            _modeBtn('pokemon', L.tabPokemonDex),
            const SizedBox(width: 8),
            _modeBtn('set', '系列圖鑑'),
          ]),
        ),
        const SizedBox(height: 12),
        if (_mode == 'search') ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: L.dexSearchHint,
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
                      _searchCtrl.text.length < 2 ? L.dexSearchPrompt : L.dexNoCard,
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
                        final sel = widget.multiSelect && _isPicked(c);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? const Color(0xFFE74C3C) : Colors.transparent,
                              width: sel ? 2 : 0),
                          ),
                          child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                          trailing: widget.multiSelect
                              ? Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 20, color: sel ? const Color(0xFFE74C3C) : const Color(0xFFD1D5DB))
                              : null,
                          onTap: () => _pick(c),
                        ));
                      }),
          ),
        ] else if (_mode == 'pokemon')
          // 精靈圖鑑瀏覽選卡：選精靈 → 看牠的卡 → 點卡回傳
          Expanded(
            child: PokemonDexScreen(
              embedded: true,
              onCardPicked: (c) => _pick(_cardToMap(c)),
              isPicked: widget.multiSelect ? (c) => _isPicked(_cardToMap(c)) : null,
            ),
          )
        else ...[
          // 系列圖鑑瀏覽選卡：選系列 → 看該系列的卡 → 點卡回傳
          if (_selSet == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _setSearchCtrl,
                onChanged: (v) => setState(() => _setQuery = v),
                decoration: InputDecoration(
                  hintText: '搜尋系列名稱',
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
            Expanded(child: _setsLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredSets.length,
                    itemBuilder: (_, i) {
                      final s = _filteredSets[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.folder_outlined, size: 22, color: Color(0xFFE8A52A)),
                        title: Text(s['name'] as String? ?? s['id'] as String? ?? '',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFFD1D5DB)),
                        onTap: () => _openSet(s['id'] as String, s['name'] as String? ?? ''),
                      );
                    })),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                GestureDetector(
                  onTap: () => setState(() { _selSet = null; _setCards = []; }),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chevron_left, size: 20, color: Color(0xFFE8A52A)),
                    Text('系列', style: TextStyle(fontSize: 13, color: Color(0xFFE8A52A))),
                  ]),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_selSetName ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(child: _setCardsLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
                : _setCards.isEmpty
                    ? const Center(child: Text('此系列暫無卡牌資料',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.62),
                        itemCount: _setCards.length,
                        itemBuilder: (_, i) {
                          final c = _setCards[i];
                          final img = c['image_small'] as String?;
                          final sel = widget.multiSelect && _isPicked(c);
                          return GestureDetector(
                            onTap: () => _pick(c),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Expanded(child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: sel ? const Color(0xFFE74C3C) : Colors.transparent,
                                    width: sel ? 2.5 : 0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(fit: StackFit.expand, children: [
                                (img != null && img.isNotEmpty)
                                    ? Image.network(img, fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined,
                                            size: 24, color: Color(0xFFD1D5DB)))
                                    : const Icon(Icons.style_outlined, size: 24, color: Color(0xFFD1D5DB)),
                                if (sel)
                                  Positioned(right: 2, top: 2,
                                      child: Container(
                                        decoration: const BoxDecoration(color: Color(0xFFE74C3C), shape: BoxShape.circle),
                                        child: const Icon(Icons.check, size: 14, color: Colors.white))),
                              ]))),
                              const SizedBox(height: 3),
                              Text('#${c['number'] ?? ''}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          );
                        })),
          ],
        ],
      ]),
    );
  }
}

// ── 面交地點選擇器 ──────────────────────────────────────────────────────────────
class _MeetupLocationPicker extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  // 面交地點分區
  static const _hkRegions = kMeetupRegions;

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
        Text(L.preferredMeetup, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(width: 6),
        Text(L.meetupOptionalMulti, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        const Spacer(),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Text(L.select, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE8A52A))),
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
              color: const Color(0xFFE8A52A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8A52A).withValues(alpha: 0.4)),
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
            child: Center(
              child: Text(L.tapToPickMeetup, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
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

  static const _hkRegions = _MeetupLocationPicker._hkRegions;

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
            Text(L.selectMeetup, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: Text(L.doneCount(_selected.length), style: const TextStyle(color: Color(0xFFE8A52A), fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        // Grid
        SizedBox(
          height: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: _hkRegions.entries.map((region) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(region.key,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: Color(0xFF111827))),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: region.value.map((loc) {
                      final sel = _selected.contains(loc);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (sel) {
                            _selected.remove(loc);
                          } else {
                            _selected.add(loc);
                          }
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
                  const SizedBox(height: 14),
                ]);
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}
