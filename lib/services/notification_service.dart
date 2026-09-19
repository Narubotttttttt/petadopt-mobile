import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile_petadopt/services/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.initialize();
  final notification = message.notification;
  if (notification != null) {
    await NotificationService.showDirectPushNotification(
      id: message.hashCode,
      title: notification.title ?? 'CAWS PetAdopt',
      body: notification.body ?? '',
    );
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navKey;

  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (navigatorKey != null) _navKey = navigatorKey;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = const InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap();
      },
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    // Create high-priority Heads-Up Notification Channel on Android
    const androidChannel = AndroidNotificationChannel(
      'adoption_status_channel',
      'CAWS Alerts',
      description: 'Real-time alerts for adoption applications & medical updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await androidImpl?.createNotificationChannel(androidChannel);
  }

  static void _handleNotificationTap() {
    try {
      if (_navKey?.currentState != null) {
        _navKey!.currentState!.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (_) {}
  }

  /// Initialize Firebase & FCM real-time push listener
  static Future<void> setupFirebaseFCM({GlobalKey<NavigatorState>? navigatorKey}) async {
    try {
      if (navigatorKey != null) _navKey = navigatorKey;
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Enable heads-up notification in foreground
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final fcmToken = await messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await ApiService.saveFcmToken(fcmToken);
      }

      // Keep token synced if it refreshes
      messaging.onTokenRefresh.listen((newToken) async {
        await ApiService.saveFcmToken(newToken);
      });

      // Handle when user taps notification while app was closed or in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap();
      });

      // Handle real-time push when app is in foreground -> pop heads-up banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showDirectPushNotification(
            id: message.hashCode,
            title: notification.title ?? 'CAWS PetAdopt',
            body: notification.body ?? '',
          );
        }
      });
    } catch (_) {}
  }

  static Future<void> showDirectPushNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: title,
      htmlFormatContentTitle: false,
      summaryText: 'CAWS PetAdopt',
      htmlFormatSummaryText: false,
    );

    final androidDetails = AndroidNotificationDetails(
      'adoption_status_channel',
      'CAWS Alerts',
      channelDescription: 'Real-time alerts for adoption applications & medical updates',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: bigTextStyleInformation,
    );

    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}

