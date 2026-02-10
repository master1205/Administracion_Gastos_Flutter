import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/haptic_utils.dart';

/// Diálogo de confirmación reutilizable con diseño Cashew
///
/// Uso:
/// ```dart
/// final confirmed = await showConfirmationDialog(
///   context: context,
///   title: 'Eliminar item',
///   message: '¿Estás seguro?',
///   confirmText: 'Eliminar',
///   confirmColor: Colors.red,
///   icon: Icons.delete_rounded,
/// );
/// ```
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  Color? confirmColor,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => ConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          confirmColor: confirmColor,
          icon: icon,
        ),
  );
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.confirmColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveConfirmColor = confirmColor ?? theme.colorScheme.primary;
    final effectiveIcon = icon ?? Icons.info_outline;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 280.w),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: effectiveConfirmColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: effectiveConfirmColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                effectiveIcon,
                size: 30.sp,
                color: effectiveConfirmColor,
              ),
            ),
            SizedBox(height: 13.h),

            // Título
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),

            // Mensaje
            Text(
              message,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),

            // Botones
            Row(
              children: [
                // Botón Cancelar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(false),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Center(
                            child: Text(
                              cancelText,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),

                // Botón Confirmar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: effectiveConfirmColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: effectiveConfirmColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Haptics.heavy();
                          Navigator.of(context).pop(true);
                        },
                        borderRadius: BorderRadius.circular(10.r),
                        splashColor: effectiveConfirmColor.withOpacity(0.1),
                        highlightColor: effectiveConfirmColor.withOpacity(0.05),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Center(
                            child: Text(
                              confirmText,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: effectiveConfirmColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
