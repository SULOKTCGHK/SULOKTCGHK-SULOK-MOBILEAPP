import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/set_name_zh.dart';
import '../config/env.dart';
import 'supabase_service.dart';
import '../i18n/locale_controller.dart';

// TCGdex 日版 API — 免費、支援 CORS、有日文資料
const String _baseUrl = 'https://api.tcgdex.net/v2/ja';

// JustTCG API — 日版 Promo 卡資料來源
const String _justTcgBase = 'https://api.justtcg.com/v1';
// 密鑰由 --dart-define-from-file=env.json 注入（見 lib/config/env.dart）
final String _justTcgKey = Env.justTcgKey;

// JustTCG set ID mapping: our promo set_id → JustTCG set id + number filter
const Map<String, Map<String, String>> kPromoSetConfig = {
  'SV-P': { 'justId': 'sv-scarlet-violet-promo-cards-pokemon', 'filter': ''       },
  'S-P':  { 'justId': 'swsh-sword-shield-promo-cards-pokemon',  'filter': '/S-P'  },
  'SM-P': { 'justId': 'sm-promos-pokemon',                      'filter': '/SM-P' },
  'XY-P': { 'justId': 'xy-promos-pokemon',                      'filter': '/XY-P' },
  'BW-P': { 'justId': 'black-and-white-promos-pokemon',         'filter': '/BW-P' },
  'DP-P': { 'justId': 'diamond-and-pearl-promos-pokemon',       'filter': '/DP-P' },
};

// TCGdex set name caches: lowercased id → localized name
Map<String, String> _zhTwSetNamesCache = {};
Map<String, String> _enSetNamesCache = {};

/// 球種/花紋變體 → 繁中標籤（找不到時去掉 " Pattern" 原樣顯示）
String variantLabelZh(String? variant) {
  if (variant == null || variant.isEmpty) return '';
  const map = {
    'poke ball pattern': '精靈球',
    'master ball pattern': '大師球',
    'great ball pattern': '超級球',
    'ultra ball pattern': '高級球',
    'quick ball pattern': '速度球',
    'love ball pattern': '愛心球',
    'heal ball pattern': '治療球',
    'energy symbol pattern': '能量符號',
  };
  return map[variant.toLowerCase()] ?? variant.replaceAll(RegExp(r'\s*Pattern$'), '');
}

class ApiCard {
  final String id;
  final String name;
  final String? imageSmall;
  final String? imageLarge;
  final String? rarity;
  final String? setName;
  final String? setId;
  final String? number;      // localId — 系列內編號 e.g. "001"
  final String? supertype;   // category: Pokémon / Trainer / Energy
  final List<String> types;
  final String? variant;     // 花紋/球種變體，如 "Poke Ball Pattern"

  ApiCard({
    required this.id,
    required this.name,
    this.imageSmall,
    this.imageLarge,
    this.rarity,
    this.setName,
    this.setId,
    this.number,
    this.supertype,
    this.types = const [],
    this.variant,
  });

  /// 去掉名稱中的變體括號（顯示用）
  String get cleanName => name.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();

  factory ApiCard.fromJson(Map<String, dynamic> json, {String? setName, String? setId}) {
    final localId = json['localId']?.toString() ?? json['id']?.toString() ?? '';
    final globalId = setId != null ? '$setId-$localId' : (json['id'] ?? localId);

    // TCGdex image URL pattern
    final imageBase = json['image'] as String?;
    final imageSmall = imageBase != null ? '$imageBase/low.webp' : null;
    final imageLarge = imageBase != null ? '$imageBase/high.webp' : null;

    return ApiCard(
      id: globalId,
      name: json['name'] ?? '',
      imageSmall: imageSmall,
      imageLarge: imageLarge,
      rarity: json['rarity'],
      setName: setName ?? json['set']?['name'],
      setId: setId ?? json['set']?['id'],
      number: localId,
      supertype: json['category'],
      types: List<String>.from(json['types'] ?? []),
    );
  }

  // TCGdex 沒有價格，固定回傳 0（由用戶手動輸入成交價）
  int get estimatedPriceNTD => 0;

  String get displayNumber => number != null && number!.isNotEmpty ? '#$number' : '';
  String get displaySet => '${setName ?? ''} $displayNumber'.trim();
}

class ApiSet {
  final String id;
  final String name;       // 原始日文名稱（用於版本過濾）
  final String? series;    // 原始日文系列名稱
  final String? seriesId;  // 系列 ID，如 'sv', 'ss'
  final String? releaseDate;
  final String? symbolImage;
  final String? logoImage;
  final int total;

  ApiSet({
    required this.id,
    required this.name,
    this.series,
    this.seriesId,
    this.releaseDate,
    this.symbolImage,
    this.logoImage,
    this.total = 0,
  });

