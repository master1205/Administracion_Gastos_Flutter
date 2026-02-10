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
import 'package:notificaciones/data_provider.dart';
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
import 'widgets/budget_widgets.dart';
import 'presupuesto_detalle_screen.dart';
import 'meta_detalle_screen.dart';
import 'apartados_screen.dart';
import 'apartado_detalle_screen.dart';
import 'widgets/animated_card.dart';
import 'widgets/expand_toggle_button.dart';

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
  Map<String, dynamic>? _balanceData;

  bool _isLoading = false;
  bool _isManualRefresh = false;
  bool _metasExpanded = false;
  bool _presupuestosExpanded = false;
  bool _apartadosExpanded = false;
  bool _hasInitialData = false;

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
    // Recalcular balances cuando DataProvider notifica cambios
    if (mounted && _hasInitialData) {
      _calculateBalanceData();
    }
  }

  @override
  void dispose() {
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
      // Los datos vienen de DataProvider — solo calcular balances
      _hasInitialData = true;
      _calculateBalanceData();
      await _maybeShowDashboardTutorial();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateBalanceData() {
    if (!_hasInitialData) return;

    final dp = Provider.of<DataProvider>(context, listen: false);
    final accounts = dp.cuentas;
    final transactions = dp.transacciones;

    double totalSaldo = accounts.fold(0.0, (sum, cuenta) => sum + cuenta.saldo);

    // Calcular ingresos y gastos del mes actual
    final now = DateTime.now();
    final mesActual = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    double ingresos = 0.0;
    double gastos = 0.0;

    for (var transaccion in transactions) {
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
      colorShadow: Theme.of(context).colorScheme.shadow,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onBack,
                              icon: Icon(Icons.arrow_back_rounded, size: 16.sp),
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
            color:
                !isActive && !isCurrent
                    ? Theme.of(context).colorScheme.outlineVariant
                    : null,
            borderRadius: BorderRadius.circular(2.5.r),
          ),
        );
      }),
    );
  }

  Future<void> refreshData() async {
    debugPrint('🔄 RefreshData llamado (manual)');
    setState(() => _isManualRefresh = true);
    // DataProvider streams se actualizan automáticamente
    _calculateBalanceData();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isManualRefresh = false);
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
                color: theme.colorScheme.shadow.withOpacity(0.03),
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
                          style: theme.textTheme.bodySmall?.copyWith(
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
          style: theme.textTheme.headlineLarge?.copyWith(
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
                style: theme.textTheme.bodySmall?.copyWith(
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
                style: theme.textTheme.titleLarge?.copyWith(
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

    return ExpandableSection<Meta>(
      title: 'Mis Metas',
      items: _metas,
      isExpanded: _metasExpanded,
      itemLabel: 'meta',
      onToggle: () => setState(() => _metasExpanded = !_metasExpanded),
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MetasScreen()),
        );
      },
      selectPrincipal:
          (metas) => metas.reduce((a, b) => a.progreso > b.progreso ? a : b),
      itemBuilder: (meta, isFirst) => _buildMetaCard(meta, isFirst: isFirst),
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
                color: theme.colorScheme.shadow.withOpacity(0.03),
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Crea tu primera meta y haz seguimiento',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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

    // Urgencia: próximos 7 días
    final diasRestantes = meta.diasRestantes;
    final esUrgente =
        !meta.completada && diasRestantes >= 0 && diasRestantes <= 7;

    // Status badge
    String estadoLabel = '';
    IconData? estadoIcon;
    Color estadoBgColor = Colors.white.withOpacity(0.25);
    if (meta.completada) {
      estadoLabel = 'Completada';
      estadoIcon = Icons.check_circle_rounded;
    } else if (meta.estaProxima) {
      estadoLabel = 'Casi listo';
      estadoIcon = Icons.local_fire_department_rounded;
      estadoBgColor = Colors.amber.withOpacity(0.3);
    }

    return AnimatedCard(
      color: meta.completada ? Colors.green : color,
      randomOffset: meta.nombre.length,
      horizontalMargin: 2.w,
      borderRadius: 16.r,
      borderColor:
          esUrgente ? Colors.red.withOpacity(0.5) : color.withOpacity(0.2),
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
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _getIconData(meta.icono),
              size: 18.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.nombre,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.descripcion.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    meta.descripcion,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11.sp,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (meta.cuentaNombre != null &&
                    meta.cuentaNombre!.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    meta.cuentaNombre!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11.sp,
                      color: Colors.white.withOpacity(0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (estadoLabel.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: estadoBgColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (estadoIcon != null) ...[
                    Icon(estadoIcon, size: 12.sp, color: Colors.white),
                    SizedBox(width: 3.w),
                  ],
                  Text(
                    estadoLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (esUrgente)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '$diasRestantes d',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.fromLTRB(16.r, 12.r, 16.r, 14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar with percentage
            Row(
              children: [
                Expanded(
                  child: BudgetProgressBar(
                    progreso: meta.progreso,
                    color: color,
                    height: 10.h,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${meta.progreso.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Montos + info
            Row(
              children: [
                // Ahorrado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahorrado',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(meta.montoActual),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Objetivo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Objetivo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(meta.montoObjetivo),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 11.sp,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.45,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            _formatDate(meta.fechaObjetivo),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            meta.diasRestantes > 0
                                ? '${meta.diasRestantes} días'
                                : 'Vencida',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isFirst && _metas.length > 1) ...[
              SizedBox(height: 12.h),
              ExpandToggleButton(
                isExpanded: _metasExpanded,
                itemCount: _metas.length - 1,
                itemLabel: 'meta',
                onToggle:
                    () => setState(() => _metasExpanded = !_metasExpanded),
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM', 'es').format(date);
    } catch (e) {
      return dateStr;
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
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
          child: Text(
            'Mis Cuentas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          key: _accountsCarouselKey,
          height: 195.h,
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
        color: theme.colorScheme.surfaceContainerLow,
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
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            SizedBox(height: 10.h),
            Text(
              'No hay cuentas disponibles',
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
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
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final hasRetenido = account.saldoRetenido > 0;

    return GestureDetector(
      onDoubleTap: () {
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
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: primary.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: image + name + type badge
              Row(
                children: [
                  // Account image
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: primary.withOpacity(0.1),
                      border: Border.all(
                        color: primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.5.r),
                      child: Image.asset(
                        'assets/images/${account.imagen}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.account_balance_wallet_rounded,
                            color: primary,
                            size: 22.sp,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.nombre,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (account.numeroTarjeta != null &&
                            account.numeroTarjeta!.isNotEmpty)
                          Text(
                            '•••• •••• •••• ${account.numeroTarjeta!.substring(account.numeroTarjeta!.length - 4)}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 11.sp,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.5,
                            ),
                          ),
                        if (account.beneficiario != null &&
                            account.beneficiario!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              account.beneficiario!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Balance section
              Text(
                hasRetenido ? 'Saldo total' : 'Saldo disponible',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
              if (hasRetenido) ...[
                SizedBox(height: 10.h),
                // Distribution bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: SizedBox(
                    height: 4.h,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (account.saldoDisponible *
                                  100 /
                                  (account.saldo == 0 ? 1 : account.saldo))
                              .round()
                              .clamp(0, 100),
                          child: Container(color: primary),
                        ),
                        Expanded(
                          flex: (account.saldoRetenido *
                                  100 /
                                  (account.saldo == 0 ? 1 : account.saldo))
                              .round()
                              .clamp(0, 100),
                          child: Container(color: primary.withOpacity(0.25)),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildCardBalanceLabel(
                      'Disponible',
                      account.saldoDisponible,
                      primary,
                    ),
                    const Spacer(),
                    _buildCardBalanceLabel(
                      'Apartado',
                      account.saldoRetenido,
                      colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBalanceLabel(String label, double amount, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(
          '$label ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          _currencyFormat.format(amount),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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

    return ExpandableSection<Budget>(
      title: 'Presupuestos',
      items: presupuestosOrdenados,
      isExpanded: _presupuestosExpanded,
      itemLabel: 'presupuesto',
      onToggle:
          () => setState(() => _presupuestosExpanded = !_presupuestosExpanded),
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetScreen()),
        );
      },
      itemBuilder:
          (presupuesto, isFirst) =>
              _buildDashboardBudgetCard(presupuesto, isFirst: isFirst),
    );
  }

  Widget _buildDashboardBudgetCard(Budget presupuesto, {bool isFirst = false}) {
    final theme = Theme.of(context);
    final color = Color(presupuesto.colorEstado);

    // Badge de estado
    Widget? statusBadge;
    if (presupuesto.excedido) {
      statusBadge = _buildBudgetStatusBadge(
        Icons.warning_rounded,
        'Excedido',
        Colors.red.withOpacity(0.3),
      );
    } else if (presupuesto.enAlerta) {
      statusBadge = _buildBudgetStatusBadge(
        Icons.notifications_active_rounded,
        'Alerta',
        Colors.white.withOpacity(0.25),
      );
    }

    return AnimatedCard(
      color: color,
      randomOffset: presupuesto.nombre.length,
      horizontalMargin: 2.w,
      borderRadius: 16.r,
      borderColor:
          presupuesto.excedido
              ? Colors.red.withOpacity(0.5)
              : color.withOpacity(0.2),
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
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              presupuesto.periodo == 'semanal'
                  ? Icons.calendar_view_week_rounded
                  : Icons.calendar_month_rounded,
              size: 18.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        presupuesto.nombre,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (presupuesto.esRecurrente) ...[
                      SizedBox(width: 5.w),
                      Icon(
                        Icons.repeat_rounded,
                        size: 13.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  presupuesto.periodo == 'semanal' ? 'Semanal' : 'Mensual',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          if (statusBadge != null) statusBadge,
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.fromLTRB(16.r, 12.r, 16.r, 14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar with percentage
            Row(
              children: [
                Expanded(
                  child: BudgetProgressBar(
                    progreso: presupuesto.progreso,
                    color: color,
                    height: 10.h,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${presupuesto.progreso.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Montos + info
            Row(
              children: [
                // Gastado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gastado',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(presupuesto.montoGastado),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Límite
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Límite',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(presupuesto.montoLimite),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11.sp,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.45,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            _formatBudgetPeriodo(presupuesto),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            presupuesto.diasRestantes > 0
                                ? '${presupuesto.diasRestantes} días'
                                : 'Vencido',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isFirst && _presupuestos.length > 1) ...[
              SizedBox(height: 12.h),
              ExpandToggleButton(
                isExpanded: _presupuestosExpanded,
                itemCount: _presupuestos.length - 1,
                itemLabel: 'presupuesto',
                onToggle:
                    () => setState(
                      () => _presupuestosExpanded = !_presupuestosExpanded,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStatusBadge(IconData icon, String label, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: Colors.white),
          SizedBox(width: 3.w),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBudgetPeriodo(Budget budget) {
    final inicio = DateFormat('d MMM', 'es_MX').format(budget.fechaInicio);
    final fin = DateFormat('d MMM', 'es_MX').format(budget.fechaFin);
    return '$inicio - $fin';
  }

  // UI Builders - Apartados Card
  Widget _buildApartadosCard() {
    if (_apartados.isEmpty) return const SizedBox.shrink();

    // Ordenar: mayor progreso primero
    final apartadosOrdenados = List<Apartado>.from(_apartados);
    apartadosOrdenados.sort((a, b) => b.progreso.compareTo(a.progreso));

    return ExpandableSection<Apartado>(
      title: 'Apartados',
      items: apartadosOrdenados,
      isExpanded: _apartadosExpanded,
      itemLabel: 'apartado',
      onToggle: () => setState(() => _apartadosExpanded = !_apartadosExpanded),
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApartadosScreen()),
        );
      },
      itemBuilder:
          (apartado, isFirst) =>
              _buildDashboardApartadoCard(apartado, isFirst: isFirst),
    );
  }

  Widget _buildDashboardApartadoCard(
    Apartado apartado, {
    bool isFirst = false,
  }) {
    final theme = Theme.of(context);
    final colorHex = int.parse('FF${apartado.color}', radix: 16);
    final color = Color(colorHex);
    final isPagado = apartado.estado == 'pagado';
    final cardColor = isPagado ? Colors.grey : color;

    // Estado badge
    String estadoLabel = '';
    IconData? estadoIcon;
    Color estadoBgColor = Colors.white.withOpacity(0.25);
    if (apartado.estado == 'completado') {
      estadoLabel = 'Listo';
      estadoIcon = Icons.check_circle_rounded;
    } else if (isPagado) {
      estadoLabel = 'Pagado';
      estadoIcon = Icons.done_all_rounded;
    } else if (apartado.estaVencido) {
      estadoLabel = 'Vencido';
      estadoIcon = Icons.warning_rounded;
      estadoBgColor = Colors.red.withOpacity(0.3);
    }

    // Urgencia: próximos 7 días
    final diasRestantes =
        apartado.fechaLimite.difference(DateTime.now()).inDays;
    final esUrgente =
        !isPagado &&
        apartado.estado == 'activo' &&
        diasRestantes >= 0 &&
        diasRestantes <= 7;

    final codePoint = int.tryParse(apartado.icono);
    final IconData iconData =
        codePoint != null
            ? IconData(codePoint, fontFamily: 'MaterialIcons')
            : Icons.account_balance_wallet;

    return AnimatedCard(
      color: cardColor,
      randomOffset: apartado.nombre.length,
      horizontalMargin: 2.w,
      borderRadius: 16.r,
      borderColor:
          esUrgente ? Colors.red.withOpacity(0.5) : color.withOpacity(0.2),
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
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(iconData, size: 18.sp, color: Colors.white),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        apartado.nombre,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (apartado.esRecurrente) ...[
                      SizedBox(width: 5.w),
                      Icon(
                        Icons.repeat_rounded,
                        size: 13.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ],
                ),
                if (apartado.descripcion.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    apartado.descripcion,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11.sp,
                      color: Colors.white.withOpacity(0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (estadoLabel.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: estadoBgColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (estadoIcon != null) ...[
                    Icon(estadoIcon, size: 12.sp, color: Colors.white),
                    SizedBox(width: 3.w),
                  ],
                  Text(
                    estadoLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (esUrgente)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '$diasRestantes d',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.fromLTRB(16.r, 12.r, 16.r, 14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar with percentage
            Row(
              children: [
                Expanded(
                  child: BudgetProgressBar(
                    progreso: apartado.progreso,
                    color: cardColor,
                    height: 10.h,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${apartado.progreso.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Montos + info
            Row(
              children: [
                // Apartado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apartado',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(apartado.montoApartado),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(apartado.montoTotal),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 11.sp,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.45,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '${apartado.pagosRealizados}/${apartado.numeroPagos}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            DateFormat(
                              'dd MMM',
                              'es',
                            ).format(apartado.fechaLimite),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (apartado.fechaProximoPago != null &&
                apartado.estado == 'activo') ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 12.sp,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Próximo pago: ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM',
                      'es',
                    ).format(apartado.fechaProximoPago!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
            if (isFirst && _apartados.length > 1) ...[
              SizedBox(height: 12.h),
              ExpandToggleButton(
                isExpanded: _apartadosExpanded,
                itemCount: _apartados.length - 1,
                itemLabel: 'apartado',
                onToggle:
                    () => setState(
                      () => _apartadosExpanded = !_apartadosExpanded,
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
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            key: _verTodoKey,
            onPressed: () => widget.onTabChange?.call(1),
            child: Text(
              'Ver todos',
              style: theme.textTheme.bodySmall?.copyWith(
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
          color: theme.colorScheme.onSurfaceVariant,
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
          style: theme.textTheme.bodyMedium?.copyWith(
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
          Icon(
            Icons.arrow_forward,
            size: 10.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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

  // ── Datos centralizados desde DataProvider ──
  DataProvider get _dp => Provider.of<DataProvider>(context, listen: false);
  List<Account> get _accounts => _dp.cuentas;
  List<Transaction> get _transactions => _dp.transacciones;
  List<Meta> get _metas => _dp.metas;
  List<Budget> get _presupuestos => _dp.presupuestosActivos;
  List<Apartado> get _apartados => _dp.apartadosActivos;

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    // Escuchar cambios de DataProvider para rebuild automático
    Provider.of<DataProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
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
                                : theme.colorScheme.onSurfaceVariant,
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
