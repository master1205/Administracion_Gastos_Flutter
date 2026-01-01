import 'package:flutter/material.dart';
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
    // Si no existe la clave, asumimos que es la primera vez (onboarding no completado)
    return prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    validarUnicode();
    final themeProvider = Provider.of<ThemeManager>(context);
    return MaterialApp(
      title: 'Administración de Gastos',
      theme: themeProvider.themeData,
      home: FutureBuilder<bool>(
        future: _checkOnboardingStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final onboardingComplete = snapshot.data ?? false;
          // Si ya completó el onboarding mostramos LoadingScreen, de lo contrario OnboardingScreen.
          return onboardingComplete
              ? const LoadingScreen()
              : const OnboardingScreen();
        },
      ),
    );
  }

  void validarUnicode() {
    print(Icons.restaurant_outlined.codePoint);
  }
}
