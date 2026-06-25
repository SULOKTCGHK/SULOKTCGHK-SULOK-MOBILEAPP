import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
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
      const InitializationSettings(android: androidInit, iOS: iosInit),
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
        notif.hashCode, notif.title, notif.body,
        NotificationDetails(
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
