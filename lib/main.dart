import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ AGREGADO
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/firebase_options.dart';
import 'package:notificaciones/loading_screen.dart';
import 'package:notificaciones/local_notifications.dart';
import 'package:notificaciones/onboarding_screen.dart';
import 'package:notificaciones/permission_handler.dart';
import 'package:notificaciones/services/cortes_service.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Habilitar cache offline de Firebase
  // Reduce lecturas en ~70% y mejora rendimiento
  // NO afecta notificaciones en tiempo real de Streams activos
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Cache automático offline
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Sin límite de cache
  );

  await LocalNotifications.initialize();

  // ✅ Programar cortes automáticos solo si el dispositivo está configurado como maestro
  final prefs = await SharedPreferences.getInstance();
  final corteSemanalActivo = prefs.getBool('corte_semanal_automatico') ?? false;
  final corteMensualActivo = prefs.getBool('corte_mensual_automatico') ?? false;

  if (corteSemanalActivo) {
    await CortesService.programarCorteSemanal(); // Domingos 1 AM
    print('✅ Dispositivo maestro: Corte semanal programado');
  }

  if (corteMensualActivo) {
    await CortesService.programarCorteMensual(); // 1º del mes 1 AM
    print('✅ Dispositivo maestro: Corte mensual programado');
  }

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
          debugShowCheckedModeBanner: false,
          title: 'Administración de Gastos',
          theme: themeProvider.themeData,
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
