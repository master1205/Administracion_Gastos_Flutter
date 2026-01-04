import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ AGREGADO
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/loading_screen.dart';
import 'package:notificaciones/local_notifications.dart';
import 'package:notificaciones/onboarding_screen.dart';
import 'package:notificaciones/permission_handler.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotifications.initialize();
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
