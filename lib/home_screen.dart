import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notificaciones/ajustes_screen.dart';
import 'package:notificaciones/categorias_screen.dart';
import 'package:notificaciones/cuentas_screen.dart';
import 'package:notificaciones/dynamic_form_screen.dart';
import 'package:notificaciones/graficas_screen.dart';
import 'package:notificaciones/metas_screen.dart';
import 'package:notificaciones/new_dashboard_screen.dart';
import 'package:notificaciones/notificaciones_screen.dart';
import 'package:notificaciones/budgets_screen.dart';
import 'package:notificaciones/apartados_screen.dart';
import 'package:notificaciones/reportes_screen.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:notificaciones/transacciones_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'dart:async';
import 'services/firestore_service.dart';
import 'widgets/animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String _tutorialKey = 'tutorial_home_shown';
  static const String _userNameKey = 'username';

  int _selectedIndex = 0;
  bool _isScrollingDown = false;
  String _userName = '';
  int _cantidadMetas = 0;
  int _cantidadPresupuestos = 0;
  int _cantidadApartados = 0;
  StreamSubscription? _metasSubscription;
  StreamSubscription? _presupuestosSubscription;
  StreamSubscription? _apartadosSubscription;

  late TutorialCoachMark _tutorialCoachMark;
  final List<TargetFocus> _targets = [];

  final GlobalKey<NewDashboardScreenState> _dashboardKey = GlobalKey();
  final GlobalKey<TransaccionesScreenState> _transaccionesKey = GlobalKey();
  final GlobalKey<GraficasScreenState> _graficasKey = GlobalKey();
  final GlobalKey<ReportesScreenState> _reportesKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  final GlobalKey _navItemInicioKey = GlobalKey();
  final GlobalKey _navItemTransaccionesKey = GlobalKey();
  final GlobalKey _navItemGraficasKey = GlobalKey();
  final GlobalKey _navItemReportesKey = GlobalKey();
  final GlobalKey _drawerButtonKey = GlobalKey();
  final GlobalKey _themeButtonKey = GlobalKey();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWidgets();
    _checkUserName();
    _cargarCantidadMetas();
    _cargarCantidadPresupuestos();
    _cargarCantidadApartados();
    _maybeShowTutorial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _metasSubscription?.cancel();
    _presupuestosSubscription?.cancel();
    _apartadosSubscription?.cancel();
    super.dispose();
  }

  void _initializeWidgets() {
    _widgetOptions = [
      NewDashboardScreen(key: _dashboardKey, onTabChange: _onItemTapped),
      TransaccionesScreen(key: _transaccionesKey),
      GraficasScreen(key: _graficasKey),
      ReportesScreen(key: _reportesKey),
    ];
  }

  Future<void> _checkUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString(_userNameKey);

    if (storedName == null || storedName.isEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _promptUserName();
      });
    } else {
      setState(() => _userName = storedName);
    }
  }

  void _cargarCantidadMetas() {
    final firestoreService = FirestoreService();
    _metasSubscription = firestoreService.obtenerMetas().listen((metas) {
      if (mounted) {
        setState(() {
          _cantidadMetas = metas.length;
        });
      }
    });
  }

  void _cargarCantidadPresupuestos() {
    final firestoreService = FirestoreService();
    _presupuestosSubscription = firestoreService
        .obtenerPresupuestosActivos()
        .listen((presupuestos) {
          if (mounted) {
            setState(() {
              _cantidadPresupuestos = presupuestos.length;
            });
          }
        });
  }

  void _cargarCantidadApartados() {
    final firestoreService = FirestoreService();
    _apartadosSubscription = firestoreService.obtenerApartadosActivos().listen((
      apartados,
    ) {
      if (mounted) {
        setState(() {
          _cantidadApartados = apartados.length;
        });
      }
    });
  }

  void _promptUserName() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(0.15),
                  ),
                  child: Icon(
                    Icons.waving_hand_rounded,
                    size: 36.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Personaliza tu experiencia',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu nombre',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.secondary.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.primary,
                        size: 18.sp,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.secondary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2.w,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        if (controller.text.trim().isNotEmpty) {
                          final name = controller.text.trim();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(_userNameKey, name);
                          setState(() => _userName = name);
                          if (mounted) Navigator.of(context).pop();
                        }
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Comenzar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _maybeShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_tutorialKey) ?? false)) {
      _createTutorial();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _tutorialCoachMark.show(context: context);
      });
    }
  }

  void _createTutorial() {
    _initTutorialTargets();
    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black,
      textSkip: "",
      paddingFocus: 10,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_tutorialKey, true);
      },
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool(_tutorialKey, true);
        });
        return true;
      },
    );
  }

  void _initTutorialTargets() {
    _targets.clear();
    _targets.addAll([
      _createDrawerTarget(),
      _createThemeTarget(),
      _createNavInicioTarget(),
      _createNavTransaccionesTarget(),
      _createNavGraficasTarget(),
      _createNavReportesTarget(),
    ]);
  }

  TargetFocus _createDrawerTarget() {
    return TargetFocus(
      identify: "DrawerButton",
      keyTarget: _drawerButtonKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.Circle,
      radius: 10,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "👤 Menú Principal",
                description:
                    "Accede a tu perfil, categorías, cuentas y ajustes.",
                icon: Icons.menu_rounded,
                gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                currentStep: 1,
                totalSteps: 6,
                onNext: controller.next,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createThemeTarget() {
    return TargetFocus(
      identify: "ThemeButton",
      keyTarget: _themeButtonKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.Circle,
      radius: 10,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "🌓 Cambiar Tema",
                description: "Alterna entre modo claro y oscuro.",
                icon: Icons.brightness_6_rounded,
                gradientColors: const [Color(0xFFf093fb), Color(0xFFF5576c)],
                currentStep: 2,
                totalSteps: 6,
                onNext: controller.next,
                onBack: controller.previous,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createNavInicioTarget() {
    return TargetFocus(
      identify: "NavItemInicio",
      keyTarget: _navItemInicioKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 15,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "🏠 Inicio",
                description: "Resumen de balance, cuentas y transacciones.",
                icon: Icons.home_rounded,
                gradientColors: const [Color(0xFFfa709a), Color(0xFFfee140)],
                currentStep: 3,
                totalSteps: 6,
                onNext: controller.next,
                onBack: controller.previous,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createNavTransaccionesTarget() {
    return TargetFocus(
      identify: "NavItemTransacciones",
      keyTarget: _navItemTransaccionesKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 15,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "💸 Transacciones",
                description: "Consulta, edita o elimina tus movimientos.",
                icon: Icons.swap_horiz_rounded,
                gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                currentStep: 4,
                totalSteps: 6,
                onNext: controller.next,
                onBack: controller.previous,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createNavGraficasTarget() {
    return TargetFocus(
      identify: "NavItemGraficas",
      keyTarget: _navItemGraficasKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 15,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "📊 Gráficas",
                description: "Visualiza tus gastos con gráficos interactivos.",
                icon: Icons.bar_chart_rounded,
                gradientColors: const [Color(0xFF30cfd0), Color(0xFF330867)],
                currentStep: 5,
                totalSteps: 6,
                onNext: controller.next,
                onBack: controller.previous,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createNavReportesTarget() {
    return TargetFocus(
      identify: "NavItemReportes",
      keyTarget: _navItemReportesKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 15,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "📋 Reportes",
                description: "Genera informes y exporta tus datos.",
                icon: Icons.description_rounded,
                gradientColors: const [Color(0xFFa8edea), Color(0xFFfed6e3)],
                currentStep: 6,
                totalSteps: 6,
                onNext: controller.next,
                onBack: controller.previous,
                isLastStep: true,
              ),
        ),
      ],
    );
  }

  Widget _buildModernTutorialCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required int currentStep,
    required int totalSteps,
    VoidCallback? onNext,
    VoidCallback? onBack,
    VoidCallback? onSkip,
    bool isLastStep = false,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: 280.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 26.sp, color: Colors.white),
                ),
                SizedBox(height: 8.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.3,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
                _buildProgressIndicator(
                  currentStep,
                  totalSteps,
                  gradientColors,
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isLastStep && onSkip != null)
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          minimumSize: Size(50.w, 32.h),
                        ),
                        child: Text(
                          'Omitir',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        if (onBack != null)
                          Container(
                            margin: EdgeInsets.only(right: 6.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onBack,
                              icon: Icon(Icons.arrow_back_rounded, size: 16.sp),
                              color: Colors.grey.shade700,
                              padding: EdgeInsets.all(6.r),
                              constraints: BoxConstraints(
                                minWidth: 30.w,
                                minHeight: 30.h,
                              ),
                            ),
                          ),
                        if (onNext != null)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors.first.withOpacity(0.4),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 3.h),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onNext,
                                borderRadius: BorderRadius.circular(18.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isLastStep
                                            ? '¡Entendido!'
                                            : 'Siguiente',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        isLastStep
                                            ? Icons.check_rounded
                                            : Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 14.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    int currentStep,
    int totalSteps,
    List<Color> gradientColors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: isCurrent ? 20.w : 5.w,
          height: 5.h,
          decoration: BoxDecoration(
            gradient:
                isActive || isCurrent
                    ? LinearGradient(colors: gradientColors)
                    : null,
            color: !isActive && !isCurrent ? Colors.grey.shade300 : null,
            borderRadius: BorderRadius.circular(2.5.r),
          ),
        );
      }),
    );
  }

  Widget _buildDrawer() {
    final menuItems = [
      _DrawerItem(
        icon: Icons.category_rounded,
        title: "Categorías",
        subtitle: "Organiza tus gastos",
        color: const Color(0xFF667eea),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      const CategoriasScreen(headerColor: Color(0xFF667eea)),
            ),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.account_balance_rounded,
        title: "Cuentas",
        subtitle: "Administra tus cuentas",
        color: const Color(0xFF4facfe),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CuentasScreen()),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.savings_outlined,
        title: "Metas de Ahorro",
        subtitle: "Alcanza tus objetivos",
        color: const Color(0xFF4CAF50),
        badge: _cantidadMetas > 0 ? _cantidadMetas.toString() : null,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      const MetasScreen(headerColor: Color(0xFF4CAF50)),
            ),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.account_balance_wallet_rounded,
        title: "Presupuestos",
        subtitle: "Controla tus gastos",
        color: const Color(0xFFFF9800),
        badge:
            _cantidadPresupuestos > 0 ? _cantidadPresupuestos.toString() : null,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetScreen()),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.event_note_rounded,
        title: "Apartados",
        subtitle: "Reserva para gastos planeados",
        color: const Color(0xFF2196F3),
        badge: _cantidadApartados > 0 ? _cantidadApartados.toString() : null,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApartadosScreen()),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.notifications_rounded,
        title: "Notificaciones",
        subtitle: "Mantente informado",
        color: const Color(0xFFf093fb),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificacionesScreen(),
            ),
          );
        },
      ),
      _DrawerItem(
        icon: Icons.settings_rounded,
        title: "Ajustes",
        subtitle: "Configura tu app",
        color: const Color(0xFF30cfd0),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AjustesScreen()),
          );
        },
      ),
    ];

    final theme = Theme.of(context);

    return Drawer(
      width: 280.w,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        color: theme.colorScheme.background,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 28.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26.r),
                  bottomRight: Radius.circular(26.r),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/icons/cochinito.png',
                      height: 44.h,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Hola, $_userName',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Administrador',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return FadeIn(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: theme.colorScheme.secondary.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: item.onTap,
                          borderRadius: BorderRadius.circular(14.r),
                          child: Padding(
                            padding: EdgeInsets.all(14.r),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: item.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        item.subtitle,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: theme.colorScheme.secondary
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.badge != null)
                                  Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.5),
                                    size: 18.sp,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(18.r),
              child: Column(
                children: [
                  Divider(color: theme.colorScheme.secondary.withOpacity(0.2)),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14.sp,
                        color: theme.colorScheme.secondary.withOpacity(0.6),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Versión 1.0.0',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.secondary.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _navigateToDynamicFormScreen(String type, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TrasaccionScreen(transactionType: type, color: color),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No hacemos nada - el FAB permanece siempre visible
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Buenos días';
    if (hour >= 12 && hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _showTransactionOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: theme.colorScheme.primary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Nueva Transacción',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      _buildTransactionOption(
                        icon: Icons.trending_down_rounded,
                        title: 'Gastos',
                        description: 'Registra un gasto o compra',
                        color: Colors.red,
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDynamicFormScreen('Gastos', Colors.red);
                        },
                      ),
                      SizedBox(height: 12.h),
                      _buildTransactionOption(
                        icon: Icons.trending_up_rounded,
                        title: 'Ingresos',
                        description: 'Registra un ingreso o ganancia',
                        color: Colors.green,
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDynamicFormScreen(
                            'Ingresos',
                            Colors.green,
                          );
                        },
                      ),
                      SizedBox(height: 12.h),
                      _buildTransactionOption(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Traspasos',
                        description: 'Transfiere entre cuentas',
                        color: Colors.blue,
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDynamicFormScreen(
                            'Traspasos',
                            Colors.blue,
                          );
                        },
                      ),
                      SizedBox(height: 12.h),
                      _buildTransactionOption(
                        icon: Icons.monetization_on_rounded,
                        title: 'Pagos',
                        description: 'Registra un pago realizado',
                        color: Colors.orange,
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDynamicFormScreen('Pagos', Colors.orange);
                        },
                      ),
                      SizedBox(height: 12.h),
                      _buildTransactionOption(
                        icon: Icons.restore_rounded,
                        title: 'Reembolsos',
                        description: 'Registra un reembolso recibido',
                        color: Colors.purple,
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDynamicFormScreen(
                            'Reembolsos',
                            Colors.purple,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
    );
  }

  Widget _buildTransactionOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.secondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.secondary.withOpacity(0.5),
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          key: _drawerButtonKey,
          icon: Icon(
            Icons.menu_rounded,
            color: theme.colorScheme.onSurface,
            size: 22.sp,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          children: [
            Text(
              _getTimeGreeting(),
              style: TextStyle(
                color: theme.colorScheme.secondary.withOpacity(0.7),
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _userName.isEmpty ? "Usuario" : _userName,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: _themeButtonKey,
            icon: Icon(
              themeManager.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: theme.colorScheme.onSurface,
              size: 22.sp,
            ),
            onPressed: () => themeManager.toggleTheme(),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.background,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final isScrollingDown =
              notification.direction == ScrollDirection.reverse;
          if (isScrollingDown != _isScrollingDown) {
            setState(() => _isScrollingDown = isScrollingDown);
          }
          return true;
        },
        child: Center(child: _widgetOptions[_selectedIndex]),
      ),
      bottomNavigationBar: BottomAppBar(
        color: theme.colorScheme.surface,
        elevation: 0,
        height: 60.h,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(
              Icons.home_rounded,
              Icons.home_outlined,
              'Inicio',
              0,
              theme,
            ),
            _buildNavButton(
              Icons.swap_horiz_rounded,
              Icons.swap_horiz_outlined,
              'Transacciones',
              1,
              theme,
            ),
            SizedBox(width: 56.w), // Espacio para el FAB en el centro
            _buildNavButton(
              Icons.bar_chart_rounded,
              Icons.bar_chart_outlined,
              'Gráficas',
              2,
              theme,
            ),
            _buildNavButton(
              Icons.description_rounded,
              Icons.description_outlined,
              'Reportes',
              3,
              theme,
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showTransactionOptions,
            customBorder: const CircleBorder(),
            splashColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                color: theme.colorScheme.primary,
                size: 24.sp,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavButton(
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    int index,
    ThemeData theme,
  ) {
    GlobalKey? key;
    switch (index) {
      case 0:
        key = _navItemInicioKey;
        break;
      case 1:
        key = _navItemTransaccionesKey;
        break;
      case 2:
        key = _navItemGraficasKey;
        break;
      case 3:
        key = _navItemReportesKey;
        break;
    }

    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Material(
        key: key,
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 70.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  size: 22.sp,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary.withOpacity(0.5),
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });
}
