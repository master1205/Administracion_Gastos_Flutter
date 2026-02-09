import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notificaciones/models/Budget.dart';
import 'package:notificaciones/models/Transaccion.dart' as models;
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/widgets/animated_goo_background.dart';
import 'package:notificaciones/widgets/animations.dart';
import 'package:notificaciones/widgets/budget_widgets.dart';
import 'package:notificaciones/crear_presupuesto_screen.dart';
import 'package:notificaciones/componentes/heads_up_notification.dart';
import 'package:notificaciones/widgets/confirmation_dialog.dart';

class PresupuestoDetalleScreen extends StatefulWidget {
  final Budget presupuesto;

  const PresupuestoDetalleScreen({Key? key, required this.presupuesto})
    : super(key: key);

  @override
  State<PresupuestoDetalleScreen> createState() =>
      _PresupuestoDetalleScreenState();
}

class _PresupuestoDetalleScreenState extends State<PresupuestoDetalleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  late Budget _budget;
  List<models.Transaction> _transacciones = [];
  Map<String, double> _gastosPorCategoria = {};
  Map<String, String> _categoriasImagenes = {};
  List<Map<String, dynamic>> _historial = [];
  bool _isLoading = true;
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _budget = widget.presupuesto;
    initializeDateFormatting('es_ES', null);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final transacciones = await _firestoreService
          .obtenerTransaccionesPresupuesto(_budget);
      final gastos = await _firestoreService
          .obtenerGastoPorCategoriaPresupuesto(_budget);

      // Cargar los iconos reales de las categorías
      Map<String, String> imagenesMap = {};
      try {
        imagenesMap = await _firestoreService.obtenerImagenesCategorias();
      } catch (_) {}

      // Cargar historial de periodos anteriores
      List<Map<String, dynamic>> historialList = [];
      try {
        historialList = await _firestoreService.obtenerHistorialPresupuesto(
          _budget.id,
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _transacciones = transacciones;
          _gastosPorCategoria = gastos;
          _categoriasImagenes = imagenesMap;
          _historial = historialList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color get _budgetColor => Color(_budget.colorEstado);

  Color get _baseColor {
    if (_budget.colorAsignado != null) return Color(_budget.colorAsignado!);
    return Theme.of(context).colorScheme.primary;
  }

  // ── Helpers para ícono/color por tipo (igual que transacciones_screen) ──
  (IconData, Color) _getIconAndColorForType(String type) {
    return switch (type) {
      'Reembolsos' => (Icons.restore_rounded, Colors.purple),
      'Pagos' => (Icons.monetization_on_rounded, Colors.orange),
      'Traspasos' => (Icons.swap_horiz_rounded, Colors.blue),
      'Ingresos' => (Icons.trending_up_rounded, Colors.green),
      'Gastos' => (Icons.trending_down_rounded, Colors.red),
      _ => (Icons.receipt_rounded, Colors.grey),
    };
  }

  Widget _buildBadge({
    required String text,
    required Color backgroundColor,
    required TextStyle textStyle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: backgroundColor.withOpacity(0.3), width: 1.w),
      ),
      child: Text(text, style: textStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Header animado
          _buildSliverAppBar(theme),
          // Resumen
          SliverToBoxAdapter(child: _buildSummarySection(theme)),
          // Progreso por día
          SliverToBoxAdapter(child: _buildDailySpending(theme)),
          // Categorías
          if (_gastosPorCategoria.isNotEmpty)
            SliverToBoxAdapter(child: _buildCategoriesSection(theme)),
          // Historial de periodos anteriores
          if (_historial.isNotEmpty)
            SliverToBoxAdapter(child: _buildHistorialSection(theme)),
          // Título transacciones
          SliverToBoxAdapter(child: _buildTransactionsHeader(theme)),
          // Lista de transacciones
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40.r),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (_filteredTransactions.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyTransactions(theme))
          else
            _buildTransactionsList(theme),
          // Espacio inferior
          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CrearPresupuestoScreen(presupuesto: _budget),
                ),
              );
              _cargarDatos();
            },
            customBorder: const CircleBorder(),
            splashColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Center(
              child: Icon(
                Icons.edit_rounded,
                color: theme.colorScheme.primary,
                size: 24.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<models.Transaction> get _filteredTransactions {
    if (_categoriaSeleccionada == null) return _transacciones;
    return _transacciones
        .where((t) => t.categoria == _categoriaSeleccionada)
        .toList();
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    final expandedH = 220.h;
    final statusBar = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: expandedH,
      pinned: true,
      stretch: true,
      backgroundColor: _baseColor,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
          ),
          onPressed: _eliminarPresupuesto,
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final maxExtent = expandedH + statusBar;
          final minExtent = kToolbarHeight + statusBar;
          final t = ((maxExtent - constraints.maxHeight) /
                  (maxExtent - minExtent))
              .clamp(0.0, 1.0);
          final contentOpacity = (1.0 - t * 2.0).clamp(0.0, 1.0);

          // Título: posición expandida → colapsada
          final titleFontSize = 22.0 - 6.0 * t;
          final expandedY = maxExtent - 150.h;
          final collapsedY = statusBar + kToolbarHeight / 2;
          final titleCenterY = expandedY + (collapsedY - expandedY) * t;
          final titleLeft = 76.w + (56.w - 76.w) * t;
          final titleRight = 20.w + (56.w - 20.w) * t;

          return Stack(
            children: [
              // Fondo animado
              Positioned.fill(
                child: ClipRect(
                  child: AnimatedGooBackground(
                    color: _baseColor,
                    randomOffset: _budget.nombre.length,
                    enableAnimation: true,
                  ),
                ),
              ),
              // Overlay oscuro
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.35),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Contenido expandido (se desvanece)
              Positioned.fill(
                child: Opacity(
                  opacity: contentOpacity,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 90.h, 20.w, 20.h),
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomLeft,
                        maxHeight: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icono + espacio para título + Subtítulo
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Icon(
                                    _budget.periodo == 'semanal'
                                        ? Icons.calendar_view_week_rounded
                                        : Icons.calendar_month_rounded,
                                    size: 24.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 30.h),
                                      Text(
                                        _budget.periodo == 'semanal'
                                            ? 'Presupuesto Semanal'
                                            : 'Presupuesto Mensual',
                                        style: GoogleFonts.lato(
                                          fontSize: 13.sp,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            // Barra de progreso grande
                            BudgetProgressBar(
                              progreso: _budget.progreso,
                              color: _budgetColor,
                              height: 14.h,
                            ),
                            SizedBox(height: 8.h),
                            // Fecha rango
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'd MMM',
                                    'es_MX',
                                  ).format(_budget.fechaInicio),
                                  style: GoogleFonts.lato(
                                    fontSize: 12.sp,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                if (_budget.enAlerta || _budget.excedido)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      _budget.excedido
                                          ? '⚠ Excedido'
                                          : '⚠ Alerta',
                                      style: GoogleFonts.lato(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                Text(
                                  DateFormat(
                                    'd MMM',
                                    'es_MX',
                                  ).format(_budget.fechaFin),
                                  style: GoogleFonts.lato(
                                    fontSize: 12.sp,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Título que se desliza al AppBar
              Positioned(
                top: titleCenterY - titleFontSize.sp * 0.6,
                left: titleLeft,
                right: titleRight,
                child: Align(
                  alignment:
                      Alignment.lerp(
                        Alignment.centerLeft,
                        Alignment.center,
                        t,
                      )!,
                  child: Text(
                    _budget.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme) {
    final gastoDiarioIdeal =
        _budget.diasRestantes > 0
            ? _budget.montoRestante / _budget.diasRestantes
            : 0.0;

    final diasTotales =
        _budget.fechaFin.difference(_budget.fechaInicio).inDays + 1;

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
            blurRadius: theme.brightness == Brightness.dark ? 12 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gastado / Límite
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn(
                label: 'Gastado',
                amount: _budget.montoGastado,
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  '${_budget.progreso.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _budgetColor,
                  ),
                ),
              ),
              _buildAmountColumn(
                label: 'Límite',
                amount: _budget.montoLimite,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                theme: theme,
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
          SizedBox(height: 16.h),
          // Restante / Días
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Disponible',
                  value: _currencyFormat.format(_budget.montoRestante),
                  color:
                      _budget.excedido
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Días restantes',
                  value: '${_budget.diasRestantes} de $diasTotales',
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
            ],
          ),
          if (_budget.diasRestantes > 0 && !_budget.excedido) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.trending_down_rounded,
                    label: 'Gasto diario ideal',
                    value: _currencyFormat.format(gastoDiarioIdeal),
                    color: theme.colorScheme.secondary,
                    theme: theme,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Transacciones',
                    value: '${_transacciones.length}',
                    color: theme.colorScheme.tertiary,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountColumn({
    required String label,
    required double amount,
    required Color color,
    required ThemeData theme,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _currencyFormat.format(amount),
          style: GoogleFonts.lato(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color.withOpacity(0.7)),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySpending(ThemeData theme) {
    if (_budget.diasRestantes <= 0) return const SizedBox.shrink();

    final diasTotales =
        _budget.fechaFin.difference(_budget.fechaInicio).inDays + 1;
    final diasTranscurridos = diasTotales - _budget.diasRestantes;
    final promedioDiario =
        diasTranscurridos > 0 ? _budget.montoGastado / diasTranscurridos : 0.0;
    final proyeccion = promedioDiario * diasTotales;
    final excederaLimite = proyeccion > _budget.montoLimite;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              excederaLimite
                  ? theme.colorScheme.error.withOpacity(0.2)
                  : theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
            blurRadius: theme.brightness == Brightness.dark ? 12 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: (excederaLimite
                      ? theme.colorScheme.error
                      : theme.colorScheme.secondary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              excederaLimite
                  ? Icons.trending_up_rounded
                  : Icons.show_chart_rounded,
              color:
                  excederaLimite
                      ? theme.colorScheme.error
                      : theme.colorScheme.secondary,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gastas ${_currencyFormat.format(promedioDiario)}/día',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  excederaLimite
                      ? 'A este ritmo excederás el límite por ${_currencyFormat.format(proyeccion - _budget.montoLimite)}'
                      : 'Vas bien, ${_budget.diasRestantes} días más',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color:
                        excederaLimite
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme) {
    final sortedCategories =
        _gastosPorCategoria.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Generar colores de categoría derivados del accent del tema
    final primary = theme.colorScheme.primary;
    final hsl = HSLColor.fromColor(primary);
    final colors = List.generate(8, (i) {
      final hueShift = (i * 45.0) % 360;
      return hsl
          .withHue((hsl.hue + hueShift) % 360)
          .withSaturation((hsl.saturation * 0.85).clamp(0.3, 0.8))
          .withLightness(theme.brightness == Brightness.dark ? 0.65 : 0.45)
          .toColor();
    });

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
            blurRadius: theme.brightness == Brightness.dark ? 12 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Por Categoría',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (_categoriaSeleccionada != null)
                GestureDetector(
                  onTap: () => setState(() => _categoriaSeleccionada = null),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Ver todas',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          // Gráfica de pastel estilo Cashew
          Center(
            child: SizedBox(
              height: 200.h,
              width: 200.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pie chart
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            return;
                          }
                          final index =
                              pieTouchResponse
                                  .touchedSection!
                                  .touchedSectionIndex;
                          if (index >= 0 && index < sortedCategories.length) {
                            setState(() {
                              final cat = sortedCategories[index].key;
                              _categoriaSeleccionada =
                                  _categoriaSeleccionada == cat ? null : cat;
                            });
                          }
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                      sections: _buildPieSections(sortedCategories, colors),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                  // Círculo interior semi-transparente
                  Container(
                    width: 110.w,
                    height: 110.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Círculo interior sólido
                  Container(
                    width: 85.w,
                    height: 85.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currencyFormat.format(_budget.montoGastado),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'gastado',
                          style: GoogleFonts.lato(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Lista de categorías
          ...sortedCategories.asMap().entries.map((entry) {
            final cat = entry.value.key;
            final monto = entry.value.value;
            final porcentaje =
                _budget.montoGastado > 0
                    ? (monto / _budget.montoGastado * 100)
                    : 0.0;
            final color = colors[entry.key % colors.length];
            final isSelected = _categoriaSeleccionada == cat;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _categoriaSeleccionada =
                      _categoriaSeleccionada == cat ? null : cat;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                margin: EdgeInsets.only(bottom: 4.h),
                decoration: BoxDecoration(
                  color:
                      isSelected ? color.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(cat),
                        size: 16.sp,
                        color: color,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        cat,
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(monto),
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${porcentaje.toStringAsFixed(0)}%',
                        style: GoogleFonts.lato(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, double>> sortedCategories,
    List<Color> colors,
  ) {
    final total = _budget.montoGastado;
    if (total <= 0) return [];

    return sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value.key;
      final monto = entry.value.value;
      final color = colors[index % colors.length];
      final percent = (monto / total * 100);
      final isSelected = _categoriaSeleccionada == cat;
      final isTouched = isSelected;
      final radius = isTouched ? 95.0.r : 88.0.r;

      return PieChartSectionData(
        value: monto.abs(),
        color:
            _categoriaSeleccionada == null || isSelected
                ? color
                : color.withOpacity(0.25),
        radius: radius,
        title: '',
        badgeWidget: _buildPieBadge(cat, color, percent, isTouched),
        badgePositionPercentageOffset: 0.85,
      );
    }).toList();
  }

  Widget _buildPieBadge(
    String category,
    Color color,
    double percent,
    bool isTouched,
  ) {
    // Ocultar badges para segmentos muy pequeños
    if (percent < 5 && !isTouched) return const SizedBox.shrink();

    final size = isTouched ? 38.0.r : 32.0.r;

    return AnimatedScale(
      scale: percent < 5 && !isTouched ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _getCategoryIcon(category),
          size: isTouched ? 18.sp : 15.sp,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHistorialSection(ThemeData theme) {
    // Calcular promedio histórico
    double sumaProcentajes = 0;
    for (final h in _historial) {
      sumaProcentajes += (h['porcentaje'] as num?)?.toDouble() ?? 0;
    }
    final promedio =
        _historial.isNotEmpty ? (sumaProcentajes / _historial.length) : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
            blurRadius: theme.brightness == Brightness.dark ? 12 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historial',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Prom. ${promedio.toStringAsFixed(0)}%',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Cards de cada periodo
          ..._historial.map((h) {
            final montoLimite = (h['montoLimite'] as num?)?.toDouble() ?? 0;
            final montoGastado = (h['montoGastado'] as num?)?.toDouble() ?? 0;
            final porcentaje = (h['porcentaje'] as num?)?.toDouble() ?? 0;

            DateTime? fechaInicio;
            DateTime? fechaFin;
            if (h['fechaInicio'] is Timestamp) {
              fechaInicio = (h['fechaInicio'] as Timestamp).toDate();
            }
            if (h['fechaFin'] is Timestamp) {
              fechaFin = (h['fechaFin'] as Timestamp).toDate();
            }

            // Color según porcentaje
            final Color statusColor;
            final IconData statusIcon;
            if (porcentaje >= 100) {
              statusColor = const Color(0xFFD32F2F);
              statusIcon = Icons.warning_rounded;
            } else if (porcentaje >= 80) {
              statusColor = const Color(0xFFFFA726);
              statusIcon = Icons.info_rounded;
            } else {
              statusColor = const Color(0xFF66BB6A);
              statusIcon = Icons.check_circle_rounded;
            }

            // Formato de fechas
            String rangoFechas = '';
            if (fechaInicio != null && fechaFin != null) {
              rangoFechas =
                  '${DateFormat('d MMM', 'es_MX').format(fechaInicio)} - ${DateFormat('d MMM', 'es_MX').format(fechaFin)}';
            }

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: statusColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Indicador visual
                  Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(statusIcon, size: 18.sp, color: statusColor),
                  ),
                  SizedBox(width: 12.w),
                  // Info del periodo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rangoFechas,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${_currencyFormat.format(montoGastado)} de ${_currencyFormat.format(montoLimite)}',
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Porcentaje
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${porcentaje.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final imagen = _categoriasImagenes[categoryName];
    if (imagen == null) return Icons.category;
    final codePoint = int.tryParse(imagen);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return Icons.category;
  }

  Widget _buildTransactionsHeader(ThemeData theme) {
    final count = _filteredTransactions.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _categoriaSeleccionada != null
                ? 'Transacciones: $_categoriaSeleccionada'
                : 'Todas las Transacciones',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(40.r),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          SizedBox(height: 12.h),
          Text(
            'Sin transacciones',
            style: GoogleFonts.lato(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _categoriaSeleccionada != null
                ? 'No hay transacciones en "$_categoriaSeleccionada"'
                : 'No hay transacciones en este período',
            style: GoogleFonts.lato(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme) {
    // Agrupar transacciones por fecha
    final grouped = <String, List<models.Transaction>>{};
    for (var t in _filteredTransactions) {
      final fecha = t.fecha;
      grouped.putIfAbsent(fecha, () => []).add(t);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Flatten: date headers + transaction cards
    final items = <_ListItem>[];
    for (final fecha in sortedDates) {
      items.add(
        _ListItem(
          type: _ListItemType.dateHeader,
          fecha: fecha,
          transactions: grouped[fecha]!,
        ),
      );
      for (final t in grouped[fecha]!) {
        items.add(_ListItem(type: _ListItemType.transaction, transaction: t));
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        if (item.type == _ListItemType.dateHeader) {
          return AnimatedListItem(
            index: index,
            enableHero: false,
            child: _buildDateHeader(item.fecha!, item.transactions!, theme),
          );
        }
        return AnimatedListItem(
          index: index,
          enableHero: false,
          child: _buildTransactionCard(item.transaction!, theme),
        );
      }, childCount: items.length),
    );
  }

  Widget _buildDateHeader(
    String fecha,
    List<models.Transaction> dailyTransactions,
    ThemeData theme,
  ) {
    String formattedDate = DateFormat(
      'EEEE, d MMMM',
      'es_ES',
    ).format(DateTime.parse(fecha));
    formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 14.sp,
              color: theme.colorScheme.secondary,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              formattedDate,
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            _currencyFormat.format(
              dailyTransactions.fold<double>(0.0, (s, t) => s + t.monto.abs()),
            ),
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    models.Transaction transaction,
    ThemeData theme,
  ) {
    final (icon, color) = _getIconAndColorForType(transaction.tipoTransaccion);
    final badgeTextStyle = TextStyle(
      fontSize: 9.sp,
      fontWeight: FontWeight.w600,
      color: color,
    );

    return BounceTapButton(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color:
                  theme.brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.15)
                      : Colors.black.withOpacity(0.03),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          leading: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          title: Text(
            transaction.descripcion.isNotEmpty
                ? transaction.descripcion
                : transaction.categoria,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Wrap(
              spacing: 4.w,
              runSpacing: 2.h,
              children: _buildTransactionBadges(
                transaction,
                color,
                badgeTextStyle,
              ),
            ),
          ),
          trailing: Text(
            _currencyFormat.format(transaction.monto.abs()),
            style: GoogleFonts.lato(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransactionBadges(
    models.Transaction transaction,
    Color color,
    TextStyle badgeTextStyle,
  ) {
    final badges = <Widget>[];

    switch (transaction.tipoTransaccion) {
      case 'Traspasos':
        if (transaction.cuentaOrigen.isNotEmpty &&
            transaction.cuentaDestino.isNotEmpty) {
          badges.addAll([
            _buildBadge(
              text: transaction.cuentaOrigen,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
            Icon(Icons.arrow_forward_rounded, size: 10.sp, color: color),
            _buildBadge(
              text: transaction.cuentaDestino,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
          ]);
        }
        break;
      case 'Reembolsos':
        if (transaction.cuenta.isNotEmpty) {
          badges.add(
            _buildBadge(
              text: transaction.cuenta,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
          );
        }
        break;
      case 'Gastos':
      case 'Pagos':
      case 'Ingresos':
        if (transaction.categoria.isNotEmpty) {
          badges.add(
            _buildBadge(
              text: transaction.categoria,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
          );
        }
        if (transaction.cuenta.isNotEmpty) {
          badges.add(
            _buildBadge(
              text: transaction.cuenta,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
          );
        }
        break;
    }

    return badges;
  }

  void _eliminarPresupuesto() async {
    final confirmar = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar presupuesto?',
      message:
          'Se eliminará "${_budget.nombre}". Las transacciones no se verán afectadas.',
      confirmText: 'Eliminar',
      confirmColor: Theme.of(context).colorScheme.error,
      icon: Icons.delete_rounded,
    );

    if (confirmar == true && mounted) {
      try {
        await _firestoreService.eliminarPresupuesto(_budget.id);
        if (mounted) {
          showSuccessNotification(context, message: 'Presupuesto eliminado');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showErrorNotification(
            context,
            message: 'Error al eliminar',
            subtitle: '$e',
          );
        }
      }
    }
  }
}

// Helper para construir la lista plana de headers + transacciones
enum _ListItemType { dateHeader, transaction }

class _ListItem {
  final _ListItemType type;
  final String? fecha;
  final List<models.Transaction>? transactions;
  final models.Transaction? transaction;

  _ListItem({
    required this.type,
    this.fecha,
    this.transactions,
    this.transaction,
  });
}
