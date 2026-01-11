import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handler de mensajes en background (debe estar en top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Notificación recibida en background: ${message.messageId}');
  print('📨 Título: ${message.notification?.title}');
  print('📨 Cuerpo: ${message.notification?.body}');
}

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _fcmTokenCollection = 'fcm_tokens';
  static String? _lastSavedToken; // Caché del último token guardado

  /// Inicializar servicio de FCM
  static Future<void> initialize() async {
    print('🔄 Inicializando Firebase Cloud Messaging...');

    // 1. Solicitar permisos
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificaciones concedidos');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ Permisos de notificaciones provisionales');
    } else {
      print('❌ Permisos de notificaciones denegados');
      return;
    }

    // 2. Obtener y guardar el token FCM (solo si cambió)
    final token = await _messaging.getToken();
    if (token != null && token != _lastSavedToken) {
      print('📱 FCM Token nuevo o actualizado: $token');
      await _guardarTokenEnFirestore(token);
      _lastSavedToken = token;
    } else if (token != null) {
      print('✓ Token FCM sin cambios');
      _lastSavedToken = token; // Actualizar caché sin escribir a Firestore
    }

    // 3. Escuchar cambios de token (cuando se regenera)
    _messaging.onTokenRefresh.listen((newToken) {
      _lastSavedToken = newToken; // Actualizar caché
      _guardarTokenEnFirestore(newToken);
    });

    // 4. Configurar handler para mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Configurar handler para cuando el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Verificar si la app se abrió desde una notificación
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App abierta desde notificación: ${initialMessage.messageId}');
      _handleMessageOpenedApp(initialMessage);
    }

    print('✅ Firebase Cloud Messaging inicializado correctamente');
  }

  /// Guardar token FCM en Firestore
  static Future<void> _guardarTokenEnFirestore(String token) async {
    try {
      // Usar el token como ID del documento (cada dispositivo tendrá su propio documento)
      final docId = token.substring(
        0,
        20,
      ); // Usar primeros 20 caracteres como ID

      await _db.collection(_fcmTokenCollection).doc(docId).set({
        'token': token,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'android',
        'activo': true, // Útil para identificar dispositivos activos
      }, SetOptions(merge: true));

      print('✅ Token FCM guardado en Firestore');
    } catch (e) {
      print('❌ Error al guardar token FCM: $e');
    }
  }

  /// Manejar mensajes cuando la app está en foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Notificación recibida en foreground: ${message.messageId}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      // Mostrar notificación local
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_channel',
            'Notificaciones Push',
            channelDescription: 'Notificaciones desde el servidor',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
              contentTitle: notification.title,
            ),
          ),
        ),
        payload: message.data.toString(),
      );

      print('✅ Notificación mostrada localmente');
    }
  }

  /// Manejar cuando el usuario toca una notificación
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('👆 Usuario tocó notificación: ${message.messageId}');
    print('📊 Data: ${message.data}');

    // Aquí puedes navegar a una pantalla específica según el payload
    // Por ejemplo, si viene data['screen'] = 'reportes'
    // Navegar a ReportesScreen
  }

  /// Obtener el token actual del dispositivo
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Eliminar el token cuando el usuario cierra sesión
  static Future<void> deleteToken() async {
    try {
      final token = await _messaging.getToken();
      await _messaging.deleteToken();

      // Eliminar de Firestore usando el token como ID
      if (token != null) {
        final docId = token.substring(0, 20);
        await _db.collection(_fcmTokenCollection).doc(docId).delete();
      }

      _lastSavedToken = null;
      print('✅ Token FCM eliminado');
    } catch (e) {
      print('❌ Error al eliminar token FCM: $e');
    }
  }

  /// Suscribirse a un topic (para notificaciones masivas)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Suscrito al topic: $topic');
    } catch (e) {
      print('❌ Error al suscribirse al topic: $e');
    }
  }

  /// Desuscribirse de un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Desuscrito del topic: $topic');
    } catch (e) {
      print('❌ Error al desuscribirse del topic: $e');
    }
  }
}
