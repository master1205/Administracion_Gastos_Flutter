import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notificaciones/models/Meta.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/widgets/animated_goo_background.dart';
import 'package:notificaciones/widgets/budget_widgets.dart';
import 'package:notificaciones/crear_meta_screen.dart';
import 'package:notificaciones/componentes/heads_up_notification.dart';
import 'package:notificaciones/widgets/confirmation_dialog.dart';

class MetaDetalleScreen extends StatefulWidget {
  final Meta meta;

  const MetaDetalleScreen({Key? key, required this.meta}) : super(key: key);

  @override
  State<MetaDetalleScreen> createState() => _MetaDetalleScreenState();
}

class _MetaDetalleScreenState extends State<MetaDetalleScreen> {
  final ApiService _apiService = ApiService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  late Meta _meta;

  @override
  void initState() {
    super.initState();
    _meta = widget.meta;
    initializeDateFormatting('es_ES', null);
  }

  Color get _metaColor {
    try {
      final colorHex = int.parse('FF${_meta.color}', radix: 16);
      return Color(colorHex);
    } catch (_) {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Color get _statusColor {
    if (_meta.completada) return Colors.green;
    if (_meta.estaProxima) return Colors.amber.shade700;
    return _metaColor;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'emergency':
        return Icons.local_hospital_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(child: _buildSummarySection(theme)),
          SliverToBoxAdapter(child: _buildProgressSection(theme)),
          SliverToBoxAdapter(child: _buildTimelineSection(theme)),
          if (_meta.descripcion.isNotEmpty)
            SliverToBoxAdapter(child: _buildDescriptionSection(theme)),
          SliverToBoxAdapter(child: _buildDetailsSection(theme)),
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
            onTap: _editarMeta,
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

  // ── SliverAppBar con fondo animado ──────────────────────────────────

  Widget _buildSliverAppBar(ThemeData theme) {
    final montoRestante = _meta.montoObjetivo - _meta.montoActual;
    final expandedH = 240.h;
    final statusBar = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: expandedH,
      pinned: true,
      stretch: true,
      backgroundColor: _metaColor,
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
          onPressed: _eliminarMeta,
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
          final expandedY = maxExtent - 165.h;
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
                    color: _metaColor,
                    randomOffset: _meta.nombre.length,
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
                                    _getIconData(_meta.icono),
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
                                        _meta.completada
                                            ? '¡Meta completada!'
                                            : 'Faltan ${_currencyFormat.format(montoRestante.clamp(0, double.infinity))}',
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
                              progreso: _meta.progreso,
                              color: _statusColor,
                              height: 14.h,
                            ),
                            SizedBox(height: 8.h),
                            // Status badges
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_meta.progreso.toStringAsFixed(1)}%',
                                  style: GoogleFonts.lato(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                if (_meta.completada)
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
                                      '✓ Completada',
                                      style: GoogleFonts.lato(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                else if (_meta.estaProxima)
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
                                      '🔥 Casi listo',
                                      style: GoogleFonts.lato(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                Text(
                                  _meta.diasRestantes > 0
                                      ? '${_meta.diasRestantes} días'
                                      : 'Plazo vencido',
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
                    _meta.nombre,
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

  // ── Resumen con montos ─────────────────────────────────────────────

  Widget _buildSummarySection(ThemeData theme) {
    final montoRestante = (_meta.montoObjetivo - _meta.montoActual).clamp(
      0,
      double.infinity,
    );

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          // Ahorrado / Objetivo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn(
                label: 'Ahorrado',
                amount: _meta.montoActual,
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
                  '${_meta.progreso.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ),
              _buildAmountColumn(
                label: 'Objetivo',
                amount: _meta.montoObjetivo,
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
          // Info tiles
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Te falta',
                  value: _currencyFormat.format(montoRestante),
                  color:
                      _meta.completada
                          ? Colors.green
                          : theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Días restantes',
                  value: '${_meta.diasRestantes}',
                  color:
                      _meta.diasRestantes <= 7 && !_meta.completada
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
            ],
          ),
          if (_meta.cuentaNombre != null && _meta.cuentaNombre!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.account_balance_rounded,
                    label: 'Cuenta asociada',
                    value: _meta.cuentaNombre!,
                    color: theme.colorScheme.secondary,
                    theme: theme,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildInfoTile(
                    icon: _getIconData(_meta.icono),
                    label: 'Categoría',
                    value:
                        _meta.icono[0].toUpperCase() + _meta.icono.substring(1),
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

  // ── Progreso visual detallado ──────────────────────────────────────

  Widget _buildProgressSection(ThemeData theme) {
    final montoRestante = (_meta.montoObjetivo - _meta.montoActual).clamp(
      0.0,
      double.infinity,
    );

    // Ahorro diario necesario
    final ahorroDiarioNecesario =
        _meta.diasRestantes > 0 ? montoRestante / _meta.diasRestantes : 0.0;

    // Ahorro semanal necesario
    final ahorroSemanalNecesario =
        _meta.diasRestantes > 0
            ? montoRestante /
                (_meta.diasRestantes / 7).clamp(1, double.infinity)
            : 0.0;

    // Ahorro mensual necesario
    final ahorroMensualNecesario =
        _meta.diasRestantes > 0
            ? montoRestante /
                (_meta.diasRestantes / 30).clamp(1, double.infinity)
            : 0.0;

    if (_meta.completada || _meta.diasRestantes <= 0) {
      return _buildCompletionCard(theme);
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.savings_rounded,
                  color: theme.colorScheme.secondary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Para alcanzar tu meta necesitas ahorrar:',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Ritmo de ahorro requerido
          Row(
            children: [
              Expanded(
                child: _buildSavingsChip(
                  label: 'Diario',
                  value: _currencyFormat.format(ahorroDiarioNecesario),
                  icon: Icons.today_rounded,
                  theme: theme,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildSavingsChip(
                  label: 'Semanal',
                  value: _currencyFormat.format(ahorroSemanalNecesario),
                  icon: Icons.date_range_rounded,
                  theme: theme,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildSavingsChip(
                  label: 'Mensual',
                  value: _currencyFormat.format(ahorroMensualNecesario),
                  icon: Icons.calendar_month_rounded,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsChip({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(ThemeData theme) {
    final isCompleted = _meta.completada;
    final isExpired = !_meta.completada && _meta.diasRestantes <= 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : theme.colorScheme.error.withOpacity(0.2),
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
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: (isCompleted ? Colors.green : theme.colorScheme.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isCompleted
                  ? Icons.emoji_events_rounded
                  : Icons.timer_off_rounded,
              color: isCompleted ? Colors.green : theme.colorScheme.error,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? '¡Meta alcanzada!' : 'Plazo vencido',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green : theme.colorScheme.error,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isCompleted
                      ? 'Felicidades, lograste ahorrar ${_currencyFormat.format(_meta.montoActual)} para "${_meta.nombre}"'
                      : isExpired
                      ? 'El plazo para esta meta ha finalizado. Puedes editar la fecha objetivo para continuar.'
                      : '',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline: fechas de inicio y fin ───────────────────────────────

  Widget _buildTimelineSection(ThemeData theme) {
    final fechaInicio =
        _meta.fechaInicioTimestamp ?? _parseDate(_meta.fechaInicio);
    final fechaObjetivo =
        _meta.fechaObjetivoTimestamp ?? _parseDate(_meta.fechaObjetivo);

    if (fechaInicio == null && fechaObjetivo == null) {
      return const SizedBox.shrink();
    }

    final diasTotales =
        (fechaInicio != null && fechaObjetivo != null)
            ? fechaObjetivo.difference(fechaInicio).inDays
            : 0;
    final diasTranscurridos =
        fechaInicio != null
            ? DateTime.now()
                .difference(fechaInicio)
                .inDays
                .clamp(0, diasTotales)
            : 0;
    final porcentajeTiempo =
        diasTotales > 0
            ? (diasTranscurridos / diasTotales * 100).clamp(0.0, 100.0)
            : 0.0;

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Línea de tiempo',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 14.h),
          // Barra de tiempo
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                size: 16.sp,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: porcentajeTiempo / 100,
                        minHeight: 8.h,
                        backgroundColor: theme.colorScheme.onSurface
                            .withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          // Si el progreso de ahorro va detrás del tiempo, alertar
                          _meta.progreso < porcentajeTiempo && !_meta.completada
                              ? theme.colorScheme.error.withOpacity(0.7)
                              : theme.colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fechaInicio != null
                              ? DateFormat(
                                'd MMM yy',
                                'es_MX',
                              ).format(fechaInicio)
                              : _meta.fechaInicio,
                          style: GoogleFonts.lato(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          '${porcentajeTiempo.toStringAsFixed(0)}% del tiempo',
                          style: GoogleFonts.lato(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          fechaObjetivo != null
                              ? DateFormat(
                                'd MMM yy',
                                'es_MX',
                              ).format(fechaObjetivo)
                              : _meta.fechaObjetivo,
                          style: GoogleFonts.lato(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.emoji_events_rounded,
                size: 16.sp,
                color:
                    _meta.completada
                        ? Colors.amber
                        : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
          // Comparativa ahorro vs tiempo
          if (!_meta.completada && diasTotales > 0) ...[
            SizedBox(height: 14.h),
            _buildComparisonRow(
              theme: theme,
              label: 'Avance en dinero',
              value: _meta.progreso,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 6.h),
            _buildComparisonRow(
              theme: theme,
              label: 'Avance en tiempo',
              value: porcentajeTiempo,
              color:
                  _meta.progreso < porcentajeTiempo
                      ? theme.colorScheme.error
                      : theme.colorScheme.secondary,
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: (_meta.progreso >= porcentajeTiempo
                        ? Colors.green
                        : theme.colorScheme.error)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    _meta.progreso >= porcentajeTiempo
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16.sp,
                    color:
                        _meta.progreso >= porcentajeTiempo
                            ? Colors.green
                            : theme.colorScheme.error,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _meta.progreso >= porcentajeTiempo
                          ? 'Vas por buen camino, tu ahorro supera el avance del tiempo'
                          : 'Necesitas acelerar el ritmo de ahorro para llegar a tiempo',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color:
                            _meta.progreso >= porcentajeTiempo
                                ? Colors.green.shade700
                                : theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required ThemeData theme,
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120.w,
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6.h,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: GoogleFonts.lato(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Descripción ────────────────────────────────────────────────────

  Widget _buildDescriptionSection(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 18.sp,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              SizedBox(width: 8.w),
              Text(
                'Descripción',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            _meta.descripcion,
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Detalles extra ─────────────────────────────────────────────────

  Widget _buildDetailsSection(ThemeData theme) {
    final fechaInicio =
        _meta.fechaInicioTimestamp ?? _parseDate(_meta.fechaInicio);
    final fechaObjetivo =
        _meta.fechaObjetivoTimestamp ?? _parseDate(_meta.fechaObjetivo);

    final details = <_DetailItem>[
      _DetailItem(
        icon: Icons.calendar_today_rounded,
        label: 'Fecha de inicio',
        value:
            fechaInicio != null
                ? DateFormat('d MMMM yyyy', 'es_MX').format(fechaInicio)
                : _meta.fechaInicio,
      ),
      _DetailItem(
        icon: Icons.event_rounded,
        label: 'Fecha objetivo',
        value:
            fechaObjetivo != null
                ? DateFormat('d MMMM yyyy', 'es_MX').format(fechaObjetivo)
                : _meta.fechaObjetivo,
      ),
      if (_meta.cuentaNombre != null && _meta.cuentaNombre!.isNotEmpty)
        _DetailItem(
          icon: Icons.account_balance_rounded,
          label: 'Cuenta',
          value: _meta.cuentaNombre!,
        ),
      _DetailItem(
        icon:
            _meta.completada
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
        label: 'Estado',
        value:
            _meta.completada
                ? 'Completada'
                : _meta.diasRestantes <= 0
                ? 'Plazo vencido'
                : 'En progreso',
      ),
    ];

    if (_meta.createdAt != null) {
      details.add(
        _DetailItem(
          icon: Icons.access_time_rounded,
          label: 'Creada',
          value: DateFormat(
            'd MMM yyyy, HH:mm',
            'es_MX',
          ).format(_meta.createdAt!),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalles',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          ...details.map(
            (detail) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      detail.icon,
                      size: 16.sp,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.label,
                          style: GoogleFonts.lato(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          detail.value,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets reusables ──────────────────────────────────────────────

  BoxDecoration _cardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Acciones ───────────────────────────────────────────────────────

  Future<void> _editarMeta() async {
    final result = await Navigator.push<Meta>(
      context,
      MaterialPageRoute(builder: (context) => CrearMetaScreen(meta: _meta)),
    );

    if (result != null && mounted) {
      try {
        await _apiService.saveMeta(result);
        setState(() => _meta = result);
        if (mounted) {
          showSuccessNotification(context, message: 'Meta actualizada');
        }
      } catch (e) {
        if (mounted) {
          showErrorNotification(
            context,
            message: 'Error al guardar',
            subtitle: '$e',
          );
        }
      }
    }
  }

  Future<void> _eliminarMeta() async {
    final confirmar = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar meta?',
      message: 'Se eliminará "${_meta.nombre}" permanentemente.',
      confirmText: 'Eliminar',
      confirmColor: Theme.of(context).colorScheme.error,
      icon: Icons.delete_rounded,
    );

    if (confirmar == true && mounted) {
      try {
        await _apiService.deleteMeta(_meta.id);
        if (mounted) {
          showSuccessNotification(context, message: 'Meta eliminada');
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

// Helper para la sección de detalles
class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  _DetailItem({required this.icon, required this.label, required this.value});
}
