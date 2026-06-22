import 'dart:convert';
import 'package:http/http.dart' as http;

/// 日圓 → 港幣 匯率（即時抓取，12 小時快取，失敗用後備值）
class CurrencyService {
  static double _jpyToHkd = 0.0515; // 後備值（約 1 JPY ≈ 0.0515 HKD）
  static DateTime? _fetchedAt;

  static Future<double> jpyToHkd() async {
    if (_fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!).inHours < 12) {
      return _jpyToHkd;
    }
    try {
      final res = await http.get(
          Uri.parse('https://api.frankfurter.app/latest?from=JPY&to=HKD'));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        final r = (d['rates']?['HKD'] as num?)?.toDouble();
        if (r != null && r > 0) {
          _jpyToHkd = r;
          _fetchedAt = DateTime.now();
        }
      }
    } catch (_) {/* 用後備值 */}
    return _jpyToHkd;
  }

  /// 已知匯率（同步，需先呼叫過 jpyToHkd）
  static double get rate => _jpyToHkd;

  static int jpyToHkdInt(num jpy) => (jpy * _jpyToHkd).round();
}
