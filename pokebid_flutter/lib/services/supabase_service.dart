import 'dart:convert';
import 'dart:typed_data';
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

  // ── Admin 圖片管理 ─────────────────────────────────────────────────────────
  /// 上傳圖片到 card-images bucket，回傳含版本參數的公開網址（admin 用）
  static Future<String?> uploadAdminImage(Uint8List bytes, String path) async {
    try {
      await _client.storage.from('card-images').uploadBinary(
            path, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      final url = _client.storage.from('card-images').getPublicUrl(path);
      return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return null;
    }
  }

  static Future<bool> setSetLogo(String setId, String url) async {
    try {
      await _client.from('cached_sets').update({'logo_image': url}).eq('id', setId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 找出 image_small 為空（null）的卡片
  static Future<List<Map<String, dynamic>>> getCardsMissingImage({int limit = 100}) async {
    try {
      final res = await _client.from('cached_cards')
          .select('id, name, image_small, set_name, number')
          .isFilter('image_small', null)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> setCardImage(String cardId, String url) async {
    try {
      await _client.from('cached_cards')
          .update({'image_small': url, 'image_large': url}).eq('id', cardId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // 讀單張卡（含 psa_spec_id）
  static Future<Map<String, dynamic>?> getCardById(String cardId) async {
    try {
      final res = await _client.from('cached_cards')
          .select().eq('id', cardId).maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  // ── PSA Pop ───────────────────────────────────────────────────────────────

  // 讀取緩存的 PSA pop（給卡片詳情頁用）
  static Future<Map<String, dynamic>?> getPsaPop(String specId) async {
    try {
      final res = await _client
          .from('psa_pop_cache')
          .select()
          .eq('spec_id', specId)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  // 設定卡片的 psa_spec_id（admin 用）
  static Future<bool> setCardSpecId(String cardId, String specId) async {
    try {
      await _client.from('cached_cards')
          .update({'psa_spec_id': specId}).eq('id', cardId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // 觸發 edge function 抓取 PSA pop（admin 用，by specId）
  static Future<Map<String, dynamic>?> fetchPsaPop(String specId) async {
    try {
      final res = await _client.functions.invoke(
        'psa-pop', body: {'spec_id': specId});
      if (res.status != 200) return null;
      final data = res.data as Map<String, dynamic>?;
      return data?['data'];
    } catch (_) {
      return null;
    }
  }

  // 用 cert number 查 PSA pop（用戶上架時用，by certNumber）
  // card_id 可選：有的話順便把 spec_id 寫入 cached_cards
  static Future<bool> fetchPsaPopByCert(String certNumber,
      {String? cardId, String? cachedCardId, String? setId, String? cardNumber}) async {
    try {
      final res = await _client.functions.invoke('psa-pop', body: {
        'cert_number': certNumber,
        if (cardId != null) 'card_id': cardId,
        if (cachedCardId != null && cachedCardId.isNotEmpty) 'cached_card_id': cachedCardId,
        if (setId != null && setId.isNotEmpty) 'set_id': setId,
        if (cardNumber != null && cardNumber.isNotEmpty) 'card_number': cardNumber,
      });
      return res.status == 200;
    } catch (_) {
      return false;
    }
  }

  // 給圖鑑詳情頁用：先查 cached_cards.psa_spec_id，再嘗試從 listings 找同張卡的 cert/spec_id
  static Future<Map<String, dynamic>?> getPsaPopForDexCard({
    required String cachedCardId,
    String? setId,
    String? cardNumber,
  }) async {
    // 1. 先查 cached_cards 本身的 spec_id（admin 設的）
    try {
      final row = await _client.from('cached_cards').select('psa_spec_id').eq('id', cachedCardId).maybeSingle();
      final specId = row?['psa_spec_id'] as String?;
      if (specId != null && specId.isNotEmpty) {
        return getPsaPop(specId);
      }
    } catch (_) {}

    // 2. 從 marketplace listings 找同張卡（set_id + card_number）有沒有 cert/spec_id
    if (setId != null && setId.isNotEmpty && cardNumber != null && cardNumber.isNotEmpty) {
      try {
        final rows = await _client.from('listings')
            .select('psa_cert, psa_spec_id')
            .eq('set_id', setId)
            .eq('card_number', cardNumber)
            .not('psa_cert', 'is', null)
            .order('created_at', ascending: false)
            .limit(1);
        if (rows.isNotEmpty) {
          final listing = rows[0];
          final specId = listing['psa_spec_id'] as String?;
          final cert = listing['psa_cert'] as String?;
          return getPsaPopForListing(psaSpecId: specId, psaCert: cert);
        }
      } catch (_) {}
    }
    return null;
  }

  // 給 listing 詳情頁用：先查 specId，沒有就用 cert 觸發 fetch
  static Future<Map<String, dynamic>?> getPsaPopForListing({
    String? psaSpecId,
    String? psaCert,
  }) async {
    // 1. specId 已知 → 直接查 cache
    if (psaSpecId != null && psaSpecId.isNotEmpty) {
      return getPsaPop(psaSpecId);
    }
    // 2. 有 cert → edge function fetch（會 cache），再讀回來
    if (psaCert != null && psaCert.isNotEmpty) {
      try {
        final res = await _client.functions.invoke('psa-pop', body: {'cert_number': psaCert});
        if (res.status == 200) {
          final data = res.data as Map<String, dynamic>?;
          return data?['data'];
        }
      } catch (_) {}
    }
    return null;
  }

  // 搜尋 cached_cards（上架時選卡用）
  // 支援任意順序 token：如 "DP-P 126" / "126 DP-P" / "126/DP-P" 都能找到
  static Future<List<Map<String, dynamic>>> searchCachedCards(String query) async {
    if (query.trim().isEmpty) return [];
    // 拆 token（空格、斜線分隔）
    final tokens = query.trim().split(RegExp(r'[\s/]+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return [];
    try {
      // 用第一個 token 做初步過濾（name / set_id / number 任一符合）
      final first = tokens[0];
      final res = await _client.from('cached_cards')
          .select('id, name, number, set_id, image_small')
          .or('name.ilike.%$first%,set_id.ilike.%$first%,number.ilike.%$first%')
          .order('set_id')
          .limit(200);
      final all = (res as List).cast<Map<String, dynamic>>();

      // 剩餘 token 在 client 端過濾（所有 token 都要匹配 name/set_id/number 其中一個）
      if (tokens.length == 1) return all.take(40).toList();
      return all.where((c) {
        final name = (c['name'] as String? ?? '').toLowerCase();
        final sid  = (c['set_id'] as String? ?? '').toLowerCase();
        final num  = (c['number'] as String? ?? '').toLowerCase();
        return tokens.every((t) {
          final tl = t.toLowerCase();
          return name.contains(tl) || sid.contains(tl) || num.contains(tl);
        });
      }).take(40).toList();
    } catch (_) {
      return [];
    }
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

  /// 取得精靈名稱（en/zh）。優先從 Supabase 抓，成功後快取到本機；
  /// 失敗（如離線）時用上次快取，確保畫面不空白。
  static Future<List<Map<String, dynamic>>> getPokemonNames() async {
    const cacheKey = 'pokemon_names_cache';
    try {
      final res = await _client
          .from('pokemon_names')
          .select('id, en, zh')
          .order('id', ascending: true);
      final list = List<Map<String, dynamic>>.from(res);
      if (list.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(list));
        return list;
      }
    } catch (_) {}
    // fallback：本機快取
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cached) as List);
      }
    } catch (_) {}
    return [];
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


  // 精靈圖鑑專用：搜尋名稱開頭符合的所有卡（上限500）
  static Future<List<Map<String, dynamic>>> searchCardsByPokemon(String pokemonName) async {
    try {
      final res = await _client
          .from('cached_cards')
          .select()
          .ilike('name', '%$pokemonName%')
          .order('name')
          .limit(500);
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

  /// 收藏總市值的每日走勢（港幣）：用各卡 SNKRDUNK 每日均價加總（carry-forward）
  /// 回傳 { points:[double], labels:[String], chgPct:double? }
  static Future<Map<String, dynamic>> getCollectionValueSeries() async {
    final items = (await getCollection())
        .where((e) => (e['status'] as String?) != 'sold').toList();
    if (items.isEmpty) return {'points': <double>[], 'labels': <String>[], 'chgPct': null};
    final rate = await CurrencyService.jpyToHkd();
    final ids = items.map((e) => e['card_id'] as String).toSet().toList();

    List res = [];
    try {
      res = await _client.from('snkrdunk_prices').select('card_id,payload').inFilter('card_id', ids);
    } catch (_) {}
    final Map<String, dynamic> payloadByCard = {
      for (final r in res) (r['card_id'] as String): r['payload']
    };

    // 每個 item -> 排序後的 (date, avgJpy)
    final List<List<MapEntry<String, num>>> itemSeries = [];
    final Set<String> allDates = {};
    for (final it in items) {
      final grade = (it['grade'] as String?) ?? 'RAW';
      final key = grade == 'PSA10' ? 'psa10' : grade == 'PSA9' ? 'psa9' : 'raw';
      final p = payloadByCard[it['card_id']];
      final daily = (p is Map ? (p[key] is Map ? p[key]['daily'] : null) : null) as List?;
      final entries = <MapEntry<String, num>>[];
      if (daily != null) {
        for (final d in daily) {
          final ds = d['d'] as String?;
          final av = d['avg'] as num?;
          if (ds != null && av != null) { entries.add(MapEntry(ds, av)); allDates.add(ds); }
        }
        entries.sort((a, b) => a.key.compareTo(b.key));
      }
      itemSeries.add(entries);
    }
    if (allDates.length < 2) return {'points': <double>[], 'labels': <String>[], 'chgPct': null};

    final dates = allDates.toList()..sort();
    final points = <double>[];
    for (final date in dates) {
      double sumJpy = 0;
      for (final entries in itemSeries) {
        num? carry;
        for (final e in entries) {
          if (e.key.compareTo(date) <= 0) {
            carry = e.value;
          } else {
            break;
          }
        }
        if (carry != null) sumJpy += carry.toDouble();
      }
      points.add(sumJpy * rate);
    }
    double? chgPct;
    if (points.length >= 2 && points.first > 0) {
      chgPct = (points.last - points.first) / points.first * 100;
    }
    return {
      'points': points,
      'labels': dates.map((d) => d.substring(5).replaceAll('-', '/')).toList(),
      'chgPct': chgPct,
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
      // 收藏市值用「最新成交價」，沒有才退回均價
      final mj = ((g?['latest'] as num?) ?? (g?['avg'] as num?))?.round();
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
          DateTime.now().difference(fetchedAt).inHours >= 24) {
        return null;
      }
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