  /// 顯示名稱（依當前語言）。
  /// 英文：TCGdex en 快取 → 日文原名。
  /// 中文：TCGdex zh-tw 快取 → 靜態繁中 map → 日文原名。
  String get displayName {
    final key = id.toLowerCase();
    if (localeController.isEnglish) {
      final en = _enSetNamesCache[key];
      return (en != null && en.isNotEmpty) ? en : name;
    }
    final cached = _zhTwSetNamesCache[key];
    if (cached != null && cached.isNotEmpty) return cached;
    return setNameZh(id, name);
  }

  /// 繁體中文大系列名稱
  String get displaySeries => seriesNameZh(seriesId, series);

  factory ApiSet.fromJson(Map<String, dynamic> json) {
    final setId = json['id'] as String? ?? '';
    final serieId = (json['serie']?['id'] as String? ?? '').toLowerCase();

    // If API already provides logo/symbol URLs, use them directly
    final logoBase = json['logo'] as String?;
    final symbolBase = json['symbol'] as String?;

    // Otherwise construct from known TCGdex asset pattern
    final logoImage = logoBase != null
        ? '$logoBase.png'
        : serieId.isNotEmpty
            ? 'https://assets.tcgdex.net/ja/$serieId/$setId/logo.png'
            : null;
    final symbolImage = symbolBase != null
        ? '$symbolBase.png'
        : serieId.isNotEmpty
            ? 'https://assets.tcgdex.net/ja/$serieId/$setId/symbol.png'
            : null;

    return ApiSet(
      id: setId,
      name: json['name'] ?? '',
      series: json['serie']?['name'] ?? json['series'],
      seriesId: serieId.isNotEmpty ? serieId : null,
      releaseDate: json['releaseDate'],
      symbolImage: symbolImage,
      logoImage: logoImage,
      total: json['cardCount']?['total'] ?? json['total'] ?? 0,
    );
  }
}

class PokemonApiService {
  static bool _zhTwFetched = false;
  static bool _enFetched = false;

  /// 抓取系列名稱（依當前語言抓 TCGdex 對應端點，各語言只抓一次並快取）。
  /// 保留舊名 fetchZhTwSetNames 以相容既有呼叫點。
  static Future<void> fetchZhTwSetNames() => fetchSetNames();

  /// 依當前語言抓 TCGdex 系列名稱。語言切換後可再呼叫一次補抓英文。
  static Future<void> fetchSetNames() async {
    if (localeController.isEnglish) {
      if (_enFetched) return;
      _enFetched = true;
      await _fetchInto('https://api.tcgdex.net/v2/en/sets', _enSetNamesCache);
    } else {
      if (_zhTwFetched) return;
      _zhTwFetched = true;
      await _fetchInto('https://api.tcgdex.net/v2/zh-tw/sets', _zhTwSetNamesCache);
    }
    // 名稱抓回後刷新畫面，讓已渲染的系列名更新為對應語言
    localeController.refresh();
  }

