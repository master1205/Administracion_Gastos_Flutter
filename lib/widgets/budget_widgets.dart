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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact;

  const BudgetCardWidget({
    Key? key,
    required this.budget,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
    final statusBadge =
        (budget.enAlerta || budget.excedido)
            ? Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    budget.excedido
                        ? Icons.warning_rounded
                        : Icons.notifications_active_rounded,
                    size: 14.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    budget.excedido ? 'Excedido' : 'Alerta',
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
            : null;

    // Subtítulo del header
    final subtitle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          budget.periodo == 'semanal'
              ? Icons.calendar_view_week_rounded
              : Icons.calendar_month_rounded,
          size: 14.sp,
          color: Colors.white.withOpacity(0.9),
        ),
        SizedBox(width: 4.w),
        Text(
          budget.periodo == 'semanal' ? 'Semanal' : 'Mensual',
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );

    return AnimatedCard(
      color: color,
      randomOffset: budget.nombre.length,
      horizontalMargin: isCompact ? 0 : 16.w,
      onTap: onTap,
      headerContent: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              budget.periodo == 'semanal'
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
                  budget.nombre,
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                subtitle,
              ],
            ),
          ),
          if (statusBadge != null) ...[SizedBox(width: 8.w), statusBadge],
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de progreso
            BudgetProgressBar(
              progreso: budget.progreso,
              color: color,
              height: 12.h,
            ),

            SizedBox(height: 12.h),

            // Montos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gastado
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
                      currencyFormat.format(budget.montoGastado),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
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
                    '${budget.progreso.toStringAsFixed(0)}%',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Límite
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
                      currencyFormat.format(budget.montoLimite),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Información adicional (solo en modo expandido)
            if (!isCompact) ...[
              SizedBox(height: 16.h),
              Divider(height: 1.h, thickness: 1),
              SizedBox(height: 12.h),

              // Fecha y categorías
              Row(
                children: [
                  // Período
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      icon: Icons.calendar_today_rounded,
                      label: _formatPeriodo(),
                    ),
                  ),
                  if (budget.esRecurrente) ...[
                    SizedBox(width: 8.w),
                    _buildInfoChip(
                      context,
                      icon: Icons.sync_rounded,
                      label: 'Se renueva',
                    ),
                  ],
                ],
              ),

              if (!budget.aplicaTodasCategorias) ...[
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    ...budget.categorias.take(3).map((categoria) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          categoria,
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }),
                    if (budget.categorias.length > 3)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        child: Text(
                          '+${budget.categorias.length - 3}',
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              // Botones de acción
              if (onEdit != null || onDelete != null) ...[
                SizedBox(height: 16.h),
                Row(
                  children: [
                    if (onEdit != null)
                      Expanded(
                        child: InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 20.sp,
                                  color: color,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Editar',
                                  style: GoogleFonts.lato(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (onEdit != null && onDelete != null)
                      SizedBox(width: 10.w),
                    if (onDelete != null)
                      Expanded(
                        child: InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: theme.colorScheme.error.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20.sp,
                                  color: theme.colorScheme.error,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Eliminar',
                                  style: GoogleFonts.lato(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
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
