import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'utils/animation_utils.dart';
import 'componentes/empty_states.dart';

class GraficasScreen extends StatefulWidget {
  const GraficasScreen({Key? key}) : super(key: key);

  @override
  GraficasScreenState createState() => GraficasScreenState();
}

class GraficasScreenState extends State<GraficasScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const String _tutorialKey = 'tutorial_graficas_shown';

  late TabController _tabController;
  late Future<List<dynamic>> _futureData;
  bool _isLoading = false;
  bool _isManualRefresh = false;

  final FirestoreService _firestoreService = FirestoreService();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  late TutorialCoachMark _tutorialCoachMark;
  final List<TargetFocus> _targets = [];
  final GlobalKey _tabBarKeyGastos = GlobalKey();
  final GlobalKey _tabBarKeyCuentas = GlobalKey();
  final GlobalKey _chartKey = GlobalKey();

  final List<Color> _chartColors = [
    const Color(0xFF667eea),
    const Color(0xFFf093fb),
    const Color(0xFF4facfe),
    const Color(0xFFfa709a),
    const Color(0xFF30cfd0),
    const Color(0xFFfeca57),
    const Color(0xFFff6348),
    const Color(0xFF5f27cd),
    const Color(0xFF48dbfb),
    const Color(0xFFff9ff3),
  ];

  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Los Streams de Firebase se actualizan automáticamente
  }

  Future<void> _loadData() async {
    final startTime = DateTime.now();
    final shouldShowProgress = _isManualRefresh;

    setState(() {
      if (!_isManualRefresh) {
        _isLoading = true;
      }
    });
    _futureData = Future.wait([
      _firestoreService.obtenerGastosPorCategoriaMesActual(),
      _firestoreService.obtenerCuentas().first,
    ]);
    try {
      await _futureData;
      await _maybeShowTutorial();

      if (shouldShowProgress) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 800) {
          await Future.delayed(Duration(milliseconds: 800 - elapsed));
        }
        if (mounted && _isManualRefresh) {
          setState(() => _isManualRefresh = false);
        }
      }
    } finally {
      if (mounted && !shouldShowProgress) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> refreshData() async {
    setState(() => _isManualRefresh = true);
    _loadData();
  }

  Color _getNextColor() {
    final color = _chartColors[_colorIndex % _chartColors.length];
    _colorIndex++;
    return color;
  }

  void _resetColors() {
    _colorIndex = 0;
  }

  Future<void> _maybeShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final transaccionesTutorialShown =
        prefs.getBool('tutorial_transacciones_shown') ?? false;
    final graficasTutorialShown = prefs.getBool(_tutorialKey) ?? false;

    if (transaccionesTutorialShown && !graficasTutorialShown) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _createTutorial();
          _tutorialCoachMark.show(context: context);
        }
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
      _createGastosTabTarget(),
      _createCuentasTabTarget(),
      _createChartTarget(),
    ]);
  }

  TargetFocus _createGastosTabTarget() {
    return TargetFocus(
      identify: "GastosTab",
      keyTarget: _tabBarKeyGastos,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "📊 Gastos por Categoría",
                description:
                    "Visualiza cómo se distribuyen tus gastos entre diferentes categorías.",
                icon: Icons.bar_chart_rounded,
                gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                currentStep: 1,
                totalSteps: 3,
                onNext: controller.next,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createCuentasTabTarget() {
    return TargetFocus(
      identify: "CuentasTab",
      keyTarget: _tabBarKeyCuentas,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "💳 Distribución de Cuentas",
                description:
                    "Compara los saldos de tus diferentes cuentas de forma visual.",
                icon: Icons.account_balance_wallet_rounded,
                gradientColors: const [Color(0xFFf093fb), Color(0xFFF5576c)],
                currentStep: 2,
                totalSteps: 3,
                onNext: controller.next,
                onBack: controller.previous,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createChartTarget() {
    return TargetFocus(
      identify: "ChartArea",
      keyTarget: _chartKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 20,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "📈 Gráficos Interactivos",
                description:
                    "Toca cualquier barra para ver detalles específicos y porcentajes.",
                icon: Icons.touch_app_rounded,
                gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                currentStep: 3,
                totalSteps: 3,
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
      constraints: BoxConstraints(maxWidth: 280.w), // ✅ REDUCIDO de 350w
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r), // ✅ REDUCIDO de 24r
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
            padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 20r
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
                  padding: EdgeInsets.all(10.r), // ✅ REDUCIDO de 12r
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 26.sp,
                    color: Colors.white,
                  ), // ✅ REDUCIDO de 32sp
                ),
                SizedBox(height: 8.h), // ✅ REDUCIDO de 12h
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp, // ✅ REDUCIDO de 20sp
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
            padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 20r
            child: Column(
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp, // ✅ REDUCIDO de 14sp
                    height: 1.3,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h), // ✅ REDUCIDO de 16h
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
                            fontSize: 12.sp, // ✅ REDUCIDO de 14sp
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
                                    horizontal: 14.w, // ✅ REDUCIDO de 20w
                                    vertical: 8.h, // ✅ REDUCIDO de 10h
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
                                          fontSize: 12.sp, // ✅ REDUCIDO de 14sp
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        isLastStep
                                            ? Icons.check_rounded
                                            : Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 14.sp, // ✅ REDUCIDO de 18sp
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
          width: isCurrent ? 20.w : 5.w, // ✅ REDUCIDO de 28w/6w
          height: 5.h, // ✅ REDUCIDO de 6h
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

  Widget _buildEmptyState({required String message, required IconData icon}) {
    return EmptyState(
      icon: icon,
      title: 'Sin datos',
      message: message,
      iconColor: Colors.blue,
    );
  }

  Widget _buildGastosPorCategoria(Map<String, double> data) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    _resetColors();

    final List<BarChartGroupData> barGroups = [];
    final List<Widget> legendItems = [];
    double totalGastos = 0;
    int index = 0;

    // ✅ PRIMERO: Calcular el TOTAL de todos los gastos
    data.forEach((category, amount) {
      totalGastos += amount;
    });

    // ✅ SEGUNDO: Crear las barras y leyendas con el porcentaje correcto
    data.forEach((category, amount) {
      final color = _getNextColor();

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              fromY: 0,
              toY: amount,
              color: color.withOpacity(0.9),
              width: 24.w,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
            ),
          ],
        ),
      );

      // ✅ CALCULAR porcentaje basado en el TOTAL
      final percentage =
          totalGastos > 0
              ? (amount / totalGastos * 100).toStringAsFixed(1)
              : '0.0';

      legendItems.add(
        _buildLegendItem(
          color: color,
          category: category,
          amount: amount,
          percentage: percentage,
          themeManager: themeManager,
        ),
      );

      index++;
    });

    return ListView(
      padding: EdgeInsets.only(
        left: 14.r,
        right: 14.r,
        top: 14.r,
        bottom: 34.r + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        // Header con total
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.trending_down_rounded,
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
                          'Total de Gastos',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.secondary.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _currencyFormat.format(totalGastos),
                          style: GoogleFonts.poppins(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        AnimationUtils.slideFromBottom(
          Container(
            key: _chartKey,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: theme.colorScheme.primary,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Distribución por Categoría',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  height: 220.h,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      barGroups: barGroups,
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => theme.colorScheme.primary,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              _currencyFormat.format(rod.toY),
                              GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            );
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: totalGastos / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.secondary.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        AnimationUtils.slideFromBottom(
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.list_rounded,
                        color: theme.colorScheme.primary,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Desglose Detallado',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ...legendItems.asMap().entries.map((entry) {
                  return AnimationUtils.staggeredAnimation(
                    index: entry.key,
                    type: AnimationType.fadeIn,
                    child: entry.value,
                  );
                }).toList(),
              ],
            ),
          ),
          delay: 100,
        ),
      ],
    );
  }

  Widget _buildCuentasYSaldos(List<Account> data) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    _resetColors();

    final List<BarChartGroupData> barGroups = [];
    final List<Widget> legendItems = [];
    double totalSaldo = 0;
    int index = 0;

    // ✅ PRIMERO: Calcular el TOTAL de todos los saldos
    for (var account in data) {
      final saldo = account.saldo;
      totalSaldo += saldo;
    }

    // ✅ SEGUNDO: Crear las barras y leyendas con el porcentaje correcto
    for (var account in data) {
      final color = _getNextColor();
      final saldo = account.saldo;

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              fromY: 0,
              toY: saldo,
              color: color.withOpacity(0.9),
              width: 24.w,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
            ),
          ],
        ),
      );

      // ✅ CALCULAR porcentaje basado en el TOTAL
      final percentage =
          totalSaldo > 0
              ? (saldo / totalSaldo * 100).toStringAsFixed(1)
              : '0.0';

      legendItems.add(
        _buildLegendItem(
          color: color,
          category: account.nombre,
          amount: saldo,
          percentage: percentage,
          themeManager: themeManager,
          subtitle: account.numeroTarjeta,
        ),
      );

      index++;
    }

    return ListView(
      padding: EdgeInsets.only(
        left: 14.r,
        right: 14.r,
        top: 14.r,
        bottom: 34.r + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10.r),
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
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.secondary.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _currencyFormat.format(totalSaldo),
                          style: GoogleFonts.poppins(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      color: theme.colorScheme.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Distribución por Cuenta',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              SizedBox(
                height: 220.h,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    barGroups: barGroups,
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => theme.colorScheme.primary,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            _currencyFormat.format(rod.toY),
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                          );
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: totalSaldo / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: theme.colorScheme.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Detalle de Cuentas',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              ...legendItems.asMap().entries.map((entry) {
                return AnimationUtils.staggeredAnimation(
                  index: entry.key,
                  type: AnimationType.fadeIn,
                  child: entry.value,
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String category,
    required double amount,
    required String percentage,
    required ThemeManager themeManager,
    String? subtitle,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1.w),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(amount),
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.h),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.secondary.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.secondary.withOpacity(
                0.6,
              ),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 2.h,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  child: Container(
                    key: _tabBarKeyGastos,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 16.sp),
                        SizedBox(width: 6.w),
                        const Text('Gastos'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    key: _tabBarKeyCuentas,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, size: 16.sp),
                        SizedBox(width: 6.w),
                        const Text('Cuentas'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
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
                    SizedBox(height: 12.h),
                    Text(
                      'Cargando gráficas...',
                      style: TextStyle(
                        color: theme.colorScheme.secondary.withOpacity(0.7),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              )
              : FutureBuilder<List<dynamic>>(
                future: _futureData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        strokeWidth: 3.w,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildEmptyState(
                      message: 'Error al cargar datos',
                      icon: Icons.error_outline_rounded,
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      message: 'No hay datos disponibles',
                      icon: Icons.insert_chart_outlined_rounded,
                    );
                  }

                  final gastosPorCategoria =
                      snapshot.data![0] as Map<String, double>;
                  final cuentas = snapshot.data![1] as List<Account>;

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      gastosPorCategoria.isEmpty
                          ? _buildEmptyState(
                            message: 'No hay gastos registrados',
                            icon: Icons.money_off_rounded,
                          )
                          : _buildGastosPorCategoria(gastosPorCategoria),
                      cuentas.isEmpty
                          ? _buildEmptyState(
                            message: 'No hay cuentas disponibles',
                            icon: Icons.account_balance_wallet_outlined,
                          )
                          : _buildCuentasYSaldos(cuentas),
                    ],
                  );
                },
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
                            const Color(0xFF667eea).withOpacity(0.0),
                            const Color(0xFF667eea),
                            const Color(0xFF764ba2),
                            const Color(0xFF764ba2).withOpacity(0.0),
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
