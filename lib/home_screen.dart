import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notificaciones/ajustes_screen.dart';
import 'package:notificaciones/categorias_screen.dart';
import 'package:notificaciones/cuentas_screen.dart';
import 'package:notificaciones/dynamic_form_screen.dart';
import 'package:notificaciones/graficas_screen.dart';
import 'package:notificaciones/metas_screen.dart';
import 'package:notificaciones/new_dashboard_screen.dart';
import 'package:notificaciones/notificaciones_screen.dart';
import 'package:notificaciones/reportes_screen.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:notificaciones/transacciones_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'dart:async';
import 'services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String _tutorialKey = 'tutorial_home_shown';
  static const String _userNameKey = 'username';
  static final double _fabDistance = 60.h;

  int _selectedIndex = 0;
  bool _isScrollingDown = false;
  String _userName = '';
  int _cantidadMetas = 0;
  StreamSubscription? _metasSubscription;

  late TutorialCoachMark _tutorialCoachMark;
  final List<TargetFocus> _targets = [];

  final GlobalKey<NewDashboardScreenState> _dashboardKey = GlobalKey();
  final GlobalKey<TransaccionesScreenState> _transaccionesKey = GlobalKey();
  final GlobalKey<GraficasScreenState> _graficasKey = GlobalKey();
  final GlobalKey<ReportesScreenState> _reportesKey = GlobalKey();
  final _expandableFabKey = GlobalKey<ExpandableFabState>(); // ✅ CORRECCIÓN
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
    _maybeShowTutorial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _metasSubscription?.cancel();
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

  void _promptUserName() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 25.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 18.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.waving_hand_rounded,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Personaliza tu experiencia',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ingresa tu nombre',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Container(
                        margin: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF667eea),
                          width: 2.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    width: double.infinity,
                    height: 50.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 10.r,
                          offset: Offset(0, 5.h),
                        ),
                      ],
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
                        borderRadius: BorderRadius.circular(14.r),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Comenzar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18.sp,
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
          ),
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
    final themeManager = Provider.of<ThemeManager>(context);

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
            MaterialPageRoute(builder: (context) => const CategoriasScreen()),
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
            MaterialPageRoute(builder: (context) => const MetasScreen()),
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

    return Drawer(
      width: 280.w,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          gradient:
              themeManager.isDarkMode
                  ? LinearGradient(
                    colors: [Colors.grey.shade900, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                  : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF5F7FA)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 28.h),
              decoration: BoxDecoration(
                gradient:
                    themeManager.isDarkMode
                        ? LinearGradient(
                          colors: [Colors.grey.shade800, Colors.grey.shade900],
                        )
                        : const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26.r),
                  bottomRight: Radius.circular(26.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        themeManager.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 18.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.4),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/icons/cochinito.png',
                        height: 44.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Hola, $_userName',
                    style: TextStyle(
                      color: Colors.white,
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Text(
                      'Administrador',
                      style: TextStyle(
                        color: Colors.white,
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
                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color:
                          themeManager.isDarkMode
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              themeManager.isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
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
                                  gradient: LinearGradient(
                                    colors: [
                                      item.color,
                                      item.color.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            themeManager.isDarkMode
                                                ? Colors.white
                                                : const Color(0xFF2D3436),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      item.subtitle,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color:
                                            themeManager.isDarkMode
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
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
                                  color:
                                      themeManager.isDarkMode
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                  size: 18.sp,
                                ),
                            ],
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
                  Divider(
                    color:
                        themeManager.isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14.sp,
                        color:
                            themeManager.isDarkMode
                                ? Colors.grey.shade600
                                : Colors.grey.shade500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Versión 1.0.0',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color:
                              themeManager.isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade500,
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

  // ✅ MÉTODO MEJORADO: Botones sin brillo
  Widget _buildFloatingActionButtonExtended(
    IconData icon,
    String label,
    Color baseColor,
  ) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final buttonColor =
        themeManager.isDarkMode
            ? Color.lerp(Colors.black, baseColor, 0.6)!
            : baseColor;

    return SizedBox(
      width: 150.w,
      height: 48.h,
      child: FloatingActionButton.extended(
        heroTag: label,
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.5.sp,
          ),
        ),
        icon: Icon(icon, color: Colors.white, size: 17.sp),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        onPressed: () {
          _expandableFabKey.currentState?.toggle();
          _navigateToDynamicFormScreen(label, buttonColor);
        },
        backgroundColor: buttonColor,
        elevation: 4,
        tooltip: label,
      ),
    );
  }

  Widget _buildExpandableFab() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    return ExpandableFab(
      key: _expandableFabKey,
      distance: _fabDistance,
      type: ExpandableFabType.up,
      overlayStyle: ExpandableFabOverlayStyle(
        color: Colors.black.withOpacity(0.75),
        blur: 10,
      ),
      childrenAnimation: ExpandableFabAnimation.none,
      fanAngle: 70,
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(Icons.add_rounded, color: Colors.white),
        shape: const CircleBorder(),
        backgroundColor:
            themeManager.isDarkMode
                ? Colors.grey.shade800
                : const Color(0xFF667eea),
      ),
      closeButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(Icons.close_rounded, color: Colors.white),
        shape: const CircleBorder(),
        backgroundColor:
            themeManager.isDarkMode
                ? Colors.grey.shade800
                : const Color(0xFF667eea),
      ),
      children: [
        _buildFloatingActionButtonExtended(
          Icons.trending_down_rounded,
          "Gastos",
          Colors.red,
        ),
        _buildFloatingActionButtonExtended(
          Icons.trending_up_rounded,
          "Ingresos",
          Colors.green,
        ),
        _buildFloatingActionButtonExtended(
          Icons.swap_horiz_rounded,
          "Traspasos",
          Colors.blue,
        ),
        _buildFloatingActionButtonExtended(
          Icons.monetization_on_rounded,
          "Pagos",
          Colors.orange,
        ),
        _buildFloatingActionButtonExtended(
          Icons.restore_rounded,
          "Reembolsos",
          Colors.purple,
        ),
      ],
    );
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
        leading: Container(
          margin: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color:
                themeManager.isDarkMode
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: IconButton(
            key: _drawerButtonKey,
            icon: Icon(
              Icons.menu_rounded,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
              size: 18.sp,
            ),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        title: Column(
          children: [
            Text(
              _getTimeGreeting(),
              style: TextStyle(
                color:
                    themeManager.isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _userName.isEmpty ? "Usuario" : _userName,
              style: TextStyle(
                color: themeManager.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color:
                  themeManager.isDarkMode
                      ? Colors.grey.shade800.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: IconButton(
              key: _themeButtonKey,
              icon: Icon(
                themeManager.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: themeManager.isDarkMode ? Colors.white : Colors.black87,
                size: 18.sp,
              ),
              onPressed: () => themeManager.toggleTheme(),
            ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22.r),
            topRight: Radius.circular(22.r),
          ),
          child: BottomNavigationBar(
            backgroundColor:
                themeManager.isDarkMode ? Colors.grey.shade900 : Colors.white,
            elevation: 0,
            items: [
              _buildNavItem(
                Icons.home_rounded,
                Icons.home_outlined,
                'Inicio',
                0,
              ),
              _buildNavItem(
                Icons.swap_horiz_rounded,
                Icons.swap_horiz_outlined,
                'Transacciones',
                1,
              ),
              _buildNavItem(
                Icons.bar_chart_rounded,
                Icons.bar_chart_outlined,
                'Gráficas',
                2,
              ),
              _buildNavItem(
                Icons.description_rounded,
                Icons.description_outlined,
                'Reportes',
                3,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF667eea),
            unselectedItemColor:
                themeManager.isDarkMode
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 10.sp,
            unselectedFontSize: 9.sp,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: _onItemTapped,
          ),
        ),
      ),
      floatingActionButton: _buildExpandableFab(),
      floatingActionButtonLocation: ExpandableFab.location,
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    int index,
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

    return BottomNavigationBarItem(
      key: key,
      icon: Icon(
        _selectedIndex == index ? selectedIcon : unselectedIcon,
        size: 20.sp,
      ),
      label: label,
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
