import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Diálogo para confirmar el descarte de cambios
class DiscardChangesDialog extends StatelessWidget {
  final String title;
  final String message;

  const DiscardChangesDialog({
    Key? key,
    this.title = '¿Descartar cambios?',
    this.message =
        'Tienes cambios sin guardar. ¿Estás seguro de que quieres descartarlos?',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 30.sp,
                color: theme.colorScheme.primary,
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
                Expanded(
                  child: _buildButton(
                    context: context,
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(false),
                    isPrimary: false,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildButton(
                    context: context,
                    label: 'Descartar',
                    onPressed: () => Navigator.of(context).pop(true),
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: (isPrimary
                ? theme.colorScheme.secondary
                : theme.colorScheme.secondary)
            .withOpacity(0.1),
        highlightColor: (isPrimary
                ? theme.colorScheme.secondary
                : theme.colorScheme.secondary)
            .withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color:
                isPrimary
                    ? theme.colorScheme.secondary.withOpacity(0.08)
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color:
                  isPrimary
                      ? theme.colorScheme.secondary.withOpacity(0.2)
                      : theme.colorScheme.secondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color:
                  isPrimary
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Método estático para mostrar el diálogo fácilmente
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => DiscardChangesDialog(
            title: title ?? '¿Descartar cambios?',
            message:
                message ??
                'Tienes cambios sin guardar. ¿Estás seguro de que quieres descartarlos?',
          ),
    );
    return result ?? false;
  }
}
