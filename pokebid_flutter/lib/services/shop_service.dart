import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CardShop {
  final String id;
  final String name;
  final String? address;
  final String? district;
  final double lat;
  final double lng;
  final String? phone;
  final String? igHandle;
  final String? hours;
  final String? note;
  double? distanceKm; // 由位置計算後填入

  CardShop({
    required this.id, required this.name, this.address, this.district,
    required this.lat, required this.lng, this.phone, this.igHandle,
    this.hours, this.note, this.distanceKm,
  });

  factory CardShop.fromRow(Map<String, dynamic> r) => CardShop(
        id: r['id'] as String,
        name: r['name'] as String? ?? '',
        address: r['address'] as String?,
        district: r['district'] as String?,
        lat: (r['lat'] as num).toDouble(),
        lng: (r['lng'] as num).toDouble(),
        phone: r['phone'] as String?,
        igHandle: r['ig_handle'] as String?,
        hours: r['hours'] as String?,
        note: r['note'] as String?,
      );
}

class ShopService {
  static final _client = Supabase.instance.client;

  static Future<List<CardShop>> getShops({bool includeInactive = false}) async {
    try {
      var q = _client.from('card_shops').select();
      if (!includeInactive) q = q.eq('is_active', true);
      final res = await q;
      return (res as List).map((r) => CardShop.fromRow(r)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Admin ─────────────────────────────────────────────────────────────────
  static Future<bool> upsertShop(Map<String, dynamic> data) async {
    try {
      await _client.from('card_shops').upsert(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> deleteShop(String id) async {
    try { await _client.from('card_shops').delete().eq('id', id); } catch (_) {}
  }

  /// 取得目前位置；權限被拒/逾時回 null
  static Future<Position?> currentPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return null;
      }
      // 注：web 上不檢查 isLocationServiceEnabled（常誤判）；直接取位置 + 逾時保護
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// 取卡鋪並依目前位置由近到遠排序（無位置則依名稱）
  static Future<({List<CardShop> shops, bool hasLocation})> nearbyShops() async {
    final shops = await getShops();
    final pos = await currentPosition();
    if (pos != null) {
      for (final s in shops) {
        s.distanceKm = Geolocator.distanceBetween(
                pos.latitude, pos.longitude, s.lat, s.lng) /
            1000.0;
      }
      shops.sort((a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9));
      return (shops: shops, hasLocation: true);
    }
    shops.sort((a, b) => a.name.compareTo(b.name));
    return (shops: shops, hasLocation: false);
  }
}
