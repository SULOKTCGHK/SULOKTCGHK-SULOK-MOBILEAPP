import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostAnnouncementSheet extends StatefulWidget {
  final VoidCallback onPosted;

  const PostAnnouncementSheet({super.key, required this.onPosted});

  @override
  State<PostAnnouncementSheet> createState() => _PostAnnouncementSheetState();
}

class _PostAnnouncementSheetState extends State<PostAnnouncementSheet> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  String _selectedColor = 'E8A52A';
  String _selectedIcon = '📢';
  Uint8List? _coverBytes;
  final List<Uint8List> _bodyImageBytes = [];
  bool _submitting = false;

  static const _colorOptions = [
    {'hex': 'E8A52A', 'label': '金黃', 'color': Color(0xFFE8A52A)},
    {'hex': '27AE60', 'label': '綠色', 'color': Color(0xFF27AE60)},
    {'hex': '2980B9', 'label': '藍色', 'color': Color(0xFF2980B9)},
    {'hex': '8E44AD', 'label': '紫色', 'color': Color(0xFF8E44AD)},
    {'hex': 'E74C3C', 'label': '紅色', 'color': Color(0xFFE74C3C)},
    {'hex': '1ABC9C', 'label': '青色', 'color': Color(0xFF1ABC9C)},
  ];

  static const _iconOptions = ['📢', '🎉', '🔔', '⭐', '🎴', '🛡️', '📦', '📊', '✨', '🚀'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _coverBytes = bytes);
  }

  Future<void> _pickBodyImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    final bytesList = await Future.wait(files.map((f) => f.readAsBytes()));
    setState(() => _bodyImageBytes.addAll(bytesList));
  }

  Future<String?> _uploadImage(Uint8List bytes, String filename) async {
    final client = Supabase.instance.client;
    await client.storage.from('card-images').uploadBinary(
        filename, bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
    return client.storage.from('card-images').getPublicUrl(filename);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final subtitle = _subtitleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty) {
      _showError('請輸入標題');
      return;
    }
    setState(() => _submitting = true);
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Upload cover
      String? coverUrl;
      if (_coverBytes != null) {
        coverUrl = await _uploadImage(_coverBytes!, 'announcements/cover_$ts.jpg');
      }

      // Upload body images
      final List<String> bodyUrls = [];
      for (int i = 0; i < _bodyImageBytes.length; i++) {
        final url = await _uploadImage(
            _bodyImageBytes[i], 'announcements/body_${ts}_$i.jpg');
        if (url != null) bodyUrls.add(url);
      }

      await Supabase.instance.client.from('announcements').insert({
        'title': title,
        'subtitle': subtitle,
        'body': body.isEmpty ? null : body,
        'color_hex': _selectedColor,
        'icon': _selectedIcon,
        'image_url': coverUrl,
        'body_image_urls': bodyUrls,
        'is_active': true,
        'sort_order': 0,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onPosted();
      }
    } catch (e) {
      if (mounted) _showError('發佈失敗：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE74C3C)));
  }

  Color get _accentColor {
    final match = _colorOptions.firstWhere(
        (c) => c['hex'] == _selectedColor,
        orElse: () => _colorOptions.first);
    return match['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Row(children: [
            Text(_selectedIcon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('發佈公告',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 20),

          // ── Cover image ──────────────────────────────────────────────
          _label('封面圖片（選填）'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickCover,
            child: Container(
              width: double.infinity, height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _coverBytes != null ? _accentColor : const Color(0xFFE5E7EB),
                  width: _coverBytes != null ? 1.5 : 1,
                ),
              ),
              child: _coverBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(fit: StackFit.expand, children: [
                        Image.memory(_coverBytes!, fit: BoxFit.cover),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _coverBytes = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ]),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 30, color: _accentColor),
                      const SizedBox(height: 6),
                      Text('點擊上傳封面圖片',
                          style: TextStyle(fontSize: 13, color: _accentColor)),
                    ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ────────────────────────────────────────────────────
          _label('標題 *'),
          const SizedBox(height: 6),
          _textField(_titleCtrl, '例：新系列正式上架！', maxLines: 1),
          const SizedBox(height: 12),

          // ── Subtitle ─────────────────────────────────────────────────
          _label('副標題（顯示在 Banner 上）'),
          const SizedBox(height: 6),
          _textField(_subtitleCtrl, '例：即日起正式開放預購', maxLines: 1),
          const SizedBox(height: 12),

          // ── Body ─────────────────────────────────────────────────────
          _label('內文'),
          const SizedBox(height: 6),
          _textField(_bodyCtrl, '輸入詳細公告內容...', maxLines: 5),
          const SizedBox(height: 16),

          // ── Body images ──────────────────────────────────────────────
          Row(children: [
            _label('內文圖片'),
            const Spacer(),
            GestureDetector(
              onTap: _pickBodyImages,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_photo_alternate, size: 15, color: _accentColor),
                  const SizedBox(width: 4),
                  Text('新增圖片',
                      style: TextStyle(fontSize: 12, color: _accentColor,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 8),

          if (_bodyImageBytes.isEmpty)
            Container(
              width: double.infinity, height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                    style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text('尚未新增內文圖片',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _bodyImageBytes.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == _bodyImageBytes.length) {
                    // Add more button
                    return GestureDetector(
                      onTap: _pickBodyImages,
                      child: Container(
                        width: 90, height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Icon(Icons.add, color: _accentColor, size: 24),
                          Text('新增', style: TextStyle(
                              fontSize: 11, color: _accentColor)),
                        ]),
                      ),
                    );
                  }
                  return Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _bodyImageBytes[i],
                        width: 90, height: 100, fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _bodyImageBytes.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          const SizedBox(height: 16),

          // ── Icon picker ──────────────────────────────────────────────
          _label('圖示'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _iconOptions.map((icon) {
              final selected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: selected ? _accentColor.withValues(alpha: 0.15) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _accentColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 22))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Color picker ─────────────────────────────────────────────
          _label('主題色'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _colorOptions.map((c) {
              final selected = c['hex'] == _selectedColor;
              final color = c['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c['hex'] as String),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? Colors.black38 : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: color.withValues(alpha: 0.4),
                              blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Submit ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('發佈公告',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  Widget _textField(TextEditingController ctrl, String hint,
          {required int maxLines}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1.5),
          ),
        ),
      );
}
