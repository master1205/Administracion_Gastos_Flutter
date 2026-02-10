import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notificaciones/services/firebase_messaging_service.dart';

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
  static const int _saturdayNotificationId = 4;
  static const int _monthEndNotificationId = 5;

  // Channel IDs con mejor nomenclatura
  static const String _morningChannelId = 'morning_reminder';
  static const String _afternoonChannelId = 'afternoon_reminder';
  static const String _nightChannelId = 'night_summary';
  static const String _saturdayChannelId = 'saturday_reminder';
  static const String _monthEndChannelId = 'month_end_reminder';

  // Preference Keys
  static const String _prefKeyNotificationsEnabled = 'notifications_enabled';
  static const String _prefKeyMorningEnabled = 'morning_notification_enabled';
  static const String _prefKeyAfternoonEnabled =
      'afternoon_notification_enabled';
  static const String _prefKeyNightEnabled = 'night_notification_enabled';
  static const String _prefKeySaturdayEnabled = 'saturday_notification_enabled';
  static const String _prefKeyMonthEndEnabled =
      'month_end_notification_enabled';

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

  // Callback cuando se toca una notificación local
  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    print('Notificación tocada: ${response.payload}');

    final payload = response.payload;
    if (payload != null && payload.startsWith('apartado_')) {
      final apartadoId = payload.replaceFirst('apartado_', '');
      // Reusar la navegación del servicio FCM
      FirebaseMessagingService.navegarAApartado(apartadoId);
    }
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
    final saturdayEnabled = prefs.getBool(_prefKeySaturdayEnabled) ?? true;
    final monthEndEnabled = prefs.getBool(_prefKeyMonthEndEnabled) ?? true;

    if (morningEnabled) await scheduleDailyMorningNotification();
    if (afternoonEnabled) await scheduleDailyAfternoonNotification();
    if (nightEnabled) await scheduleDailyNightNotification();
    if (saturdayEnabled) await scheduleWeeklySaturdayNotification();
    if (monthEndEnabled) await scheduleMonthlyEndNotification();
  }

  // ============================================================================
  // UPDATE USERNAME IN NOTIFICATIONS
  // ============================================================================

  /// ✅ AGREGAR ESTE MÉTODO AQUÍ
  static Future<void> updateUsername(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();

    // Guardar el nuevo nombre
    await prefs.setString('username', newUsername);

    // Obtener qué notificaciones están habilitadas
    final morningEnabled = await isMorningNotificationEnabled();
    final afternoonEnabled = await isAfternoonNotificationEnabled();
    final nightEnabled = await isNightNotificationEnabled();
    final saturdayEnabled = await isSaturdayNotificationEnabled();
    final monthEndEnabled = await isMonthEndNotificationEnabled();

    // Cancelar todas las notificaciones actuales
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Reprogramar solo las que estaban habilitadas
    if (morningEnabled) {
      await scheduleDailyMorningNotification(username: newUsername);
    }
    if (afternoonEnabled) {
      await scheduleDailyAfternoonNotification(username: newUsername);
    }
    if (nightEnabled) {
      await scheduleDailyNightNotification(username: newUsername);
    }
    if (saturdayEnabled) {
      await scheduleWeeklySaturdayNotification(username: newUsername);
    }
    if (monthEndEnabled) {
      await scheduleMonthlyEndNotification(username: newUsername);
    }
  }

  // ============================================================================
  // MORNING NOTIFICATION (10:00 AM)
  // ============================================================================

  static Future<void> scheduleDailyMorningNotification({
    String? username,
  }) async {
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

  static Future<void> scheduleDailyAfternoonNotification({
    String? username,
  }) async {
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

  static Future<void> scheduleDailyNightNotification({String? username}) async {
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
  // SATURDAY NOTIFICATION (8:00 PM - Reminder before Weekly Corte)
  // ============================================================================

  static Future<void> scheduleWeeklySaturdayNotification({
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'Usuario';

    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      _saturdayChannelId,
      'Recordatorio Semanal',
      channelDescription: 'Notificación de recordatorio los sábados',
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('moneda'),
      enableVibration: true,
      playSound: true,
      icon: 'ic_notificacion',
      styleInformation: BigTextStyleInformation(
        'Mañana domingo a la 1:00 AM se realizará el corte semanal. Asegúrate de registrar todas tus compras de la semana. 📋',
        contentTitle: '¡Corte semanal mañana, $username! 📅',
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
      _saturdayNotificationId,
      '¡Corte semanal mañana, $username! 📅',
      'No olvides registrar tus compras de la semana antes del corte.',
      _nextSaturday(21, 0),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'saturday_notification',
    );
  }

  // ============================================================================
  // MONTH END NOTIFICATION (8:00 PM - Reminder before Monthly Corte)
  // ============================================================================

  static Future<void> scheduleMonthlyEndNotification({String? username}) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'Usuario';

    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      _monthEndChannelId,
      'Recordatorio Mensual',
      channelDescription: 'Notificación de recordatorio el último día del mes',
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('moneda'),
      enableVibration: true,
      playSound: true,
      icon: 'ic_notificacion',
      styleInformation: BigTextStyleInformation(
        'Mañana se realizará el corte mensual a la 1:00 AM. Revisa y registra todas tus transacciones pendientes. Se generará el reporte automáticamente. 📊',
        contentTitle: '¡Corte mensual mañana, $username! 📆',
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
      _monthEndNotificationId,
      '¡Corte mensual mañana, $username! 📆',
      'Revisa todas tus transacciones antes del corte mensual.',
      _nextMonthEnd(21, 0),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'month_end_notification',
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

  static tz.TZDateTime _nextSaturday(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si hoy es sábado pero ya pasó la hora, programar para el próximo sábado
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Encontrar el próximo sábado (DateTime.saturday = 6)
    while (scheduledDate.weekday != DateTime.saturday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static tz.TZDateTime _nextMonthEnd(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Calcular el último día del mes actual
    int lastDayOfMonth = _getLastDayOfMonth(now.year, now.month);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      lastDayOfMonth,
      hour,
      minute,
    );

    // Si ya pasó, calcular el último día del mes siguiente
    if (scheduledDate.isBefore(now)) {
      int nextMonth = now.month + 1;
      int nextYear = now.year;

      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }

      lastDayOfMonth = _getLastDayOfMonth(nextYear, nextMonth);
      scheduledDate = tz.TZDateTime(
        tz.local,
        nextYear,
        nextMonth,
        lastDayOfMonth,
        hour,
        minute,
      );
    }

    return scheduledDate;
  }

  static int _getLastDayOfMonth(int year, int month) {
    // Crear fecha del primer día del mes siguiente y restar un día
    final firstDayNextMonth = DateTime(year, month + 1, 1);
    final lastDay = firstDayNextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
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

  static Future<void> cancelSaturdayNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_saturdayNotificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeySaturdayEnabled, false);
  }

  static Future<void> cancelMonthEndNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_monthEndNotificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyMonthEndEnabled, false);
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotificationsEnabled, false);
    await prefs.setBool(_prefKeyMorningEnabled, false);
    await prefs.setBool(_prefKeyAfternoonEnabled, false);
    await prefs.setBool(_prefKeyNightEnabled, false);
    await prefs.setBool(_prefKeySaturdayEnabled, false);
    await prefs.setBool(_prefKeyMonthEndEnabled, false);
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
    await prefs.setBool(_prefKeySaturdayEnabled, true);
    await prefs.setBool(_prefKeyMonthEndEnabled, true);
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

  static Future<void> toggleSaturdayNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeySaturdayEnabled, enabled);
    if (enabled) {
      await scheduleWeeklySaturdayNotification();
    } else {
      await cancelSaturdayNotification();
    }
  }

  static Future<void> toggleMonthEndNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyMonthEndEnabled, enabled);
    if (enabled) {
      await scheduleMonthlyEndNotification();
    } else {
      await cancelMonthEndNotification();
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

  static Future<bool> isSaturdayNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeySaturdayEnabled) ?? true;
  }

  static Future<bool> isMonthEndNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyMonthEndEnabled) ?? true;
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

  // ============================================================================
  // NOTIFICACIONES PERSONALIZADAS CON DÍAS ESPECÍFICOS
  // ============================================================================

  /// Programar notificación personalizada con días de la semana específicos
  static Future<void> scheduleCustomNotificationWithDays({
    required String notificationId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> weekdays, // 1=Lunes, 7=Domingo
  }) async {
    // Cancelar notificaciones anteriores de este ID
    await cancelCustomNotification(notificationId);

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

    // Programar una notificación por cada día seleccionado
    for (int day in weekdays) {
      final int notifId = _getNotificationIdForDay(notificationId, day);
      final tz.TZDateTime scheduledDate = _nextInstanceOfWeekday(
        hour,
        minute,
        day,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notifId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'custom_$notificationId',
      );
    }
  }

  /// Calcular la próxima instancia de un día de la semana específico
  static tz.TZDateTime _nextInstanceOfWeekday(
    int hour,
    int minute,
    int weekday,
  ) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Ajustar al día de la semana correcto
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Si ya pasó hoy, programar para la próxima semana
    if (scheduledDate.isBefore(now) && scheduledDate.weekday == now.weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Generar ID único para cada día de la semana
  static int _getNotificationIdForDay(String baseId, int day) {
    // Convertir el ID de texto a un número usando hash
    final baseHash = baseId.hashCode.abs() % 100000;
    return baseHash * 10 + day; // ID único por día
  }

  /// Cancelar notificación personalizada (todos los días)
  static Future<void> cancelCustomNotification(String notificationId) async {
    // Cancelar notificaciones de todos los días (1-7)
    for (int day = 1; day <= 7; day++) {
      final int notifId = _getNotificationIdForDay(notificationId, day);
      await _flutterLocalNotificationsPlugin.cancel(notifId);
    }
  }

  /// Cancelar una notificación específica de un día
  static Future<void> cancelCustomNotificationDay(
    String notificationId,
    int day,
  ) async {
    final int notifId = _getNotificationIdForDay(notificationId, day);
    await _flutterLocalNotificationsPlugin.cancel(notifId);
  }
}
