import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/reporte_detalle_screen.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'utils/animation_utils.dart';
import 'componentes/empty_states.dart';
import 'widgets/animated_goo_background.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  ReportesScreenState createState() => ReportesScreenState();
}

class ReportesScreenState extends State<ReportesScreen>
    with WidgetsBindingObserver {
  // State
  bool _isLoading = false;
  bool _isManualRefresh = false;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await initializeDateFormatting('es_ES', null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> refreshData() async {
    setState(() => _isManualRefresh = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isManualRefresh = false);
  }

  void _navigateToDetalle(Reporte reporte) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReporteDetalleScreen(reporte: reporte)),
    );
  }

  // ─── Hero card: Último reporte ───
  Widget _buildHeroCard(Reporte reporte, ThemeData theme) {
    final isPositive = reporte.balance >= 0;

    final maxAmount =
        reporte.totalIngresos > reporte.totalGastos
            ? reporte.totalIngresos
            : reporte.totalGastos;

    final heroColor = theme.colorScheme.primary;
    final radius = 18.r;

    return BounceTapButton(
      onTap: () => _navigateToDetalle(reporte),
      child: Container(
        margin: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 6.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: heroColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color:
                  theme.brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.25)
                      : Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con efecto animado
            Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(radius),
                    ),
                    child: AnimatedGooBackground(
                      color: heroColor,
                      randomOffset: reporte.fechaCorte.length,
                      enableAnimation: true,
                    ),
                  ),
                ),
                // Overlay para legibilidad
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(radius),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.black.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                // Contenido del header
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.assessment_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Último Reporte',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              reporte.fechaCorte,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 14.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${isPositive ? '+' : ''}${_currencyFormat.format(reporte.balance)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Cuerpo de la card
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barras de ingresos/gastos
                  if (reporte.tieneResumen) ...[
                    _buildHeroBar(
                      label: 'Ingresos',
                      amount: reporte.totalIngresos,
                      max: maxAmount,
                      color: const Color(0xFF66BB6A),
                      theme: theme,
                    ),
                    SizedBox(height: 10.h),
                    _buildHeroBar(
                      label: 'Gastos',
                      amount: reporte.totalGastos,
                      max: maxAmount,
                      color: const Color(0xFFEF5350),
                      theme: theme,
                    ),
                    SizedBox(height: 14.h),
                    // Footer stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeroStat(
                          Icons.account_balance_wallet_rounded,
                          'Saldo',
                          _currencyFormat.format(reporte.saldoTotal),
                          theme,
                        ),
                        _buildHeroStat(
                          Icons.receipt_long_rounded,
                          'Transacciones',
                          '${reporte.cantidadTransacciones}',
                          theme,
                        ),
                        _buildHeroStat(
                          Icons.category_rounded,
                          'Categorías',
                          '${reporte.gastosPorCategoria.length}',
                          theme,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBar({
    required String label,
    required double amount,
    required double max,
    required Color color,
    required ThemeData theme,
  }) {
    final ratio = max > 0 ? (amount / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            Text(
              _currencyFormat.format(amount),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6.h,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStat(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 15.sp,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
      ],
    );
  }

  // ─── Year section header ───
  Widget _buildYearHeader(
    String year,
    List<Reporte> reportes,
    ThemeData theme,
  ) {
    final totalIngresos = reportes.fold<double>(
      0,
      (sum, r) => sum + r.totalIngresos,
    );
    final totalGastos = reportes.fold<double>(
      0,
      (sum, r) => sum + r.totalGastos,
    );
    final balance = totalIngresos - totalGastos;
    final isPositive = balance >= 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              year,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            '${reportes.length} reporte${reportes.length != 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const Spacer(),
          if (totalIngresos > 0 || totalGastos > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: (isPositive
                        ? const Color(0xFF66BB6A)
                        : const Color(0xFFEF5350))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${_currencyFormat.format(balance)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isPositive
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFEF5350),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Report month card ───
  Widget _buildReportCard(Reporte reporte, ThemeData theme) {
    final isPositive = reporte.balance >= 0;
    final balanceColor =
        isPositive ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    final mes = reporte.fechaCorte.split(' ').first;

    return BounceTapButton(
      onTap: () => _navigateToDetalle(reporte),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  theme.brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.15)
                      : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
            reporte.tieneResumen
                ? _buildRichReportContent(
                  reporte,
                  mes,
                  theme,
                  balanceColor,
                  isPositive,
                )
                : _buildSimpleReportContent(reporte, mes, theme),
      ),
    );
  }

  Widget _buildRichReportContent(
    Reporte reporte,
    String mes,
    ThemeData theme,
    Color balanceColor,
    bool isPositive,
  ) {
    final maxAmount =
        reporte.totalIngresos > reporte.totalGastos
            ? reporte.totalIngresos
            : reporte.totalGastos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: mes + balance
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: theme.colorScheme.primary,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mes,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${reporte.cantidadTransacciones} transacciones',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13.sp,
                      color: balanceColor,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _currencyFormat.format(reporte.balance.abs()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  'balance',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Mini bars
        Row(
          children: [
            Expanded(
              child: _buildMiniBar(
                label: 'Ingresos',
                amount: reporte.totalIngresos,
                max: maxAmount,
                color: const Color(0xFF66BB6A),
                theme: theme,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildMiniBar(
                label: 'Gastos',
                amount: reporte.totalGastos,
                max: maxAmount,
                color: const Color(0xFFEF5350),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleReportContent(
    Reporte reporte,
    String mes,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.picture_as_pdf_rounded,
            color: Colors.red.shade400,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mes,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                reporte.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
          size: 20.sp,
        ),
      ],
    );
  }

  Widget _buildMiniBar({
    required String label,
    required double amount,
    required double max,
    required Color color,
    required ThemeData theme,
  }) {
    final ratio = max > 0 ? (amount / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            Text(
              _currencyFormat.format(amount),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(3.r),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4.h,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───
  Map<String, List<Reporte>> _agruparReportesPorAno(List<Reporte> reportes) {
    final Map<String, List<Reporte>> reportesPorAno = {};
    for (var reporte in reportes) {
      try {
        final String ano = reporte.fechaCorte.split(' ').last;
        reportesPorAno.putIfAbsent(ano, () => []);
        reportesPorAno[ano]!.add(reporte);
      } catch (e) {
        debugPrint('Error al extraer el año: ${reporte.fechaCorte}');
      }
    }
    final sortedKeys =
        reportesPorAno.keys.toList()
          ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    return {for (var key in sortedKeys) key: reportesPorAno[key]!};
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
            strokeWidth: 2.5.w,
          ),
          SizedBox(height: 12.h),
          Text(
            'Cargando reportes...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build list content ───
  List<Widget> _buildReportList(List<Reporte> reportes, ThemeData theme) {
    final reportesPorAno = _agruparReportesPorAno(reportes);
    final widgets = <Widget>[];

    // Hero card del último reporte con resumen
    final ultimoConResumen = reportes.where((r) => r.tieneResumen).toList();
    if (ultimoConResumen.isNotEmpty) {
      widgets.add(_buildHeroCard(ultimoConResumen.first, theme));
    }

    // Reportes agrupados por año
    for (final entry in reportesPorAno.entries) {
      final year = entry.key;
      final reportesDelAno = entry.value;

      widgets.add(_buildYearHeader(year, reportesDelAno, theme));

      // Omitir el hero del listado para no duplicar
      for (final reporte in reportesDelAno) {
        if (ultimoConResumen.isNotEmpty && reporte == ultimoConResumen.first) {
          continue;
        }
        widgets.add(_buildReportCard(reporte, theme));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          _isLoading
              ? _buildLoadingIndicator(theme)
              : Builder(
                builder: (context) {
                  final reportes = Provider.of<DataProvider>(context).reportes;

                  if (reportes.isEmpty) {
                    return const EmptyReportsState();
                  }

                  final items = _buildReportList(reportes, theme);

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      top: 8.h,
                      bottom: 32.h + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => items[i],
                  );
                },
              ),
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
                    child: SizedBox(
                      height: 3.h,
                      child: LinearProgressIndicator(
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
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
