import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/announcement_service.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  Color get _color {
    try {
      final hex = announcement.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFE8A52A);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}年${dt.month.toString().padLeft(2, '0')}月'
        '${dt.day.toString().padLeft(2, '0')}日 '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('公告詳情',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.25), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(announcement.icon, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(announcement.title,
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                  if (announcement.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(announcement.subtitle,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.access_time, size: 13, color: color.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(_formatDate(announcement.createdAt),
                        style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
                  ]),
                ],
              ),
            ),

            // Image (if any)
            if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: announcement.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: const Color(0xFFF3F4F6),
                    child: const Center(child: CircularProgressIndicator(
                        color: Color(0xFFE8A52A), strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            // Body content
            if (announcement.body != null && announcement.body!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                ),
                child: Text(
                  announcement.body!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.7,
                  ),
                ),
              ),
            ],

            // Body images
            if (announcement.bodyImageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...announcement.bodyImageUrls.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: const Color(0xFFF3F4F6),
                      child: const Center(child: CircularProgressIndicator(
                          color: Color(0xFFE8A52A), strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              )),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
