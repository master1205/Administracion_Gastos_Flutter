import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Meta.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/models/Budget.dart';
import 'package:notificaciones/models/Apartado.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'dart:async';
import 'utils/animation_utils.dart';
import 'componentes/empty_states.dart';
import 'componentes/heads_up_notification.dart';
import 'metas_screen.dart';
import 'transacciones_screen.dart';
import 'budgets_screen.dart';
import 'services/firestore_service.dart';
import 'widgets/budget_widgets.dart';
import 'presupuesto_detalle_screen.dart';
import 'meta_detalle_screen.dart';
import 'apartados_screen.dart';
import 'apartado_detalle_screen.dart';
import 'widgets/animated_card.dart';

class NewDashboardScreen extends StatefulWidget {
  final void Function(int)? onTabChange;
  const NewDashboardScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  NewDashboardScreenState createState() => NewDashboardScreenState();
}

class NewDashboardScreenState extends State<NewDashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Constants
  static const String _tutorialKey = 'tutorial_dashboard_shown';
  static const Duration _animationDuration = Duration(milliseconds: 800);
  static const int _maxRecentTransactions = 5;

  // Keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _balanceCardKey = GlobalKey();
  final GlobalKey _accountsCarouselKey = GlobalKey();
  final GlobalKey _verTodoKey = GlobalKey();

  // Formatters
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  // State
  List<Account> _accounts = [];
  Map<String, dynamic>? _balanceData;

  List<Transaction> _transactions = [];
  List<Meta> _metas = [];
  List<Budget> _presupuestos = [];
  List<Apartado> _apartados = [];
  bool _isLoading = false;
  bool _isManualRefresh = false;
  bool _metasExpanded = false;
  bool _presupuestosExpanded = false;
  bool _apartadosExpanded = false;
  bool _hasInitialData = false;

  // Firebase streams
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<Account>>? _cuentasSubscription;
  StreamSubscription<List<Transaction>>? _transaccionesSubscription;
  StreamSubscription<List<Meta>>? _metasSubscription;
  StreamSubscription<List<Budget>>? _presupuestosSubscription;
  StreamSubscription<List<Apartado>>? _apartadosSubscription;

  // Tutorial
  late TutorialCoachMark _tutorialCoachMark;
  final List<TargetFocus> _targets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reactivar streams cuando el widget vuelve a estar activo
    if (mounted && _hasInitialData) {
      _setupStreams();
    }
  }

  @override
  void dispose() {
    _cuentasSubscription?.cancel();
    _transaccionesSubscription?.cancel();
    _metasSubscription?.cancel();
    _presupuestosSubscription?.cancel();
    _apartadosSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Los Streams de Firebase se mantienen activos automáticamente
  }

  // Initialization
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      // Suscribirse a streams en tiempo real
      _setupStreams();
      await _maybeShowDashboardTutorial();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupStreams() {
    debugPrint('🔄 Configurando streams de Firebase...');
    final startTime = DateTime.now();
    final shouldShowProgress = _isManualRefresh;

    // Stream de cuentas
    _cuentasSubscription?.cancel();
    _cuentasSubscription = _firestoreService.obtenerCuentas().listen((
      cuentas,
    ) async {
      debugPrint('🔄 Stream de cuentas recibió: ${cuentas.length} cuentas');
      if (mounted) {
        setState(() {
          _accounts = cuentas;
          _hasInitialData = true;
        });
        _calculateBalanceData();

        // Esperar mínimo 800ms para mostrar animación (solo en refresh manual)
        if (shouldShowProgress) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          if (elapsed < 800) {
            await Future.delayed(Duration(milliseconds: 800 - elapsed));
          }
          if (mounted && _isManualRefresh) {
            setState(() => _isManualRefresh = false);
          }
        }
      }
    });

    // Stream de transacciones
    _transaccionesSubscription?.cancel();
    _transaccionesSubscription = _firestoreService
        .obtenerTransaccionesRecientes()
        .listen((transacciones) async {
          debugPrint(
            '🔄 Stream de transacciones recibió: ${transacciones.length} transacciones',
          );
          if (mounted) {
            setState(() {
              _transactions = transacciones;
              _hasInitialData = true;
            });
            _calculateBalanceData();

            // Esperar mínimo 800ms para mostrar animación (solo en refresh manual)
            if (shouldShowProgress) {
              final elapsed =
                  DateTime.now().difference(startTime).inMilliseconds;
              if (elapsed < 800) {
                await Future.delayed(Duration(milliseconds: 800 - elapsed));
              }
              if (mounted && _isManualRefresh) {
                setState(() => _isManualRefresh = false);
              }
            }
          }
        });

    // Stream de metas
    _metasSubscription?.cancel();
    _metasSubscription = _firestoreService.obtenerMetas().listen((metas) {
      debugPrint('🔄 Stream de metas recibió: ${metas.length} metas');
      if (mounted) {
        setState(() => _metas = metas);
      }
    });

    // Stream de presupuestos activos
    _presupuestosSubscription?.cancel();
    _presupuestosSubscription = _firestoreService
        .obtenerPresupuestosActivos()
        .listen((presupuestos) {
          debugPrint(
            '🔄 Stream de presupuestos recibió: ${presupuestos.length} presupuestos',
          );
          if (mounted) {
            setState(() => _presupuestos = presupuestos);
          }
        });

    // Stream de apartados activos
    _apartadosSubscription?.cancel();
    _apartadosSubscription = _firestoreService.obtenerApartadosActivos().listen(
      (apartados) {
        debugPrint(
          '🔄 Stream de apartados recibió: ${apartados.length} apartados',
        );
        if (mounted) {
          setState(() => _apartados = apartados);
        }
      },
    );
  }

  void _calculateBalanceData() {
    // Solo calcular si ya tenemos datos iniciales Y hay cuentas o transacciones
    if (!_hasInitialData) {
      debugPrint('❌ No hay datos iniciales aún');
      return;
    }

    debugPrint(
      '✅ Calculando balances: ${_accounts.length} cuentas, ${_transactions.length} transacciones',
    );

    double totalSaldo = _accounts.fold(
      0.0,
      (sum, cuenta) => sum + cuenta.saldo,
    );

    // Calcular ingresos y gastos del mes actual
    final now = DateTime.now();
    final mesActual = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    double ingresos = 0.0;
    double gastos = 0.0;

    for (var transaccion in _transactions) {
      final fecha =
          transaccion.fechaTimestamp ?? DateTime.parse(transaccion.fecha);
      final mesTrans =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';

      if (mesTrans == mesActual) {
        if (transaccion.tipoTransaccion == 'Ingresos' ||
            transaccion.tipoTransaccion == 'Reembolsos') {
          ingresos += transaccion.monto.abs();
        } else if (transaccion.tipoTransaccion == 'Gastos' ||
            transaccion.tipoTransaccion == 'Pagos') {
          gastos += transaccion.monto.abs();
        }
      }
    }

    debugPrint(
      '📊 Balance calculado: \$${totalSaldo}, Ingresos: \$${ingresos}, Gastos: \$${gastos}',
    );

    if (mounted) {
      setState(() {
        _balanceData = {
          'saldoCuentas': totalSaldo,
          'ingresos': ingresos,
          'gastos': gastos,
        };
      });
    }
  }

  // Tutorial Methods
  Future<void> _maybeShowDashboardTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final homeTutorialShown = prefs.getBool('tutorial_home_shown') ?? false;
    final dashboardTutorialShown = prefs.getBool(_tutorialKey) ?? false;

    if (homeTutorialShown && !dashboardTutorialShown) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _createTutorial();
          _tutorialCoachMark.show(context: context);
        }
      });
    } else if (!homeTutorialShown) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _maybeShowDashboardTutorial();
      });
    }
  }

  void _createTutorial() {
    _initTargets();
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

  void _initTargets() {
    _targets.clear();
    _targets.addAll([
      _createBalanceTarget(),
      _createAccountsTarget(),
      _createViewAllTarget(),
    ]);
  }

  TargetFocus _createBalanceTarget() {
    return TargetFocus(
      identify: "BalanceCard",
      keyTarget: _balanceCardKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 20,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r), // ✅ REDUCIDO de 20
          builder: (context, controller) {
            final theme = Theme.of(context);
            final accentColor = theme.colorScheme.primary;
            return _buildModernTutorialCard(
              title: "💰 Balance Total",
              description:
                  "Aquí puedes ver tu saldo acumulado, ingresos y gastos en un solo vistazo.",
              icon: Icons.account_balance_wallet_rounded,
              gradientColors: [
                accentColor,
                Color.lerp(accentColor, Colors.purple, 0.3)!,
              ],
              currentStep: 1,
              totalSteps: 3,
              onNext: controller.next,
              onSkip: controller.skip,
            );
          },
        ),
      ],
    );
  }

  TargetFocus _createAccountsTarget() {
    return TargetFocus(
      identify: "AccountsCarousel",
      keyTarget: _accountsCarouselKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 20,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r),
          builder: (context, controller) {
            final theme = Theme.of(context);
            final accentColor = theme.colorScheme.primary;
            return _buildModernTutorialCard(
              title: "💳 Tus Cuentas",
              description:
                  "Desliza para explorar todas tus cuentas. Cada tarjeta muestra el saldo disponible.",
              icon: Icons.credit_card_rounded,
              gradientColors: [
                accentColor,
                Color.lerp(accentColor, Colors.pink, 0.4)!,
              ],
              currentStep: 2,
              totalSteps: 3,
              onNext: controller.next,
              onBack: controller.previous,
              onSkip: controller.skip,
            );
          },
        ),
      ],
    );
  }

  TargetFocus _createViewAllTarget() {
    return TargetFocus(
      identify: "VerTodoButton",
      keyTarget: _verTodoKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          padding: EdgeInsets.all(16.r),
          builder: (context, controller) {
            final theme = Theme.of(context);
            final accentColor = theme.colorScheme.primary;
            return _buildModernTutorialCard(
              title: "📊 Historial Completo",
              description:
                  "Toca aquí para ver todas tus transacciones y analiza tus hábitos.",
              icon: Icons.history_rounded,
              gradientColors: [
                accentColor,
                Color.lerp(accentColor, Colors.cyan, 0.4)!,
              ],
              currentStep: 3,
              totalSteps: 3,
              onNext: controller.next,
              onBack: controller.previous,
              isLastStep: true,
            );
          },
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
      constraints: BoxConstraints(maxWidth: 280.w), // ✅ REDUCIDO de 350
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r), // ✅ REDUCIDO de 24
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
            padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 20
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
                  padding: EdgeInsets.all(10.r), // ✅ REDUCIDO de 12
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 26.sp,
                    color: Colors.white,
                  ), // ✅ REDUCIDO de 32
                ),
                SizedBox(height: 8.h), // ✅ REDUCIDO de 12
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp, // ✅ REDUCIDO de 20
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
            padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 20
            child: Column(
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp, // ✅ REDUCIDO de 14
                    height: 1.3,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h), // ✅ REDUCIDO de 16
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
                            fontSize: 12.sp, // ✅ REDUCIDO de 14
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

  Future<void> refreshData() async {
    debugPrint('🔄 RefreshData llamado (manual) - reactivando streams');
    setState(() => _isManualRefresh = true);
    _setupStreams();
  }

  // UI Builders - Balance Card
  Widget _buildBalanceCard() {
    final theme = Theme.of(context);

    final double saldoTotal = double.parse(
      (_balanceData?['saldoCuentas'] ?? 0.0).toString(),
    );
    final double ingresos = double.parse(
      (_balanceData?['ingresos'] ?? 0.0).toString(),
    );
    final double gastos = double.parse(
      (_balanceData?['gastos'] ?? 0.0).toString(),
    );

    return AnimationUtils.slideFromBottom(
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
        child: AnimatedContainer(
          key: _balanceCardKey,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance Total',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        _buildAnimatedBalance(saldoTotal),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Ingresos',
                      ingresos,
                      Icons.arrow_upward_rounded,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildStatColumn(
                      'Gastos',
                      gastos,
                      Icons.arrow_downward_rounded,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBalance(double amount) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: _animationDuration,
      builder: (context, animatedValue, _) {
        return Text(
          _currencyFormat.format(animatedValue),
          style: GoogleFonts.lato(
            fontSize: 32.sp,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: amount),
            duration: _animationDuration,
            builder: (context, animatedValue, _) {
              return Text(
                _currencyFormat.format(animatedValue),
                style: GoogleFonts.lato(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // UI Builders - Metas Card
  Widget _buildMetasCard() {
    if (_metas.isEmpty) return _buildEmptyMetasState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Metas',
                style: GoogleFonts.lato(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MetasScreen(),
                    ),
                  );
                },
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildMetasContent(),
      ],
    );
  }

  Widget _buildMetasContent() {
    final metaPrincipal = _metas.reduce(
      (a, b) => a.progreso > b.progreso ? a : b,
    );

    return Column(
      children: [
        // Meta principal con botón de expandir
        _buildMetaCard(metaPrincipal, isFirst: true),
        // Metas adicionales (expandibles)
        if (_metas.length > 1)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                _metasExpanded
                    ? Column(
                      children:
                          _metas
                              .where((meta) => meta.id != metaPrincipal.id)
                              .map(
                                (meta) => Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: _buildMetaCard(meta),
                                ),
                              )
                              .toList(),
                    )
                    : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildEmptyMetasState() {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MetasScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: theme.colorScheme.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Tienes una meta de ahorro?',
                      style: GoogleFonts.lato(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Crea tu primera meta y haz seguimiento',
                      style: GoogleFonts.openSans(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaCard(Meta meta, {bool isFirst = false}) {
    final theme = Theme.of(context);
    final colorHex = int.parse('FF${meta.color}', radix: 16);
    final color = Color(colorHex);

    return AnimatedCard(
      color: color,
      randomOffset: meta.nombre.length,
      horizontalMargin: 2.w,
      borderRadius: 16.r,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MetaDetalleScreen(meta: meta),
          ),
        );
      },
      headerContent: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _getIconData(meta.icono),
              size: 20.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.nombre,
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Meta de ahorro',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BudgetProgressBar(
              progreso: meta.progreso,
              color: color,
              height: 12.h,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahorrado',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(meta.montoActual),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                // Porcentaje
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${meta.progreso.toStringAsFixed(0)}%',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Objetivo',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(meta.montoObjetivo),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isFirst && _metas.length > 1) ...[
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _metasExpanded = !_metasExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _metasExpanded
                            ? 'Ver menos'
                            : 'Ver ${_metas.length - 1} meta${_metas.length > 2 ? 's' : ''} más',
                        style: GoogleFonts.lato(
                          color: theme.colorScheme.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _metasExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.primary,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'car':
        return Icons.directions_car;
      case 'travel':
        return Icons.flight;
      case 'education':
        return Icons.school;
      case 'emergency':
        return Icons.local_hospital;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.savings;
    }
  }

  // UI Builders - Accounts Carousel
  Widget _buildAccountsCarousel() {
    final sortedAccounts = List<Account>.from(_accounts)
      ..sort((a, b) => b.saldo.compareTo(a.saldo));

    if (sortedAccounts.isEmpty) return _buildEmptyAccounts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 5.h,
          ), // ✅ REDUCIDO de 6
          child: Text(
            'Mis Cuentas',
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ), // ✅ REDUCIDO de 18
          ),
        ),
        SizedBox(height: 30.h),
        SizedBox(
          key: _accountsCarouselKey,
          height: 180.h, // ✅ REDUCIDO de 200
          child: Swiper(
            itemBuilder:
                (BuildContext context, int index) =>
                    _buildAccountCard(sortedAccounts[index]),
            itemCount: sortedAccounts.length,
            viewportFraction: 0.85,
            scale: 0.9,
            loop: sortedAccounts.length > 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAccounts() {
    final theme = Theme.of(context);

    return Container(
      height: 180.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          width: 2.w,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 50.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 10.h),
            Text(
              'No hay cuentas disponibles',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final theme = Theme.of(context);

    return GestureDetector(
      onDoubleTap: () {
        // Filtrar transacciones de esta cuenta
        final transaccionesCuenta =
            _transactions.where((t) {
              return t.cuenta == account.nombre ||
                  t.cuentaOrigen == account.nombre ||
                  t.cuentaDestino == account.nombre;
            }).toList();

        if (transaccionesCuenta.isEmpty) {
          showInfoNotification(
            context,
            message: 'Sin transacciones',
            subtitle: '"${account.nombre}" no tiene transacciones registradas',
          );
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      TransaccionesScreen(cuentaFiltro: account.nombre),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                const begin = Offset(0.0, 0.1);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: theme.colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    account.nombre,
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Saldo principal
            Text(
              account.saldoRetenido > 0 ? 'Saldo total' : 'Saldo disponible',
              style: GoogleFonts.lato(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: account.saldo),
              duration: _animationDuration,
              builder: (context, animatedValue, _) {
                return Text(
                  _currencyFormat.format(animatedValue),
                  style: GoogleFonts.lato(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color:
                        account.saldo >= 0
                            ? theme.colorScheme.primary
                            : const Color(0xFFEF4444),
                    letterSpacing: -0.5,
                  ),
                );
              },
            ),
            if (account.saldoRetenido > 0) ...[
              SizedBox(height: 8.h),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
              SizedBox(height: 19.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'Disponible ',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(account.saldoDisponible),
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 20.w),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'Apartado ',
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(account.saldoRetenido),
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // UI Builders - Presupuestos (Expandible)
  Widget _buildPresupuestosCard() {
    if (_presupuestos.isEmpty) return const SizedBox.shrink();

    // Ordenar presupuestos por prioridad
    final presupuestosOrdenados = List<Budget>.from(_presupuestos);
    presupuestosOrdenados.sort((a, b) {
      if (a.excedido && !b.excedido) return -1;
      if (!a.excedido && b.excedido) return 1;
      if (a.enAlerta && !b.enAlerta) return -1;
      if (!a.enAlerta && b.enAlerta) return 1;
      return b.progreso.compareTo(a.progreso);
    });

    final presupuestoPrincipal = presupuestosOrdenados.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Presupuestos',
                style: GoogleFonts.lato(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetScreen(),
                    ),
                  );
                },
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Presupuesto principal con botón de expandir
        _buildDashboardBudgetCard(presupuestoPrincipal, isFirst: true),
        // Presupuestos adicionales (expandibles)
        if (presupuestosOrdenados.length > 1)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                _presupuestosExpanded
                    ? Column(
                      children:
                          presupuestosOrdenados
                              .skip(1)
                              .map(
                                (p) => Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: _buildDashboardBudgetCard(p),
                                ),
                              )
                              .toList(),
                    )
                    : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildDashboardBudgetCard(Budget presupuesto, {bool isFirst = false}) {
    final theme = Theme.of(context);
    final color = Color(presupuesto.colorEstado);

    // Badge de estado
    Widget? statusBadge;
    if (presupuesto.excedido || presupuesto.enAlerta) {
      statusBadge = Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              presupuesto.excedido
                  ? Icons.warning_rounded
                  : Icons.notifications_active_rounded,
              size: 13.sp,
              color: Colors.white,
            ),
            SizedBox(width: 4.w),
            Text(
              presupuesto.excedido ? 'Excedido' : 'Alerta',
              style: GoogleFonts.lato(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedCard(
      color: color,
      randomOffset: presupuesto.nombre.length,
      horizontalMargin: 2.w,
      borderRadius: 16.r,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PresupuestoDetalleScreen(presupuesto: presupuesto),
          ),
        );
      },
      headerContent: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              presupuesto.periodo == 'semanal'
                  ? Icons.calendar_view_week_rounded
                  : Icons.calendar_month_rounded,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presupuesto.nombre,
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  presupuesto.periodo == 'semanal' ? 'Semanal' : 'Mensual',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (statusBadge != null) statusBadge,
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BudgetProgressBar(
              progreso: presupuesto.progreso,
              color: color,
              height: 12.h,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastado',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(presupuesto.montoGastado),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${presupuesto.progreso.toStringAsFixed(0)}%',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Límite',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(presupuesto.montoLimite),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isFirst && _presupuestos.length > 1) ...[
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _presupuestosExpanded = !_presupuestosExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _presupuestosExpanded
                            ? 'Ver menos'
                            : 'Ver ${_presupuestos.length - 1} presupuesto${_presupuestos.length > 2 ? 's' : ''} más',
                        style: GoogleFonts.lato(
                          color: theme.colorScheme.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _presupuestosExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.primary,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // UI Builders - Apartados Card
  Widget _buildApartadosCard() {
    if (_apartados.isEmpty) return const SizedBox.shrink();

    // Ordenar: mayor progreso primero
    final apartadosOrdenados = List<Apartado>.from(_apartados);
    apartadosOrdenados.sort((a, b) => b.progreso.compareTo(a.progreso));

    final apartadoPrincipal = apartadosOrdenados.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Apartados',
                style: GoogleFonts.lato(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApartadosScreen(),
                    ),
                  );
                },
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildDashboardApartadoCard(apartadoPrincipal, isFirst: true),
        if (apartadosOrdenados.length > 1)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                _apartadosExpanded
                    ? Column(
                      children:
                          apartadosOrdenados
                              .skip(1)
                              .map(
                                (a) => Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: _buildDashboardApartadoCard(a),
                                ),
                              )
                              .toList(),
                    )
                    : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildDashboardApartadoCard(
    Apartado apartado, {
    bool isFirst = false,
  }) {
    final theme = Theme.of(context);
    final colorHex = int.parse('FF${apartado.color}', radix: 16);
    final color = Color(colorHex);

    // Badge de estado
    Widget? statusBadge;
    if (apartado.estado == 'completado') {
      statusBadge = Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 13.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text(
              'Listo',
              style: GoogleFonts.lato(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else if (apartado.estaVencido) {
      statusBadge = Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, size: 13.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text(
              'Vencido',
              style: GoogleFonts.lato(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final codePoint = int.tryParse(apartado.icono);
    final IconData iconData =
        codePoint != null
            ? IconData(codePoint, fontFamily: 'MaterialIcons')
            : Icons.account_balance_wallet;

    return AnimatedCard(
      color: color,
      randomOffset: apartado.nombre.length,
      horizontalMargin: 2.w,
      borderRadius: 16.r,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApartadoDetalleScreen(apartado: apartado),
          ),
        );
      },
      headerContent: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(iconData, size: 20.sp, color: Colors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apartado.nombre,
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (apartado.descripcion.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    apartado.descripcion,
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (statusBadge != null) statusBadge,
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BudgetProgressBar(
              progreso: apartado.progreso,
              color: color,
              height: 12.h,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apartado',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(apartado.montoApartado),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${apartado.progreso.toStringAsFixed(0)}%',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(apartado.montoTotal),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isFirst && _apartados.length > 1) ...[
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _apartadosExpanded = !_apartadosExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _apartadosExpanded
                            ? 'Ver menos'
                            : 'Ver ${_apartados.length - 1} apartado${_apartados.length > 2 ? 's' : ''} más',
                        style: GoogleFonts.lato(
                          color: theme.colorScheme.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _apartadosExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.primary,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // UI Builders - Transactions List
  Widget _buildTransactionsList() {
    final theme = Theme.of(context);

    final sortedTransactions = List<Transaction>.from(_transactions)..sort(
      (a, b) => DateTime.parse(b.fecha).compareTo(DateTime.parse(a.fecha)),
    );

    final displayCount =
        sortedTransactions.length < _maxRecentTransactions
            ? sortedTransactions.length
            : _maxRecentTransactions;

    if (sortedTransactions.isEmpty) return _buildEmptyTransactions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTransactionsHeader(theme),
        SizedBox(height: 10.h), // ✅ REDUCIDO de 12
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayCount,
          separatorBuilder:
              (context, index) => SizedBox(height: 8.h), // ✅ REDUCIDO de 10
          itemBuilder:
              (context, index) => AnimationUtils.staggeredAnimation(
                index: index,
                type: AnimationType.slideFromRight,
                child: _buildTransactionItem(
                  sortedTransactions[index],
                  index > 0 ? sortedTransactions[index - 1] : null,
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return EmptyTransactionsState();
  }

  Widget _buildTransactionsHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Transacciones Recientes',
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            key: _verTodoKey,
            onPressed: () => widget.onTabChange?.call(1),
            child: Text(
              'Ver todos',
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    Transaction transaction,
    Transaction? previousTransaction,
  ) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    final (icon, color) = _getTransactionIconAndColor(
      transaction.tipoTransaccion,
    );
    final showHeader =
        previousTransaction == null ||
        transaction.fecha != previousTransaction.fecha;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) _buildDateHeader(transaction.fecha, theme),
        _buildTransactionCard(transaction, icon, color, themeManager, theme),
      ],
    );
  }

  Widget _buildDateHeader(String date, ThemeData theme) {
    String formattedDate = DateFormat(
      'EEEE, d MMMM',
      'es_ES',
    ).format(DateTime.parse(date));
    formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 5.h), // ✅ REDUCIDO de 10/6
      child: Text(
        formattedDate,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12.sp, // ✅ REDUCIDO de 13
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    IconData icon,
    Color color,
    ThemeManager themeManager,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        leading: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        title: Text(
          transaction.descripcion,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13.sp, // ✅ REDUCIDO de 14
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Wrap(
            spacing: 4.w,
            runSpacing: 2.h,
            children: _buildTransactionBadges(transaction, color),
          ),
        ),
        trailing: Text(
          _currencyFormat.format(transaction.monto.abs()),
          style: GoogleFonts.lato(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransactionBadges(Transaction transaction, Color color) {
    final badges = <Widget>[];

    switch (transaction.tipoTransaccion) {
      case 'Traspasos':
        badges.addAll([
          _buildBadge(transaction.cuentaOrigen, color),
          Icon(Icons.arrow_forward, size: 10.sp, color: Colors.grey),
          _buildBadge(transaction.cuentaDestino, color),
        ]);
        break;
      case 'Reembolsos':
        badges.add(_buildBadge(transaction.cuenta, color));
        break;
      case 'Gastos':
      case 'Pagos':
      case 'Ingresos':
        badges.add(_buildBadge(transaction.categoria, color));
        if (transaction.cuenta.isNotEmpty) {
          badges.add(_buildBadge(transaction.cuenta, color));
        }
        break;
    }

    return badges;
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1.w),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ), // ✅ REDUCIDO de 10
      ),
    );
  }

  (IconData, Color) _getTransactionIconAndColor(String tipoTransaccion) {
    return switch (tipoTransaccion) {
      'Reembolsos' => (Icons.restore_rounded, Colors.purple),
      'Pagos' => (Icons.monetization_on_rounded, Colors.orange),
      'Traspasos' => (Icons.swap_horiz_rounded, Colors.blue),
      'Ingresos' => (Icons.trending_up_rounded, Colors.green),
      'Gastos' => (Icons.trending_down_rounded, Colors.red),
      _ => (Icons.receipt_rounded, Colors.grey),
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.background,
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      strokeWidth: 3.w,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Cargando datos...',
                      style: TextStyle(
                        color:
                            themeManager.isDarkMode
                                ? Colors.white70
                                : Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 14.r,
                      right: 14.r,
                      top: 12.h,
                      bottom: max(
                        0.0,
                        MediaQuery.of(context).padding.bottom - 25.h,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceCard(),
                        SizedBox(height: 18.h),
                        _buildAccountsCarousel(),
                        SizedBox(height: 18.h),
                        _buildPresupuestosCard(),
                        SizedBox(height: 18.h),
                        _buildMetasCard(),
                        SizedBox(height: 18.h),
                        _buildApartadosCard(),
                        SizedBox(height: 18.h),
                        _buildTransactionsList(),
                      ],
                    ),
                  ),
                  // Indicador sutil de recarga (solo refresh manual)
                  if (_isManualRefresh)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Container(
                              height: 3.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.0),
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                    Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.0),
                                  ],
                                ),
                              ),
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
    );
  }
}
