import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final _notificationController = StreamController<String>.broadcast();
  Stream<String> get onNotification => _notificationController.stream;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _notificationController.add(response.payload ?? '');
      },
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showSpotEnterNotification({
    required String spotId,
    required String spotName,
    required String description,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'spot_channel',
      '景点讲解',
      channelDescription: '进入景点时自动触发讲解',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      spotId.hashCode,
      '欢迎来到$spotName',
      description,
      details,
      payload: spotId,
    );
  }

  Future<void> showRouteRecommendationNotification({
    required String routeInfo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'route_channel',
      '路线推荐',
      channelDescription: '游览路线推荐通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      'route'.hashCode,
      '推荐游览路线',
      routeInfo,
      details,
    );
  }

  Future<void> showQuestionnaireNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'questionnaire_channel',
      '问卷调查',
      channelDescription: '用户体验问卷',
      importance: Importance.low,
      priority: Priority.low,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      'questionnaire'.hashCode,
      '游览结束',
      '感谢使用游伴！请花1分钟评价您的体验',
      details,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  void dispose() {
    _notificationController.close();
  }
}