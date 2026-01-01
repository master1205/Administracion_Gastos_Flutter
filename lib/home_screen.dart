import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:notificaciones/dynamic_form_screen.dart';
import 'package:notificaciones/graficas_screen.dart';
import 'package:notificaciones/new_dashboard_screen.dart';
import 'package:notificaciones/reportes_screen.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:notificaciones/transacciones_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isScrollingDown = false;
  String _userName = '';

  // Variables para el tutorial
  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  final GlobalKey<NewDashboardScreenState> _dashboardKey =
      GlobalKey<NewDashboardScreenState>();
  final GlobalKey<TransaccionesScreenState> _transaccionesKey =
      GlobalKey<TransaccionesScreenState>();
  final GlobalKey<GraficasScreenState> _graficasKey =
      GlobalKey<GraficasScreenState>();
  final GlobalKey<ReportesScreenState> _reportesKey =
      GlobalKey<ReportesScreenState>();

  late final List<Widget> _widgetOptions;

  final GlobalKey<ExpandableFabState> _expandableFabKey =
      GlobalKey<ExpandableFabState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final GlobalKey _navItemInicioKey = GlobalKey();
  final GlobalKey _navItemTransaccionesKey = GlobalKey();
  final GlobalKey _navItemGraficasKey = GlobalKey();
  final GlobalKey _navItemReportesKey = GlobalKey();
  final GlobalKey _drawerButtonKey = GlobalKey();
  final GlobalKey _themeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetOptions = [
      NewDashboardScreen(key: _dashboardKey, onTabChange: _onItemTapped),
      TransaccionesScreen(key: _transaccionesKey),
      GraficasScreen(key: _graficasKey),
      ReportesScreen(key: _reportesKey),
    ];
    _checkUserName();
    showTutorial();
  }

  Future<void> showTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('tutorial_home_shown') ?? false)) {
      createTutorial();
      tutorialCoachMark.show(context: context);
    }
  }

  Future<void> createTutorial() async {
    _initHomeTutorialTargets();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.red,
      textSkip: "Omitir",
      paddingFocus: 10,
      opacityShadow: 0.5,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () async {
        await (await SharedPreferences.getInstance()).setBool(
          'tutorial_home_shown',
          true,
        );
      },
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('tutorial_home_shown', true);
        });
        return true;
      },
    );
  }

  void _initHomeTutorialTargets() {
    targets.clear();

    // Target para el botón del Drawer
    targets.add(
      TargetFocus(
        identify: "DrawerButton",
        keyTarget: _drawerButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Abre el menú para acceder a más opciones de la aplicación.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target para el botón de cambiar el tema
    targets.add(
      TargetFocus(
        identify: "ThemeButton",
        keyTarget: _themeButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Cambia el tema de la aplicación aquí.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target para el ítem "Inicio"
    targets.add(
      TargetFocus(
        identify: "NavItemInicio",
        keyTarget: _navItemInicioKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Inicio: resumen de balance y cuentas.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target para el ítem "Transacciones"
    targets.add(
      TargetFocus(
        identify: "NavItemTransacciones",
        keyTarget: _navItemTransaccionesKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.pink, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Transacciones: revisa, edita o elimina movimientos.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target para el ítem "Gráficas"
    targets.add(
      TargetFocus(
        identify: "NavItemGraficas",
        keyTarget: _navItemGraficasKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Gráficas: visualiza estadísticas de tus gastos.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target para el ítem "Reportes"
    targets.add(
      TargetFocus(
        identify: "NavItemReportes",
        keyTarget: _navItemReportesKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Reportes: consulta informes detallados de tus gastos.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedName = prefs.getString('username');
    if (storedName == null || storedName.isEmpty) {
      _promptUserName();
    } else {
      setState(() {
        _userName = storedName;
      });
    }
  }

  void _promptUserName() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Bienvenido',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Ingresa tu nombre',
              prefixIcon: const Icon(Icons.person),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  final name = controller.text.trim();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('username', name);
                  setState(() {
                    _userName = name;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Guardar',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Muestra carga por 500 ms al volver de segundo plano
      setState(() => _isScrollingDown = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isScrollingDown = false);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToDynamicFormScreen(String type, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TrasaccionScreen(transactionType: type, color: color),
      ),
    ).then((_) {
      // Actualizar la pantalla actual cuando se regrese a HomeScreen
      if (_selectedIndex == 0) {
        _dashboardKey.currentState?.refreshData();
      } else if (_selectedIndex == 1) {
        _transaccionesKey.currentState?.refreshData();
      } else if (_selectedIndex == 2) {
        _graficasKey.currentState?.refreshData();
      }
    });
  }

  // Drawer con header moderno (gradiente) y Cards estilizadas para navegación
  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context);
    return Drawer(
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          // Header con gradiente y logo
          Container(
            width: double.infinity,
            height: 190,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient:
                  themeManager.isDarkMode
                      ? LinearGradient(
                        colors: [Colors.grey.shade800, Colors.black87],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : const LinearGradient(
                        colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Asegúrate de tener la imagen en assets y declararla en pubspec.yaml
                Image.asset('assets/icons/cochinito.png', height: 80),
                const SizedBox(height: 8),
                const Text(
                  'Administración de Gastos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Cards para navegación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.category,
                      color:
                          themeManager.isDarkMode
                              ? Colors.white
                              : theme.primaryColor,
                    ),
                    title: const Text(
                      "Categorías",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      // Acción para Categorías
                    },
                  ),
                ),
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.account_balance,
                      color:
                          themeManager.isDarkMode
                              ? Colors.white
                              : theme.primaryColor,
                    ),
                    title: const Text(
                      "Cuentas",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      // Acción para Cuentas
                    },
                  ),
                ),
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color:
                          themeManager.isDarkMode
                              ? Colors.white
                              : theme.primaryColor,
                    ),
                    title: const Text(
                      "Notificaciones",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      // Acción para Notificaciones
                    },
                  ),
                ),
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.settings,
                      color:
                          themeManager.isDarkMode
                              ? Colors.white
                              : theme.primaryColor,
                    ),
                    title: const Text(
                      "Ajustes",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      // Acción para Ajustes
                    },
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('v1.0.0', style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'buenos días';
    } else if (hour >= 12 && hour < 19) {
      return 'buenas tardes';
    } else {
      return 'buenas noches';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          key: _drawerButtonKey,
          icon: Icon(
            Icons.person_3_outlined,
            size: 22,
            color: themeManager.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Hola ${_userName.isEmpty ? "Usuario" : _userName}, ${_getTimeGreeting()}',
          style: TextStyle(
            color: themeManager.isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            key: _themeButtonKey,
            icon: Icon(
              themeManager.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: themeManager.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => themeManager.toggleTheme(),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse &&
              !_isScrollingDown) {
            setState(() {
              _isScrollingDown = true;
            });
          } else if (notification.direction == ScrollDirection.forward &&
              _isScrollingDown) {
            setState(() {
              _isScrollingDown = false;
            });
          }
          return true;
        },
        child: Stack(
          children: [Center(child: _widgetOptions.elementAt(_selectedIndex))],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            key: _navItemInicioKey,
            icon: const Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            key: _navItemTransaccionesKey,
            icon: const Icon(Icons.swap_horiz),
            label: 'Transacciones',
          ),
          BottomNavigationBarItem(
            key: _navItemGraficasKey,
            icon: const Icon(Icons.bar_chart),
            label: 'Gráficas',
          ),
          BottomNavigationBarItem(
            key: _navItemReportesKey,
            icon: const Icon(Icons.description),
            label: 'Reportes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      floatingActionButton:
          _isScrollingDown
              ? null
              : ExpandableFab(
                key: _expandableFabKey,
                distance: 70.0,
                type: ExpandableFabType.up,
                overlayStyle: ExpandableFabOverlayStyle(
                  color: Colors.black.withOpacity(0.5),
                  blur: 5,
                ),
                openButtonBuilder: RotateFloatingActionButtonBuilder(
                  child: Icon(Icons.add, color: Colors.white),
                  shape: const CircleBorder(),
                  backgroundColor:
                      themeManager.isDarkMode
                          ? Colors.blueGrey.shade800
                          : Colors.blue,
                ),
                closeButtonBuilder: RotateFloatingActionButtonBuilder(
                  backgroundColor:
                      themeManager.isDarkMode
                          ? Colors.blueGrey.shade800
                          : Colors.blue,
                  child: Icon(Icons.close, color: Colors.white),
                  shape: const CircleBorder(),
                ),
                children: [
                  _buildFloatingActionButtonExtended(
                    Icons.money_off,
                    "Gastos",
                    Colors.red,
                  ),
                  _buildFloatingActionButtonExtended(
                    Icons.attach_money,
                    "Ingresos",
                    Colors.green,
                  ),
                  _buildFloatingActionButtonExtended(
                    Icons.compare_arrows,
                    "Traspasos",
                    Colors.blue,
                  ),
                  _buildFloatingActionButtonExtended(
                    Icons.payment,
                    "Pagos",
                    Colors.orange,
                  ),
                  _buildFloatingActionButtonExtended(
                    Icons.undo,
                    "Reembolsos",
                    Colors.purple,
                  ),
                ],
              ),
      floatingActionButtonLocation: ExpandableFab.location,
    );
  }

  Widget _buildFloatingActionButtonExtended(
    IconData icon,
    String label,
    Color baseColor,
  ) {
    final themeManager = Provider.of<ThemeManager>(context);
    final Color buttonColor =
        themeManager.isDarkMode
            ? Color.lerp(Colors.black, baseColor, 0.4)!
            : baseColor;

    return SizedBox(
      width: 130,
      height: 50,
      child: FloatingActionButton.extended(
        heroTag: label,
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: () {
          _expandableFabKey.currentState?.toggle();
          _navigateToDynamicFormScreen(label, buttonColor);
        },
        backgroundColor: buttonColor,
        tooltip: label,
      ),
    );
  }
}
