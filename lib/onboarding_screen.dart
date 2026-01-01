import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notificaciones/local_notifications.dart';
import 'package:notificaciones/loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _notificationsActivated = false;

  Future<void> _onIntroEnd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (_nameController.text.trim().isNotEmpty) {
      await prefs.setString('username', _nameController.text.trim());
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoadingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // Estilos mejorados usando Google Fonts
    final titleStyle = GoogleFonts.lato(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final bodyStyle = GoogleFonts.openSans(fontSize: 16, color: Colors.black87);

    final pageDecoration = PageDecoration(
      titleTextStyle: titleStyle,
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      imagePadding: const EdgeInsets.all(24),
      boxDecoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade200],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      pages: [
        // Página de bienvenida con ingreso de nombre (integrada)
        PageViewModel(
          title: "Bienvenido a Administración de Gastos",
          bodyWidget: Column(
            children: [
              Text(
                "Descubre cómo gestionar tus finanzas de manera sencilla y eficiente.",
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              Text(
                "Para personalizar tu experiencia, ingresa tu nombre:",
                style: bodyStyle.copyWith(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _nameController,
                  style: GoogleFonts.openSans(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Tu nombre',
                    hintStyle: GoogleFonts.openSans(color: Colors.grey),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          image: Center(
            child: Image.asset('assets/icons/cochinito.png', height: 175),
          ),
          decoration: pageDecoration,
        ),
        // Página de permisos de notificaciones
        PageViewModel(
          title: "Permisos de Notificaciones",
          body:
              "Para mantenerte informado, necesitamos activar las notificaciones.",
          image: Center(
            child: Icon(
              Icons.notifications_active,
              size: 175,
              color: Theme.of(context).primaryColor,
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 8.0,
            ),
            child:
                _notificationsActivated
                    ? ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        "Notificaciones activadas",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        await LocalNotifications.requestNotificationPermission();
                        await LocalNotifications.requestAlarmExactPermission();
                        await LocalNotifications.scheduleDailyTenAMNotification();
                        await LocalNotifications.scheduleDailyThreePMNotification();
                        await LocalNotifications.scheduleDailyNinePMNotification();
                        setState(() {
                          _notificationsActivated = true;
                        });
                      },
                      child: const Text(
                        "Activar Notificaciones",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
          ),
          decoration: pageDecoration,
        ),
      ],
      // Modificar onDone para hacerlo obligatorio
      onDone: () {
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Por favor ingresa tu nombre para continuar."),
            ),
          );
          return;
        }
        _onIntroEnd();
      },
      showSkipButton: true,
      skip: Text(
        "Omitir",
        style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
      ),
      next: const Icon(Icons.arrow_forward),
      done: Text(
        "Empezar",
        style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Colors.black26,
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}
