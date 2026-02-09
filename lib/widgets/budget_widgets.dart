import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/models/Budget.dart';
import 'package:notificaciones/widgets/animations.dart';
import 'package:notificaciones/widgets/animated_card.dart';

/// Widget para mostrar una card de presupuesto
class BudgetCardWidget extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;
  final bool isCompact;

  const BudgetCardWidget({
    Key? key,
    required this.budget,
    this.onTap,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    final color = Color(budget.colorEstado);

    // Badge de estado (si aplica)
    Widget? statusBadge;
    if (budget.excedido) {
      statusBadge = _buildStatusBadge(
        Icons.warning_rounded,
        'Excedido',
        Colors.red.withOpacity(0.3),
      );
    } else if (budget.enAlerta) {
      statusBadge = _buildStatusBadge(
        Icons.notifications_active_rounded,
        'Alerta',
        Colors.white.withOpacity(0.25),
      );
    }

    return AnimatedCard(
      color: color,
      randomOffset: budget.nombre.length,
      horizontalMargin: isCompact ? 0 : 16.w,
      borderRadius: 16.r,
      borderColor:
          budget.excedido
              ? Colors.red.withOpacity(0.5)
              : color.withOpacity(0.2),
      onTap: onTap,
      headerContent: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              budget.periodo == 'semanal'
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
                        budget.nombre,
                        style: GoogleFonts.lato(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (budget.esRecurrente) ...[
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
                  budget.periodo == 'semanal' ? 'Semanal' : 'Mensual',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
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
                    progreso: budget.progreso,
                    color: color,
                    height: 10.h,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${budget.progreso.toStringAsFixed(0)}%',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
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
                        style: GoogleFonts.lato(
                          fontSize: 10.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        currencyFormat.format(budget.montoGastado),
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
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
                        style: GoogleFonts.lato(
                          fontSize: 10.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        currencyFormat.format(budget.montoLimite),
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
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
                            _formatPeriodo(),
                            style: GoogleFonts.lato(
                              fontSize: 11.sp,
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
                            budget.diasRestantes > 0
                                ? '${budget.diasRestantes} días'
                                : 'Vencido',
                            style: GoogleFonts.lato(
                              fontSize: 10.sp,
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
            // Categorías chips (compact, only for non-compact mode)
            if (!isCompact && !budget.aplicaTodasCategorias) ...[
              SizedBox(height: 10.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: [
                  ...budget.categorias.take(3).map((categoria) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        categoria,
                        style: GoogleFonts.lato(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }),
                  if (budget.categorias.length > 3)
                    Text(
                      '+${budget.categorias.length - 3}',
                      style: GoogleFonts.lato(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(IconData icon, String label, Color bgColor) {
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
            style: GoogleFonts.lato(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPeriodo() {
    final inicio = DateFormat('d MMM', 'es_MX').format(budget.fechaInicio);
    final fin = DateFormat('d MMM', 'es_MX').format(budget.fechaFin);
    return '$inicio - $fin';
  }
}

/// Barra de progreso animada para presupuestos
class BudgetProgressBar extends StatelessWidget {
  final double progreso;
  final Color color;
  final double height;

  const BudgetProgressBar({
    Key? key,
    required this.progreso,
    required this.color,
    this.height = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressValue = (progreso / 100).clamp(0.0, 1.0);

    return AnimatedProgressIndicator(
      value: progressValue,
      color: color,
      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
      height: height,
      borderRadius: BorderRadius.circular((height / 2).r),
    );
  }
}
