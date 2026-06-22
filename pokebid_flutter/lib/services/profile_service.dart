import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String avatarEmoji;
  final String bio;
  final String igHandle;
  final bool phoneVerified;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarEmoji,
    required this.bio,
    required this.igHandle,
    this.phoneVerified = false,
    required this.createdAt,
  });

  factory UserProfile.fromRow(Map<String, dynamic> r) => UserProfile(
    id: r['id'] as String,
    username: r['username'] as String? ?? '',
    displayName: r['display_name'] as String? ?? '',
    avatarEmoji: r['avatar_emoji'] as String? ?? '🎴',
    bio: r['bio'] as String? ?? '',
    igHandle: r['ig_handle'] as String? ?? '',
    phoneVerified: r['phone_verified'] as bool? ?? false,
    createdAt: DateTime.parse(r['created_at'] as String),
  );
}

class ProfileService {
  static final _client = Supabase.instance.client;

  // ── Get profile by user ID ────────────────────────────────────────────────
  static Future<UserProfile?> getProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return res != null ? UserProfile.fromRow(res) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Get or create profile for current user ────────────────────────────────
  static Future<UserProfile?> getOrCreateMyProfile() async {
    if (!AuthService.isLoggedIn) return null;
    final userId = AuthService.userId;

    final existing = await getProfile(userId);
    if (existing != null) return existing;

    // Auto-create with defaults from Google/email
    final defaultName = AuthService.displayName;
    final defaultUsername = _toUsername(defaultName, userId);

    try {
      final res = await _client.from('profiles').insert({
        'id': userId,
        'username': defaultUsername,
        'display_name': defaultName,
        'avatar_emoji': '🎴',
        'bio': '',
        'ig_handle': '',
      }).select().single();
      return UserProfile.fromRow(res);
    } catch (_) {
      // If username conflict, append short id
      try {
        final res = await _client.from('profiles').insert({
          'id': userId,
          'username': '${defaultUsername}_${userId.substring(0, 4)}',
          'display_name': defaultName,
          'avatar_emoji': '🎴',
          'bio': '',
          'ig_handle': '',
        }).select().single();
        return UserProfile.fromRow(res);
      } catch (_) {
        return null;
      }
    }
  }

  // ── Update profile ────────────────────────────────────────────────────────
  static Future<bool> updateProfile({
    required String displayName,
    required String username,
    required String avatarEmoji,
    required String bio,
    required String igHandle,
  }) async {
    if (!AuthService.isLoggedIn) return false;
    try {
      await _client.from('profiles').upsert({
        'id': AuthService.userId,
        'display_name': displayName,
        'username': username,
        'avatar_emoji': avatarEmoji,
        'bio': bio,
        'ig_handle': igHandle,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // 註：phone_verified 由 whatsapp-verify Edge Function 以 service role 設定，
  // 不開放 client 直接寫入（防竄改）。

  // ── Check if username is taken ────────────────────────────────────────────
  static Future<bool> isUsernameTaken(String username, String myId) async {
    try {
      final res = await _client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .neq('id', myId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  static String _toUsername(String name, String userId) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return base.isEmpty ? 'user_${userId.substring(0, 6)}' : base;
  }
}
