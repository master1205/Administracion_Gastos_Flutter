import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotifications {
  // Singleton Pattern
  static final LocalNotifications _instance = LocalNotifications._internal();
  factory LocalNotifications() => _instance;
  LocalNotifications._internal();

  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification IDs - Organizados
  static const int _morningNotificationId = 1;
  static const int _afternoonNotificationId = 2;
  static const int _nightNotificationId = 3;

  // Channel IDs con mejor nomenclatura
  static const String _morningChannelId = 'morning_reminder';
  static const String _afternoonChannelId = 'afternoon_reminder';
  static const String _nightChannelId = 'night_summary';

  // Preference Keys
  static const String _prefKeyNotificationsEnabled = 'notifications_enabled';
  static const String _prefKeyMorningEnabled = 'morning_notification_enabled';
  static const String _prefKeyAfternoonEnabled =
      'afternoon_notification_enabled';
  static const String _prefKeyNightEnabled = 'night_notification_enabled';

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notificacion');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Inicializar zonas horarias
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
  }

  // Callback cuando se toca una notificación
  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    print('Notificación tocada: ${response.payload}');
  }

  // ============================================================================
  // PERMISSION MANAGEMENT
  // ============================================================================

  static Future<bool> requestNotificationPermission() async {
    final androidPermission =
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();

    final iosPermission = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return androidPermission ?? iosPermission ?? false;
  }

  static Future<bool> requestAlarmExactPermission() async {
    return await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestExactAlarmsPermission() ??
        false;
  }

  static Future<bool> areNotificationsEnabled() async {
    final androidEnabled =
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();

    return androidEnabled ?? true;
  }

  // ============================================================================
  // SCHEDULE ALL NOTIFICATIONS
  // ============================================================================

  static Future<void> scheduleAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final globalEnabled = prefs.getBool(_prefKeyNotificationsEnabled) ?? true;

    if (!globalEnabled) return;

    final morningEnabled = prefs.getBool(_prefKeyMorningEnabled) ?? true;
    final afternoonEnabled = prefs.getBool(_prefKeyAfternoonEnabled) ?? true;
    final nightEnabled = prefs.getBool(_prefKeyNightEnabled) ?? true;

    if (morningEnabled) await scheduleDailyMorningNotification();
    if (afternoonEnabled) await scheduleDailyAfternoonNotification();
    if (nightEnabled) await scheduleDailyNightNotification();
  }

  // ============================================================================
  // MORNING NOTIFICATION (10:00 AM)
  // ============================================================================

  static Future<void> scheduleDailyMorningNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'Usuario';

    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      _morningChannelId,
      'Recordatorio Matutino',
      channelDescription: 'Notificaciones de recordatorio a las 10:00 AM',
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('moneda'),
      enableVibration: true,
      playSound: true,
      icon: 'ic_notificacion',
      styleInformation: BigTextStyleInformation(
        'Revisa tus gastos matutinos y mantén tu presupuesto bajo control. ¡Empieza el día con finanzas organizadas! 💰',
        contentTitle: '¡Buenos días, $username! 🌞',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _morningNotificationId,
      '¡Buenos días, $username! 🌞',
      'Revisa tus gastos matutinos y mantén tu presupuesto bajo control.',
      _nextInstanceOf(10, 0),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'morning_notification',
    );
  }

  // ============================================================================
  // AFTERNOON NOTIFICATION (3:00 PM)
  // ============================================================================

  static Future<void> scheduleDailyAfternoonNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'Usuario';

    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      _afternoonChannelId,
      'Recordatorio de Tarde',
      channelDescription: 'Notificaciones de registro a las 3:00 PM',
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('moneda'),
      enableVibration: true,
      playSound: true,
      icon: 'ic_notificacion',
      styleInformation: BigTextStyleInformation(
        'No olvides registrar tus compras de la tarde. Mantén tu historial actualizado para un mejor control financiero. 📊',
        contentTitle: '¡Hora de registrar, $username! ⏰',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _afternoonNotificationId,
      '¡Hora de registrar, $username! ⏰',
      'No olvides registrar tus compras de la tarde.',
      _nextInstanceOf(15, 0),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'afternoon_notification',
    );
  }

  // ============================================================================
  // NIGHT NOTIFICATION (9:30 PM)
  // ============================================================================

  static Future<void> scheduleDailyNightNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'Usuario';

    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      _nightChannelId,
      'Resumen Nocturno',
      channelDescription: 'Notificaciones de resumen a las 9:30 PM',
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('moneda'),
      enableVibration: true,
      playSound: true,
      icon: 'ic_notificacion',
      styleInformation: BigTextStyleInformation(
        'Cierra el día revisando tu resumen financiero. Registra tus últimos gastos y prepárate para un mejor mañana. 💪',
        contentTitle: 'Resumen del día, $username 🌙',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _nightNotificationId,
      'Resumen del día, $username 🌙',
      'Cierra el día revisando tu resumen financiero.',
      _nextInstanceOf(21, 30),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'night_notification',
    );
  }

  // ============================================================================
  // TIME CALCULATION HELPERS
  // ============================================================================

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // ============================================================================
  // CANCEL NOTIFICATIONS
  // ============================================================================

  static Future<void> cancelMorningNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_morningNotificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyMorningEnabled, false);
  }

  static Future<void> cancelAfternoonNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_afternoonNotificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyAfternoonEnabled, false);
  }

  static Future<void> cancelNightNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_nightNotificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNightEnabled, false);
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotificationsEnabled, false);
    await prefs.setBool(_prefKeyMorningEnabled, false);
    await prefs.setBool(_prefKeyAfternoonEnabled, false);
    await prefs.setBool(_prefKeyNightEnabled, false);
  }

  // ============================================================================
  // ENABLE/DISABLE NOTIFICATIONS
  // ============================================================================

  static Future<void> enableAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotificationsEnabled, true);
    await prefs.setBool(_prefKeyMorningEnabled, true);
    await prefs.setBool(_prefKeyAfternoonEnabled, true);
    await prefs.setBool(_prefKeyNightEnabled, true);
    await scheduleAllNotifications();
  }

  static Future<void> disableAllNotifications() async {
    await cancelAllNotifications();
  }

  static Future<void> toggleMorningNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyMorningEnabled, enabled);
    if (enabled) {
      await scheduleDailyMorningNotification();
    } else {
      await cancelMorningNotification();
    }
  }

  static Future<void> toggleAfternoonNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyAfternoonEnabled, enabled);
    if (enabled) {
      await scheduleDailyAfternoonNotification();
    } else {
      await cancelAfternoonNotification();
    }
  }

  static Future<void> toggleNightNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNightEnabled, enabled);
    if (enabled) {
      await scheduleDailyNightNotification();
    } else {
      await cancelNightNotification();
    }
  }

  // ============================================================================
  // GET NOTIFICATION STATUS
  // ============================================================================

  static Future<bool> isMorningNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyMorningEnabled) ?? true;
  }

  static Future<bool> isAfternoonNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyAfternoonEnabled) ?? true;
  }

  static Future<bool> isNightNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyNightEnabled) ?? true;
  }

  static Future<bool> areAllNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyNotificationsEnabled) ?? true;
  }

  // ============================================================================
  // PENDING NOTIFICATIONS INFO
  // ============================================================================

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  static Future<int> getPendingNotificationsCount() async {
    final pending = await getPendingNotifications();
    return pending.length;
  }

  // ============================================================================
  // INSTANT NOTIFICATION (Para testing)
  // ============================================================================

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'instant_notification',
          'Notificación Instantánea',
          channelDescription: 'Notificaciones inmediatas',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('moneda'),
          enableVibration: true,
          playSound: true,
          icon: 'ic_notificacion',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // ============================================================================
  // CUSTOM TIME NOTIFICATION
  // ============================================================================

  static Future<void> scheduleCustomNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'custom_notification',
          'Notificación Personalizada',
          channelDescription: 'Notificaciones con hora personalizada',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('moneda'),
          enableVibration: true,
          playSound: true,
          icon: 'ic_notificacion',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }
}
