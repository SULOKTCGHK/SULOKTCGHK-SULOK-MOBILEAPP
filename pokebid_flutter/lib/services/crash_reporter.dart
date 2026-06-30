import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// 統一的非致命錯誤記錄入口。
///
/// 把原本默默吞掉的 `catch (_) {}` 改成：
///   `catch (e, st) { CrashReporter.log(e, st, reason: '...'); }`
/// 讓「不致命但有意義」的失敗（例如存 token、寫通知失敗）也能在
/// Firebase Crashlytics 後台看到，封測時才不會盲。
///
/// 在 web / 桌面或 Firebase 未初始化時，recordError 會被內層 try 吞掉，
/// 只保留 debugPrint，不致額外報錯。
class CrashReporter {
  static void log(Object error, StackTrace? stack, {String? reason}) {
    debugPrint('⚠️ ${reason ?? 'error'}: $error');
    try {
      FirebaseCrashlytics.instance
          .recordError(error, stack, reason: reason, fatal: false);
    } catch (_) {
      // Crashlytics 不支援的平台（web/桌面）或尚未初始化：忽略。
    }
  }
}