  static Future<void> _fetchInto(String url, Map<String, String> cache) async {
    try {
      final res = await http.get(Uri.parse(url),
          headers: {'Content-Type': 'application/json'});
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body);
        for (final e in raw) {
          if (e['id'] != null && e['name'] != null) {
            cache[(e['id'] as String).toLowerCase()] = e['name'] as String;
          }
        }
      }
    } catch (_) {}
  }

  /// 依當前語言查系列名稱。
  /// 英文：TCGdex en 快取 → 日文原名（靜態 map 無對應）→ setId。
  /// 中文：TCGdex zh-tw 快取 → 靜態繁中 map → setId。
  /// （函式名保留 zhTwSetName 以相容既有呼叫點。）
  static String zhTwSetName(String setId) {
    final key = setId.toLowerCase();
    if (localeController.isEnglish) {
      return _enSetNamesCache[key] ?? setId;
    }
    return _zhTwSetNamesCache[key] ?? kSetNameZh[key] ?? setId;
  }

  // Fetch all Japanese sets
  static Future<List<ApiSet>> fetchSets() async {
    try {
      final uri = Uri.parse('$_baseUrl/sets');
      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body);
        final sets = raw.map((e) => ApiSet.fromJson(e as Map<String, dynamic>)).toList();
        // Sort newest first by releaseDate
        sets.sort((a, b) => (b.releaseDate ?? '').compareTo(a.releaseDate ?? ''));
        return sets;
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  // Fetch cards for a specific set (with pagination)
  static Future<List<ApiCard>> fetchCardsForSet(
      String setId, {int page = 1, int pageSize = 10}) async {
    try {
      // TCGdex returns all cards for a set in one call
      final uri = Uri.parse('$_baseUrl/sets/$setId');
      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final setName = data['name'] as String?;
        final List raw = data['cards'] ?? [];

        // Manual pagination
        final allCards = raw
            .map((e) => ApiCard.fromJson(e as Map<String, dynamic>, setName: setName, setId: setId))
            .toList();

        final start = (page - 1) * pageSize;
        if (start >= allCards.length) return [];
        final end = (start + pageSize).clamp(0, allCards.length);
        return allCards.sublist(start, end);
      }
    } catch (_) {}
    return [];
  }

  // Get total card count for a set (for pagination)
  static Future<int> fetchSetTotal(String setId) async {
    try {
      final uri = Uri.parse('$_baseUrl/sets/$setId');
      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final List cards = data['cards'] ?? [];
        return cards.length;
      }
    } catch (_) {}
    return 0;
  }

  // Search cards by name (Japanese)
  static Future<List<ApiCard>> searchCards(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/cards?name=$query');
      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body);
        return raw
            .map((e) => ApiCard.fromJson(e as Map<String, dynamic>))
            .take(20)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // Fetch single card detail
  static Future<ApiCard?> fetchCardById(String setId, String localId) async {
    try {
      final uri = Uri.parse('$_baseUrl/cards/$setId-$localId');
      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return ApiCard.fromJson(data, setId: setId);
      }
    } catch (_) {}
    return null;
  }

  /// 查 SNKRDUNK 日本市場成交價（含快取，1 天內讀 DB、過期才重查 Edge Function）
  /// 回傳 matched 的資料；無配對回 null
  static Future<Map<String, dynamic>?> getSnkrdunkPrice(
      String cardId, String name, String? number) async {
    // 1) 先讀快取
    final cached = await SupabaseService.getSnkrCache(cardId);
    if (cached != null) {
      return cached['matched'] == true ? cached : null;
    }
    // 2) 過期/無 → 呼叫 Edge Function
    final raw = await _fetchSnkrdunkRaw(name, number);
    // 3) 寫回快取（連 matched:false 也存，避免每次重查未配對的卡）
    await SupabaseService.saveSnkrCache(cardId, raw ?? {'matched': false});
    return (raw != null && raw['matched'] == true) ? raw : null;
  }

  static Future<Map<String, dynamic>?> _fetchSnkrdunkRaw(String name, String? number) async {
    try {
      var n = name.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
      n = n.replaceAll(RegExp(r'\s*-\s*\S+$'), '').trim();
      final uri = Uri.parse(
        'https://ytlfarwaawxfvutviohe.supabase.co/functions/v1/snkrdunk-price'
        '?name=${Uri.encodeQueryComponent(n)}'
        '${(number != null && number.isNotEmpty) ? '&number=${Uri.encodeQueryComponent(number)}' : ''}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch promo cards from JustTCG API.
  /// [promoSetId] is our internal ID like 'SV-P', 'S-P', etc.
  /// Returns all matching cards across all pages.
  static Future<List<ApiCard>> fetchPromoCardsForSet(
    String promoSetId, {
    int page = 1,
    int limit = 20,
  }) async {
    final config = kPromoSetConfig[promoSetId];
    if (config == null) return [];

    final justId = config['justId']!;
    final numberFilter = config['filter']!; // e.g. '/S-P', '' for SV-P

    try {
      final uri = Uri.parse(
        '$_justTcgBase/cards?game=Pokemon&set=$justId&limit=$limit&page=$page&include_price_history=false',
      );
      final res = await http.get(uri, headers: {
        'x-api-key': _justTcgKey,
        'Content-Type': 'application/json',
      });

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List rawCards = body is List ? body : (body['data'] ?? body['cards'] ?? []);

        final cards = <ApiCard>[];
        for (final e in rawCards) {
          final map = e as Map<String, dynamic>;
          final number = map['number']?.toString() ?? map['cardNumber']?.toString() ?? '';

          // Filter by Japanese promo number pattern when needed
          if (numberFilter.isNotEmpty && !number.contains(numberFilter)) continue;

          // Map JustTCG fields → ApiCard
          final imgSmall = map['imageUrl'] as String? ??
              map['image_url'] as String? ??
              map['images']?['small'] as String?;
          final imgLarge = map['imageLargeUrl'] as String? ??
              map['image_large_url'] as String? ??
              map['images']?['large'] as String? ??
              imgSmall;

          final name = map['name'] as String? ?? '';
          final id = '$promoSetId-$number';

          cards.add(ApiCard(
            id: id,
            name: name,
            imageSmall: imgSmall,
            imageLarge: imgLarge,
            rarity: map['rarity'] as String?,
            setId: promoSetId,
            setName: map['setName'] as String? ?? promoSetId,
            number: number,
            supertype: map['supertype'] as String? ?? map['category'] as String?,
            types: List<String>.from(map['types'] ?? []),
          ));
        }
        return cards;
      }
    } catch (_) {}
    return [];
  }

  /// Fetch ALL promo cards across all pages for a given promo set.
  static Future<List<ApiCard>> fetchAllPromoCards(String promoSetId) async {
    final all = <ApiCard>[];
    int page = 1;
    while (true) {
      final batch = await fetchPromoCardsForSet(promoSetId, page: page);
      if (batch.isEmpty) break;
      all.addAll(batch);
      if (batch.length < 20) break; // last page
      page++;
      // Respect JustTCG free-tier rate limits
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return all;
  }
}
