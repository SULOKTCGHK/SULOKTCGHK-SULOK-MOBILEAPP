import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'currency_service.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;
  static String? _userId;

  // ── User ID ───────────────────────────────────────────────────────────────
  // 已登入 → 用登入帳號 uid（資料跨裝置綁定）；未登入瀏覽 → 暫時的裝置 UUID
  static Future<String> getUserId() async {
    if (AuthService.isLoggedIn) return AuthService.userId;
    if (_userId != null) return _userId!;
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId == null) {
      _userId = const Uuid().v4();
      await prefs.setString('user_id', _userId!);
    }
    return _userId!;
  }

  /// 是否為已登入帳號（寫入動作前可檢查）
  static bool get isLoggedIn => AuthService.isLoggedIn;

  // ── Cached Sets ───────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCachedSets() async {
    try {
      final res = await _client
          .from('cached_sets')
          .select()
          .order('release_date', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isSetsStale() async {
    try {
      final res = await _client
          .from('cached_sets')
          .select('cached_at')
          .order('cached_at', ascending: false)
          .limit(1);
      if (res.isEmpty) return true;
      final cachedAt = res.first['cached_at'] as int? ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      return age > 1000 * 60 * 60 * 24;
    } catch (_) {
      return true;
    }
  }

  static Future<void> cacheSets(List<Map<String, dynamic>> sets) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rows = sets.map((s) => {...s, 'cached_at': now}).toList();
      await _client.from('cached_sets').upsert(rows);
    } catch (_) {}
  }

  // 搜尋卡片（依名稱，從 cached_cards）
  static Future<List<Map<String, dynamic>>> searchCachedCards(String query) async {
    try {
      final res = await _client
          .from('cached_cards')
          .select()
          .ilike('name', '%$query%')
          .limit(40);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ── Cached Cards ──────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCachedCardsForSet(String setId) async {
    try {
      final res = await _client
          .from('cached_cards')
          .select()
          .eq('set_id', setId)
          .order('number');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// 取得各 promo 系列在 cached_cards 的實際卡數（set_id → count）
  static Future<Map<String, int>> getCachedCountsForSets(List<String> setIds) async {
    final result = <String, int>{};
    try {
      for (final id in setIds) {
        final res = await _client
            .from('cached_cards')
            .select('id')
            .eq('set_id', id)
            .count(CountOption.exact);
        result[id] = res.count;
      }
    } catch (_) {}
    return result;
  }

  static Future<bool> isSetCardsCached(String setId) async {
    try {
      final res = await _client
          .from('cached_cards')
          .select('cached_at')
          .eq('set_id', setId)
          .order('cached_at', ascending: false)
          .limit(1);
      if (res.isEmpty) return false;
      final cachedAt = res.first['cached_at'] as int? ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      return age < 1000 * 60 * 60 * 6;
    } catch (_) {
      return false;
    }
  }

  static Future<void> cacheCards(List<Map<String, dynamic>> cards) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rows = cards.map((c) => {...c, 'cached_at': now}).toList();
      await _client.from('cached_cards').upsert(rows);
    } catch (_) {}
  }

  // ── Collection ────────────────────────────────────────────────────────────
  static Future<void> addToCollection(Map<String, dynamic> card) async {
    final userId = await getUserId();
    try {
      await _client.from('collection').upsert({
        ...card,
        'user_id': userId,
        'added_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// 加入分級收藏（含成本價、當前市價快照）
  static Future<void> addGradedToCollection(
    Map<String, dynamic> card, {
    required String grade,
    required num costHkd,
    required num marketJpy,
  }) async {
    final userId = await getUserId();
    try {
      await _client.from('collection').upsert({
        ...card,
        'user_id': userId,
        'grade': grade,
        'cost_hkd': costHkd,
        'market_jpy': marketJpy.round(),
        'added_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,card_id,grade');
    } catch (_) {}
  }

  static Future<void> removeFromCollection(String cardId, {String? grade}) async {
    final userId = await getUserId();
    try {
      var q = _client.from('collection').delete().eq('user_id', userId).eq('card_id', cardId);
      if (grade != null) q = q.eq('grade', grade);
      await q;
    } catch (_) {}
  }

  /// 標記某收藏為「已售出」，記錄售價與售出時間
  static Future<void> markSold(String cardId, String grade, num soldPriceHkd) async {
    final userId = await getUserId();
    try {
      await _client
          .from('collection')
          .update({
            'status': 'sold',
            'sold_price_hkd': soldPriceHkd,
            'sold_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('card_id', cardId)
          .eq('grade', grade);
    } catch (_) {}
  }

  /// 收藏盈虧摘要（港幣）：持有市值/未實現盈虧 + 已售出/已實現盈虧
  static Future<Map<String, dynamic>> getCollectionSummary() async {
    final items = await getCollection();
    final rate = await CurrencyService.jpyToHkd();
    double holdCost = 0, holdValue = 0, realized = 0;
    int holdCount = 0, soldCount = 0;
    for (final it in items) {
      final sold = (it['status'] as String?) == 'sold';
      final cost = ((it['cost_hkd'] as num?)?.toDouble() ?? 0);
      if (sold) {
        realized += ((it['sold_price_hkd'] as num?)?.toDouble() ?? 0) - cost;
        soldCount++;
      } else {
        holdCost += cost;
        holdValue += ((it['market_jpy'] as num?)?.toDouble() ?? 0) * rate;
        holdCount++;
      }
    }
    final pl = holdValue - holdCost;
    return {
      'cost': holdCost,
      'value': holdValue,
      'pl': pl,
      'plPct': holdCost > 0 ? (pl / holdCost * 100) : 0.0,
      'realized': realized,
      'rate': rate,
      'count': holdCount,
      'soldCount': soldCount,
    };
  }

  /// 更新所有收藏的當前市價（重抓 SNKRDUNK），回傳更新筆數
  static Future<int> refreshCollectionMarket() async {
    final userId = await getUserId();
    final items = await getCollection();
    int updated = 0;
    for (final it in items) {
      if ((it['status'] as String?) == 'sold') continue;
      final grade = (it['grade'] as String?) ?? 'RAW';
      final data = await PokemonApiService.getSnkrdunkPrice(
          it['card_id'] as String, it['card_name'] as String? ?? '', it['number'] as String?);
      if (data == null) continue;
      final key = grade == 'PSA10' ? 'psa10' : grade == 'PSA9' ? 'psa9' : 'raw';
      final g = data[key] as Map<String, dynamic>?;
      final mj = (g?['avg'] as num?)?.round();
      if (mj == null) continue;
      try {
        await _client
            .from('collection')
            .update({'market_jpy': mj})
            .eq('user_id', userId)
            .eq('card_id', it['card_id'])
            .eq('grade', grade);
        updated++;
      } catch (_) {}
    }
    return updated;
  }

  static Future<List<Map<String, dynamic>>> getCollection() async {
    final userId = await getUserId();
    try {
      final res = await _client
          .from('collection')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static Future<Set<String>> getCollectedCardIds() async {
    final items = await getCollection();
    return items.map((r) => r['card_id'] as String).toSet();
  }

  static Future<int> getCollectionTotalValue() async {
    final items = await getCollection();
    return items.fold<int>(0, (sum, r) => sum + ((r['estimated_price_ntd'] as int?) ?? 0));
  }

  static Future<bool> isInCollection(String cardId) async {
    final userId = await getUserId();
    try {
      final res = await _client
          .from('collection')
          .select('card_id')
          .eq('user_id', userId)
          .eq('card_id', cardId)
          .limit(1);
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── SNKRDUNK 成交價快取 ─────────────────────────────────────────────────
  /// 取快取（1 天內視為新鮮）；回傳 payload（可能含 matched:false），過期/無 → null
  static Future<Map<String, dynamic>?> getSnkrCache(String cardId) async {
    try {
      final res = await _client
          .from('snkrdunk_prices')
          .select()
          .eq('card_id', cardId)
          .limit(1);
      if (res.isEmpty) return null;
      final row = res.first;
      final fetchedAt = DateTime.tryParse(row['fetched_at'] ?? '');
      if (fetchedAt == null ||
          DateTime.now().difference(fetchedAt).inHours >= 24) return null;
      final p = row['payload'];
      if (p is Map) return Map<String, dynamic>.from(p);
      if (p is String) return jsonDecode(p) as Map<String, dynamic>;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSnkrCache(String cardId, Map<String, dynamic> payload) async {
    try {
      await _client.from('snkrdunk_prices').upsert({
        'card_id': cardId,
        'payload': payload,
        'fetched_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  static Future<void> insertTransaction(Map<String, dynamic> tx) async {
    final userId = await getUserId();
    try {
      await _client.from('transactions').insert({
        ...tx,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> deleteTransaction(String id) async {
    try {
      await _client.from('transactions').delete().eq('id', id);
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getTransactionsForCard(String cardId) async {
    final userId = await getUserId();
    try {
      final res = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('card_id', cardId)
          .order('date', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}
