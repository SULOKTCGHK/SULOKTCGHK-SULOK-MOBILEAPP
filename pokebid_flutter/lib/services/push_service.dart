import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

// Top-level handler — App 完全關閉時由系統喚醒執行，不能用 BuildContext
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

class PushService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();
  static final _client = Supabase.instance.client;

  // Android notification channel
  static const _channel = AndroidNotificationChannel(
    'tcgspot_high',
    'TCGspot 通知',
    description: '交易出價、訊息、評價等即時通知',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Web 目前不支援 FCM token 儲存（需另外設定 vapid key）
    if (kIsWeb) return;

    // 背景訊息 handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 請求通知權限
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 建立 Android channel
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 初始化本地通知
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // App 在前台時顯示本地 banner
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      _localNotif.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id, _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // iOS foreground 顯示 banner
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // 儲存 token 到 Supabase
    await _saveToken();

    // Token 刷新時更新
    _fcm.onTokenRefresh.listen((_) => _saveToken());
  }

  static Future<void> _saveToken() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final token = Platform.isIOS
          ? await _fcm.getAPNSToken().then((_) => _fcm.getToken())
          : await _fcm.getToken();
      if (token == null) return;
      await _client.from('profiles').update({
        'fcm_token': token,
        'fcm_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', AuthService.userId);
    } catch (_) {}
  }

  // 登出時清除 token，避免繼續收到通知
  static Future<void> clearToken() async {
    if (!AuthService.isLoggedIn) return;
    try {
      await _client.from('profiles').update({
        'fcm_token': null,
        'fcm_updated_at': null,
      }).eq('id', AuthService.userId);
      await _fcm.deleteToken();
    } catch (_) {}
  }
}
