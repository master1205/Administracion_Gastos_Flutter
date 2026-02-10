import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/firebase_options.dart';
import 'package:notificaciones/loading_screen.dart';
import 'package:notificaciones/local_notifications.dart';
import 'package:notificaciones/onboarding_screen.dart';
import 'package:notificaciones/permission_handler.dart';
import 'package:notificaciones/services/firebase_messaging_service.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave global de navegación para acceder al Navigator desde servicios estáticos.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Configurar handler para notificaciones en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ✅ Habilitar cache offline de Firebase
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await LocalNotifications.initialize();

  // ✅ Inicializar Firebase Cloud Messaging
  await FirebaseMessagingService.initialize();

  print(
    '✅ App inicializada - Los cortes se ejecutan automáticamente desde Google Apps Script',
  );
  print(
    '✅ App inicializada - Los cortes se ejecutan automáticamente desde Google Apps Script',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => PermissionHandler()),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeManager>(context);

    // ✅ CONFIGURACIÓN OPTIMIZADA PARA PANTALLA GRANDE (6.67")
    return ScreenUtilInit(
      designSize: const Size(
        412,
        915,
      ), // ✅ Tamaño típico de pantallas grandes Android
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          key: ValueKey(
            themeProvider.accentColor.value,
          ), // ✅ Fuerza reconstrucción al cambiar color
          debugShowCheckedModeBanner: false,
          title: 'Administración de Gastos',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: FutureBuilder<bool>(
            future: _checkOnboardingStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3.w, // ✅ Ancho responsivo
                    ),
                  ),
                );
              }
              final onboardingComplete = snapshot.data ?? false;
              return onboardingComplete
                  ? const LoadingScreen()
                  : const OnboardingScreen();
            },
          ),
        );
      },
    );
  }
}
