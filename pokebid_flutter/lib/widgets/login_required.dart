import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

/// 寫入動作前的登入檢查。
/// 已登入 → 回 true；未登入 → 彈出提示，使用者可前往登入，回 false。
Future<bool> requireLogin(BuildContext context, {String? action}) async {
  if (AuthService.isLoggedIn) return true;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('請先登入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text(
        action != null ? '登入後才能$action。' : '此功能需要登入帳號。',
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('稍後')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8A52A)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('前往登入', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
  return false;
}
