import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'crash_reporter.dart';
import 'listing_service.dart';
import '../screens/card_detail_screen.dart';
import '../screens/conversations_list_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/received_offers_screen.dart';

// Top-level handler — App 完全關閉時由系統喚醒執行，不能用 BuildContext
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

class PushService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();
  static final _client = Supabase.instance.client;

  /// 全域 Navigator key，讓通知點擊可在沒有 BuildContext 時跳轉。
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const _channel = AndroidNotificationChannel(
    'tcgspot_high',
    'TCGspot 通知',
    description: '交易出價、訊息、評價等即時通知',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    final settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotif.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      // 前台顯示的本地通知被點擊
      onDidReceiveNotificationResponse: (resp) {
        if (resp.payload != null) {
          try { _route(Map<String, dynamic>.from(jsonDecode(resp.payload!))); } catch (_) {}
        }
      },
    );

    // 前台收到 → 顯示本地 banner（payload 帶上 data 供點擊跳轉）
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      _localNotif.show(
        id: notif.hashCode, title: notif.title, body: notif.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id, _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high, priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // App 在背景被點開
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _route(m.data));
    // App 被完全關閉、由通知點開
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _route(initial.data);

    await _fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    await _saveToken();
    _fcm.onTokenRefresh.listen((_) => _saveToken());
  }

  /// 依通知 data 跳轉到對應畫面。
  static Future<void> _route(Map<String, dynamic> data) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    final type = data['type'] as String?;
    final listingId = data['listing_id'] as String?;

    // 有商品 id → 開商品詳情
    if (listingId != null && listingId.isNotEmpty) {
      final card = await ListingService.getListingById(listingId);
      if (card != null) {
        nav.push(MaterialPageRoute(builder: (_) => CardDetailScreen(
            card: card, isFavorited: false, onFavChanged: (_) {})));
        return;
      }
    }
    switch (type) {
      case 'message':
        nav.push(MaterialPageRoute(builder: (_) => const ConversationsListScreen()));
      case 'offer_received':
        nav.push(MaterialPageRoute(builder: (_) => const ReceivedOffersScreen()));
      default:
        nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  }

  static Future<void> _saveToken() async {
    if (!AuthService.isLoggedIn) return;
    try {
      // iOS：APNs 註冊是異步的，等它就緒（最多 ~15 秒）再拿 FCM token
      if (Platform.isIOS) {
        String? apns;
        for (var i = 0; i < 10 && apns == null; i++) {
          apns = await _fcm.getAPNSToken();
          if (apns == null) await Future.delayed(const Duration(milliseconds: 1500));
        }
        if (apns == null) return; // 之後 onTokenRefresh 會補存
      }
      final token = await _fcm.getToken();
      if (token == null) return;
      await _client.from('profiles').update({
        'fcm_token': token,
        'fcm_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', AuthService.userId);
    } catch (e, st) {
      CrashReporter.log(e, st, reason: 'FCM token 儲存失敗（推播將收不到）');
    }
  }

  /// 臨時診斷：逐環檢查推播鏈路，回傳可顯示的文字。
  static Future<String> diagnose() async {
    final b = StringBuffer();
    b.writeln('登入: ${AuthService.isLoggedIn ? "✅ ${AuthService.userId}" : "❌ 未登入"}');
    try {
      final s = await _fcm.getNotificationSettings();
      b.writeln('通知權限: ${s.authorizationStatus.name}');
    } catch (e) { b.writeln('通知權限: ❌ $e'); }
    String? apns;
    try {
      apns = await _fcm.getAPNSToken();
      b.writeln('APNs token: ${apns != null ? "✅ ${apns.substring(0, 12)}…" : "❌ null"}');
    } catch (e) { b.writeln('APNs token: ❌ $e'); }
    try {
      final t = await _fcm.getToken();
      b.writeln('FCM token: ${t != null ? "✅ ${t.substring(0, 16)}…" : "❌ null"}');
    } catch (e) { b.writeln('FCM token: ❌ $e'); }
    if (AuthService.isLoggedIn) {
      try {
        await _saveToken();
        b.writeln('寫入DB: 已嘗試（查 fcm_updated_at 確認）');
      } catch (e) { b.writeln('寫入DB: ❌ $e'); }
    }
    return b.toString();
  }

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
