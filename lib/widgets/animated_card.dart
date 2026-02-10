import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notificaciones/widgets/animated_goo_background.dart';

/// Widget genérico para cards con header animado
/// Usado para presupuestos y metas
class AnimatedCard extends StatelessWidget {
  /// Color principal del gradiente
  final Color color;

  /// Offset aleatorio para variación en la animación
  final int randomOffset;

  /// Contenido del header (icono, título, badges, etc.)
  final Widget headerContent;

  /// Contenido del cuerpo de la card
  final Widget bodyContent;

  /// Callback cuando se hace tap en la card
  final VoidCallback? onTap;

  /// Margen horizontal de la card
  final double? horizontalMargin;

  /// Border radius de la card
  final double? borderRadius;

  /// Color del borde
  final Color? borderColor;

  const AnimatedCard({
    Key? key,
    required this.color,
    required this.randomOffset,
    required this.headerContent,
    required this.bodyContent,
    this.onTap,
    this.horizontalMargin,
    this.borderRadius,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? 16.r;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontalMargin ?? 16.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor ?? color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con gradiente animado
            Stack(
              children: [
                // Fondo animado
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(radius),
                    ),
                    child: AnimatedGooBackground(
                      color: color,
                      randomOffset: randomOffset,
                      enableAnimation: true,
                    ),
                  ),
                ),
                // Overlay semi-transparente para mejorar legibilidad
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
                Padding(padding: EdgeInsets.all(16.r), child: headerContent),
              ],
            ),
            // Contenido del cuerpo
            bodyContent,
          ],
        ),
      ),
    );
  }
}

/// Widget para el header de una card animada
/// Proporciona la estructura estándar: icono + texto + badge opcional
class AnimatedCardHeader extends StatelessWidget {
  /// Icono a mostrar
  final IconData icon;

  /// Título principal
  final String title;

  /// Subtítulo (opcional)
  final String? subtitle;

  /// Widget de badge/estado a mostrar a la derecha (opcional)
  final Widget? badge;

  const AnimatedCardHeader({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ícono
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 20.sp, color: Colors.white),
        ),
        SizedBox(width: 12.w),
        // Texto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle!,
                  style: TextStyle(
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
        // Badge opcional
        if (badge != null) ...[SizedBox(width: 8.w), badge!],
      ],
    );
  }
}
