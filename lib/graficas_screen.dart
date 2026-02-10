import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:intl/intl.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/data_provider.dart';
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
  late Future<Map<String, double>> _futureGastos;
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
  int? _touchedGastosIndex;
  int? _touchedCuentasIndex;

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
    _futureGastos = _firestoreService.obtenerGastosPorCategoriaMesActual();
    try {
      await _futureGastos;
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
                gradientColors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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

    double totalGastos = 0;
    data.forEach((_, amount) => totalGastos += amount);

    // Ordenar por monto descendente
    final sortedEntries =
        data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    final legendData = <Map<String, dynamic>>[];
    int index = 0;

    for (final entry in sortedEntries) {
      final color = _getNextColor();
      final percentage =
          totalGastos > 0 ? (entry.value / totalGastos * 100) : 0.0;
      final isTouched = _touchedGastosIndex == index;

      sections.add(
        PieChartSectionData(
          value: entry.value,
          color: color,
          radius: isTouched ? 65.r : 55.r,
          title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
          titleStyle: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );

      legendData.add({
        'category': entry.key,
        'amount': entry.value,
        'percentage': percentage.toStringAsFixed(1),
        'color': color,
      });
      index++;
    }

    final topCategory = sortedEntries.isNotEmpty ? sortedEntries.first : null;

    return ListView(
      padding: EdgeInsets.only(
        left: 14.r,
        right: 14.r,
        top: 8.r,
        bottom: 34.r + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        // ── Tarjeta resumen ──
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.secondary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
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
                      borderRadius: BorderRadius.circular(12.r),
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
                          'Total Gastos del Mes',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _currencyFormat.format(totalGastos),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (topCategory != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 14.sp,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Mayor gasto: ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${topCategory.key} · ${_currencyFormat.format(topCategory.value)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // ── Donut chart ──
        AnimationUtils.slideFromBottom(
          Container(
            key: _chartKey,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.03),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
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
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Distribución por Categoría',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 220.h,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (
                              FlTouchEvent event,
                              pieTouchResponse,
                            ) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedGastosIndex = null;
                                  return;
                                }
                                _touchedGastosIndex =
                                    pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                              });
                            },
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 55.r,
                          sections: sections,
                          startDegreeOffset: -90,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${data.length}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'categorías',
                            style: theme.textTheme.labelSmall?.copyWith(
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
          ),
        ),
        SizedBox(height: 16.h),

        // ── Desglose detallado ──
        AnimationUtils.slideFromBottom(
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.03),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
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
                        Icons.format_list_bulleted_rounded,
                        color: theme.colorScheme.primary,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Desglose Detallado',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                ...legendData.asMap().entries.map((entry) {
                  final item = entry.value;
                  return AnimationUtils.staggeredAnimation(
                    index: entry.key,
                    type: AnimationType.fadeIn,
                    child: _buildLegendItem(
                      color: item['color'] as Color,
                      category: item['category'] as String,
                      amount: item['amount'] as double,
                      percentage: item['percentage'] as String,
                      themeManager: themeManager,
                    ),
                  );
                }),
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

    double totalSaldo = 0;
    for (var account in data) {
      totalSaldo += account.saldo;
    }

    final sections = <PieChartSectionData>[];
    final legendData = <Map<String, dynamic>>[];
    int index = 0;

    for (var account in data) {
      final color = _getNextColor();
      final saldo = account.saldo;
      final percentage = totalSaldo > 0 ? (saldo / totalSaldo * 100) : 0.0;
      final isTouched = _touchedCuentasIndex == index;

      sections.add(
        PieChartSectionData(
          value: saldo,
          color: color,
          radius: isTouched ? 65.r : 55.r,
          title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
          titleStyle: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );

      legendData.add({
        'category': account.nombre,
        'amount': saldo,
        'percentage': percentage.toStringAsFixed(1),
        'color': color,
        'subtitle': account.numeroTarjeta,
      });
      index++;
    }

    return ListView(
      padding: EdgeInsets.only(
        left: 14.r,
        right: 14.r,
        top: 8.r,
        bottom: 34.r + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        // ── Tarjeta resumen ──
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4facfe).withOpacity(0.1),
                const Color(0xFF00f2fe).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFF4facfe).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF4facfe).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF4facfe),
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
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(totalSaldo),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${data.length} cuentas',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // ── Donut chart ──
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.03),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
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
                      color: const Color(0xFF4facfe).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.donut_large_rounded,
                      color: const Color(0xFF4facfe),
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Distribución por Cuenta',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 220.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (
                            FlTouchEvent event,
                            pieTouchResponse,
                          ) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedCuentasIndex = null;
                                return;
                              }
                              _touchedCuentasIndex =
                                  pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                            });
                          },
                        ),
                        sectionsSpace: 2,
                        centerSpaceRadius: 55.r,
                        sections: sections,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${data.length}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'cuentas',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
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
        SizedBox(height: 16.h),

        // ── Detalle de cuentas ──
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.03),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
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
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Detalle de Cuentas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              ...legendData.asMap().entries.map((entry) {
                final item = entry.value;
                return AnimationUtils.staggeredAnimation(
                  index: entry.key,
                  type: AnimationType.fadeIn,
                  child: _buildLegendItem(
                    color: item['color'] as Color,
                    category: item['category'] as String,
                    amount: item['amount'] as double,
                    percentage: item['percentage'] as String,
                    themeManager: themeManager,
                    subtitle: item['subtitle'] as String?,
                  ),
                );
              }),
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
    final theme = Theme.of(context);
    final percentValue = double.tryParse(percentage) ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Container(
                    width: 14.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '$percentage%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: percentValue / 100,
              backgroundColor: color.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
              minHeight: 4.h,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Selector de pestañas tipo segmented control ──
              Container(
                margin: EdgeInsets.fromLTRB(40.w, 4.h, 40.w, 12.h),
                height: 44.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                    0.6,
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        key: _tabBarKeyGastos,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pie_chart_rounded, size: 16.sp),
                          SizedBox(width: 6.w),
                          const Text('Gastos'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        key: _tabBarKeyCuentas,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          const Text('Cuentas'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Contenido ──
              Expanded(
                child:
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
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                        : FutureBuilder<Map<String, double>>(
                          future: _futureGastos,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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

                            if (!snapshot.hasData) {
                              return _buildEmptyState(
                                message: 'No hay datos disponibles',
                                icon: Icons.insert_chart_outlined_rounded,
                              );
                            }

                            final gastosPorCategoria = snapshot.data!;
                            final cuentas =
                                Provider.of<DataProvider>(context).cuentas;

                            return TabBarView(
                              controller: _tabController,
                              children: [
                                gastosPorCategoria.isEmpty
                                    ? _buildEmptyState(
                                      message:
                                          'No hay gastos registrados este mes',
                                      icon: Icons.money_off_rounded,
                                    )
                                    : _buildGastosPorCategoria(
                                      gastosPorCategoria,
                                    ),
                                cuentas.isEmpty
                                    ? _buildEmptyState(
                                      message: 'No hay cuentas disponibles',
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                    )
                                    : _buildCuentasYSaldos(cuentas),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
          // Indicador de recarga
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
                            theme.colorScheme.primary.withOpacity(0.0),
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                            theme.colorScheme.secondary.withOpacity(0.0),
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
