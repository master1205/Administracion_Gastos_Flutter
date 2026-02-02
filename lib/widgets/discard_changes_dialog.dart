import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 340.w),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono superior
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 48.sp,
                color: Colors.white,
              ),
            ),

            // Contenido
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    message,
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          context: context,
                          label: 'Cancelar',
                          onPressed: () => Navigator.of(context).pop(false),
                          isPrimary: false,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildButton(
                          context: context,
                          label: 'Descartar',
                          onPressed: () => Navigator.of(context).pop(true),
                          isPrimary: true,
                          isDarkMode: isDarkMode,
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
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isDarkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            gradient:
                isPrimary
                    ? const LinearGradient(
                      colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color:
                isPrimary
                    ? null
                    : (isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color:
                  isPrimary
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black87),
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
