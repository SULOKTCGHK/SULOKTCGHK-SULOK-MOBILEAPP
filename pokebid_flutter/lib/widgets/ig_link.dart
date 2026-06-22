import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Instagram 連結標誌（用戶填了 IG 帳號才顯示），點擊開對方 IG 個人檔案
class IgLink extends StatelessWidget {
  final String handle;
  final double size;
  const IgLink({super.key, required this.handle, this.size = 16});

  String get _clean => handle.trim().replaceAll('@', '').replaceAll(' ', '');

  Future<void> _open() async {
    if (_clean.isEmpty) return;
    final uri = Uri.parse('https://instagram.com/$_clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_clean.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: EdgeInsets.all(size * 0.18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
            begin: Alignment.bottomLeft, end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(Icons.camera_alt, size: size, color: Colors.white),
      ),
    );
  }
}
