import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;
  static String? _userId;

  // ── User ID ───────────────────────────────────────────────────────────────
  static Future<String> getUserId() async {
    if (_userId != null) return _userId!;
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId == null) {
      _userId = const Uuid().v4();
      await prefs.setString('user_id', _userId!);
    }
    return _userId!;
  }

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

  static Future<void> removeFromCollection(String cardId) async {
    final userId = await getUserId();
    try {
      await _client
          .from('collection')
          .delete()
          .eq('user_id', userId)
          .eq('card_id', cardId);
    } catch (_) {}
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
