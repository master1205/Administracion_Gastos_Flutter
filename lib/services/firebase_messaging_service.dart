import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notificaciones/main.dart' show navigatorKey;
import 'package:notificaciones/models/Apartado.dart';
import 'package:notificaciones/apartado_detalle_screen.dart';
import 'package:notificaciones/apartados_screen.dart';

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

  /// Inicializar servicio de FCM (sin solicitar permisos)
  static Future<void> initialize() async {
    print('🔄 Inicializando Firebase Cloud Messaging...');

    // Intentar obtener token (solo funciona si ya hay permisos del onboarding)
    print('📡 Verificando token FCM...');
    final token = await _messaging.getToken();
    if (token != null) {
      print('✅ Token obtenido: ${token.substring(0, 30)}...');
      await _guardarTokenSiCambio(token);
    } else {
      print('ℹ️ Sin token - Permisos se solicitarán en onboarding');
    }

    // Configurar listener para regeneraciones futuras de token
    print('📡 Configurando listener de onTokenRefresh...');
    _messaging.onTokenRefresh.listen(
      (newToken) async {
        print('🔄 onTokenRefresh disparado - Token regenerado');
        print('📱 Nuevo token: ${newToken.substring(0, 30)}...');
        await _guardarTokenSiCambio(newToken);
      },
      onError: (error) {
        print('❌ Error en onTokenRefresh: $error');
      },
    );
    print('✅ Listener de onTokenRefresh configurado');

    // Configurar handler para mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Configurar handler para cuando el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Verificar si la app se abrió desde una notificación
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App abierta desde notificación: ${initialMessage.messageId}');
      _handleMessageOpenedApp(initialMessage);
    }

    print('✅ Firebase Cloud Messaging inicializado correctamente');
  }

  /// Solicitar permisos y configurar token (llamar desde onboarding)
  static Future<bool> requestPermissionsAndSetup() async {
    print('🔔 Solicitando permisos de notificaciones push...');

    try {
      // 1. Solicitar permisos
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificaciones push concedidos');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ Permisos de notificaciones push provisionales');
      } else {
        print('❌ Permisos de notificaciones push denegados');
        return false;
      }

      // 2. Obtener token inicial y guardarlo
      print('📡 Obteniendo token FCM...');
      final token = await _messaging.getToken();
      if (token != null) {
        print('✅ Token obtenido: ${token.substring(0, 30)}...');
        await _guardarTokenSiCambio(token);
        return true;
      } else {
        print('⚠️ No se pudo obtener el token');
        return false;
      }
    } catch (e) {
      print('❌ Error al solicitar permisos: $e');
      return false;
    }
  }

  /// Guardar token FCM en Firestore solo si cambió
  static Future<void> _guardarTokenSiCambio(String newToken) async {
    try {
      final docId = newToken.substring(0, 20);
      print('🔍 Verificando si el token cambió...');
      print('🔑 Document ID: $docId');

      // Verificar token actual en Firestore
      final docRef = _db.collection(_fcmTokenCollection).doc(docId);
      final snapshot = await docRef.get();
      final currentToken = snapshot.data()?['token'];

      if (currentToken != newToken) {
        print('💾 Token cambió - Guardando en Firestore...');
        await docRef.set({
          'token': newToken,
          'timestamp': FieldValue.serverTimestamp(),
          'platform': 'android',
          'activo': true,
        }, SetOptions(merge: true));

        print('✅ Token FCM guardado exitosamente');
        print('📍 Colección: $_fcmTokenCollection');
        print('📍 Documento: $docId');
      } else {
        print('ℹ️ Token no cambió - No se actualiza Firestore');
      }
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
      // Mostrar notificación local con el apartadoId como payload para navegación
      final payload =
          message.data['apartadoId'] != null
              ? 'apartado_${message.data['apartadoId']}'
              : message.data.toString();

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
        payload: payload,
      );

      print('✅ Notificación mostrada localmente');
    }
  }

  /// Manejar cuando el usuario toca una notificación push (FCM)
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('👆 Usuario tocó notificación: ${message.messageId}');
    print('📊 Data: ${message.data}');

    final screen = message.data['screen'];
    final apartadoId = message.data['apartadoId'];

    if (screen == 'apartados') {
      if (apartadoId != null) {
        navegarAApartado(apartadoId);
      } else {
        // Sin ID específico → ir a la lista de apartados
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          navigator.push(
            MaterialPageRoute(builder: (_) => const ApartadosScreen()),
          );
        }
      }
    }
  }

  /// Navega a la pantalla de detalle de un apartado por su ID.
  /// Público para ser reutilizado desde LocalNotifications.
  static Future<void> navegarAApartado(String apartadoId) async {
    try {
      final doc = await _db.collection('apartados').doc(apartadoId).get();
      if (!doc.exists) {
        print('⚠️ Apartado $apartadoId no encontrado');
        return;
      }

      final apartado = Apartado.fromFirestore(doc);
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ApartadoDetalleScreen(apartado: apartado),
          ),
        );
      }
    } catch (e) {
      print('❌ Error navegando a apartado: $e');
    }
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
