import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全域語言控制器。切換時通知 MaterialApp 重建整個 App。
/// 支援：繁體中文 (zh) / English (en)
class LocaleController extends ValueNotifier<Locale> {
  LocaleController._() : super(const Locale('zh'));

  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'app_locale';

  /// 啟動時載入已儲存的語言（在 runApp 前呼叫）
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      // 相容舊版以中文字串儲存的設定
      final legacy = prefs.getString('language');
      if (code == 'en' || legacy == 'English') {
        value = const Locale('en');
      } else {
        value = const Locale('zh');
      }
    } catch (_) {
      value = const Locale('zh');
    }
  }

  bool get isEnglish => value.languageCode == 'en';

  /// 顯示用語言名稱
  String get label => isEnglish ? 'English' : '繁體中文';

  Future<void> setLocale(Locale locale) async {
    if (value.languageCode == locale.languageCode) return;
    value = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
      // 同步舊 key，避免設定頁顯示不一致
      await prefs.setString('language', isEnglish ? 'English' : '繁體中文');
    } catch (_) {}
  }

  Future<void> toggleByLabel(String label) =>
      setLocale(Locale(label == 'English' ? 'en' : 'zh'));
}

/// 全域便捷存取
LocaleController get localeController => LocaleController.instance;
