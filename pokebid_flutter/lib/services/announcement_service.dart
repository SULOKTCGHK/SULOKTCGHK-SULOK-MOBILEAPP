import 'package:supabase_flutter/supabase_flutter.dart';

class Announcement {
  final String id;
  final String title;
  final String subtitle;
  final String? body;
  final String colorHex;
  final String icon;
  final String? imageUrl;
  final List<String> bodyImageUrls;
  final int sortOrder;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.subtitle,
    this.body,
    required this.colorHex,
    required this.icon,
    this.imageUrl,
    this.bodyImageUrls = const [],
    required this.sortOrder,
    required this.createdAt,
  });

  factory Announcement.fromRow(Map<String, dynamic> r) => Announcement(
    id: r['id'] as String,
    title: r['title'] as String,
    subtitle: r['subtitle'] as String? ?? '',
    body: r['body'] as String?,
    colorHex: r['color_hex'] as String? ?? '#E8A52A',
    icon: r['icon'] as String? ?? '📢',
    imageUrl: r['image_url'] as String?,
    bodyImageUrls: (r['body_image_urls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    sortOrder: (r['sort_order'] as int?) ?? 0,
    createdAt: DateTime.parse(r['created_at'] as String),
  );
}

class AnnouncementService {
  static final _client = Supabase.instance.client;

  static Future<List<Announcement>> getAnnouncements() async {
    try {
      final res = await _client
          .from('announcements')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);
      return (res as List).map((r) => Announcement.fromRow(r)).toList();
    } catch (_) {
      return [];
    }
  }
}
