import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedService {
  static const _key = 'recently_viewed_v1';
  static const _max = 30;

  static final _controller = StreamController<void>.broadcast();
  // 任何地方記錄後，首頁可訂閱此 stream 刷新
  static Stream<void> get onChange => _controller.stream;

  // 記錄一次瀏覽（id 唯一，重複則移到最前）
  static Future<void> record(Map<String, dynamic> snapshot) async {
    final id = snapshot['id'] as String?;
    if (id == null || id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final list = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    list.removeWhere((e) => e['id'] == id);
    list.insert(0, snapshot);
    if (list.length > _max) list.removeRange(_max, list.length);
    await prefs.setString(_key, jsonEncode(list));
    _controller.add(null); // 通知訂閱者
  }

  // 讀取最近瀏覽清單
  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
