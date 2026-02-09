import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/widgets/animated_goo_background.dart';
import 'package:notificaciones/widgets/animations.dart';
import 'package:url_launcher/url_launcher.dart';

class ReporteDetalleScreen extends StatelessWidget {
  final Reporte reporte;

  const ReporteDetalleScreen({Key? key, required this.reporte})
    : super(key: key);

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, theme),
          SliverToBoxAdapter(child: _buildResumenSection(theme)),
          if (reporte.gastosPorCategoria.isNotEmpty)
            SliverToBoxAdapter(child: _buildCategoriasSection(theme)),
          if (reporte.gastosPorCuenta.isNotEmpty)
            SliverToBoxAdapter(child: _buildCuentasSection(theme)),
          SliverToBoxAdapter(child: _buildPdfButton(context, theme)),
          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme) {
    final expandedH = 200.h;
    final statusBar = MediaQuery.of(context).padding.top;
    final baseColor = theme.colorScheme.primary;

    return SliverAppBar(
      expandedHeight: expandedH,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
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
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final maxExtent = expandedH + statusBar;
          final minExtent = kToolbarHeight + statusBar;
          final t = ((maxExtent - constraints.maxHeight) /
                  (maxExtent - minExtent))
              .clamp(0.0, 1.0);
          final contentOpacity = (1.0 - t * 2.0).clamp(0.0, 1.0);

          final titleFontSize = 22.0 - 6.0 * t;
          final expandedY = maxExtent - 130.h;
          final collapsedY = statusBar + kToolbarHeight / 2;
          final titleCenterY = expandedY + (collapsedY - expandedY) * t;
          final titleLeft = 76.w + (56.w - 76.w) * t;
          final titleRight = 20.w + (56.w - 20.w) * t;

          return Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: AnimatedGooBackground(
                    color: baseColor,
                    randomOffset: reporte.fechaCorte.length,
                    enableAnimation: true,
                  ),
                ),
              ),
              // Overlay con tono
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        baseColor.withOpacity(0.35),
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Contenido expandido
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
                                    Icons.assessment_rounded,
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
                                      SizedBox(height: 28.h),
                                      Text(
                                        'Reporte Mensual',
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
                            SizedBox(height: 14.h),
                            if (reporte.tieneResumen)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildHeaderStat(
                                    label: 'Ingresos',
                                    value: _currencyFormat.format(
                                      reporte.totalIngresos,
                                    ),
                                    icon: Icons.trending_up_rounded,
                                  ),
                                  _buildHeaderStat(
                                    label: 'Gastos',
                                    value: _currencyFormat.format(
                                      reporte.totalGastos,
                                    ),
                                    icon: Icons.trending_down_rounded,
                                  ),
                                  _buildHeaderStat(
                                    label: 'Transacciones',
                                    value: '${reporte.cantidadTransacciones}',
                                    icon: Icons.receipt_long_rounded,
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
              // Título deslizable
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
                    reporte.fechaCorte,
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

  Widget _buildHeaderStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16.sp, color: Colors.white.withOpacity(0.7)),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenSection(ThemeData theme) {
    if (!reporte.tieneResumen) {
      return Container(
        margin: EdgeInsets.all(16.r),
        padding: EdgeInsets.all(20.r),
        decoration: _cardDecoration(theme),
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 40.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 8.h),
            Text(
              'Reporte sin datos de resumen',
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Este reporte fue generado antes de la actualización. Puedes ver el PDF directamente.',
              style: GoogleFonts.lato(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final isPositive = reporte.balance >= 0;

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          // Ingresos / Gastos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn(
                label: 'Ingresos',
                amount: reporte.totalIngresos,
                color: const Color(0xFF66BB6A),
                icon: Icons.trending_up_rounded,
                theme: theme,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFD32F2F))
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: (isPositive
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFFD32F2F))
                        .withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isPositive ? '+' : '-',
                      style: GoogleFonts.lato(
                        fontSize: 10.sp,
                        color:
                            isPositive
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFFD32F2F),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(reporte.balance.abs()),
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            isPositive
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
              _buildAmountColumn(
                label: 'Gastos',
                amount: reporte.totalGastos,
                color: const Color(0xFFD32F2F),
                icon: Icons.trending_down_rounded,
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
          // Saldo / Transacciones
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Saldo al corte',
                  value: _currencyFormat.format(reporte.saldoTotal),
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Transacciones',
                  value: '${reporte.cantidadTransacciones}',
                  color: theme.colorScheme.tertiary,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required ThemeData theme,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Icon(icon, size: 16.sp, color: color.withOpacity(0.6)),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          _currencyFormat.format(amount),
          style: GoogleFonts.lato(
            fontSize: 16.sp,
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

  Widget _buildCategoriasSection(ThemeData theme) {
    final sorted =
        reporte.gastosPorCategoria.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

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
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos por Categoría',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          // Donut chart
          Center(
            child: SizedBox(
              height: 180.h,
              width: 180.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                      sections:
                          sorted.asMap().entries.map((entry) {
                            final color = colors[entry.key % colors.length];
                            return PieChartSectionData(
                              value: entry.value.value.abs(),
                              color: color,
                              radius: 80.r,
                              title: '',
                            );
                          }).toList(),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                  Container(
                    width: 95.w,
                    height: 95.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 72.w,
                    height: 72.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currencyFormat.format(reporte.totalGastos),
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'total',
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
          // Lista categorías
          ...sorted.asMap().entries.map((entry) {
            final cat = entry.value.key;
            final monto = entry.value.value;
            final porcentaje =
                reporte.totalGastos > 0
                    ? (monto / reporte.totalGastos * 100)
                    : 0.0;
            final color = colors[entry.key % colors.length];

            return Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
              margin: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      cat,
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCuentasSection(ThemeData theme) {
    final sorted =
        reporte.gastosPorCuenta.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos por Cuenta',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          ...sorted.map((entry) {
            final cuenta = entry.key;
            final monto = entry.value;
            final porcentaje =
                reporte.totalGastos > 0
                    ? (monto / reporte.totalGastos * 100)
                    : 0.0;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: 18.sp,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cuenta,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        // Barra de proporción
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: (porcentaje / 100).clamp(0, 1),
                            minHeight: 4.h,
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.primary.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(monto),
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${porcentaje.toStringAsFixed(0)}%',
                        style: GoogleFonts.lato(
                          fontSize: 11.sp,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPdfButton(BuildContext context, ThemeData theme) {
    if (reporte.file.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: BounceTapButton(
        onTap: () async {
          try {
            final uri = Uri.parse(reporte.file);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Text(
                'Ver Reporte PDF',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
}
