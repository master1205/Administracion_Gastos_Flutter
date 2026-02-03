import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Muestra una notificación heads-up desde la parte superior de la pantalla
void showHeadsUpNotification(
  BuildContext context, {
  required String message,
  String? subtitle,
  required IconData icon,
  required Color backgroundColor,
  Color? iconColor,
  int durationSeconds = 3,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder:
        (context) => _HeadsUpNotification(
          message: message,
          subtitle: subtitle,
          icon: icon,
          backgroundColor: backgroundColor,
          iconColor: iconColor ?? Colors.white,
          durationSeconds: durationSeconds,
          onDismiss: () => overlayEntry.remove(),
        ),
  );

  overlay.insert(overlayEntry);
}

/// Notificación de éxito (verde)
void showSuccessNotification(
  BuildContext context, {
  required String message,
  String? subtitle,
  int durationSeconds = 3,
}) {
  showHeadsUpNotification(
    context,
    message: message,
    subtitle: subtitle,
    icon: Icons.check_circle,
    backgroundColor: const Color(0xFF4CAF50),
    iconColor: Colors.white,
    durationSeconds: durationSeconds,
  );
}

/// Notificación de error (rojo)
void showErrorNotification(
  BuildContext context, {
  required String message,
  String? subtitle,
  int durationSeconds = 3,
}) {
  showHeadsUpNotification(
    context,
    message: message,
    subtitle: subtitle,
    icon: Icons.error_outline,
    backgroundColor: const Color(0xFFF44336),
    iconColor: Colors.white,
    durationSeconds: durationSeconds,
  );
}

/// Notificación de información (azul)
void showInfoNotification(
  BuildContext context, {
  required String message,
  String? subtitle,
  int durationSeconds = 3,
}) {
  showHeadsUpNotification(
    context,
    message: message,
    subtitle: subtitle,
    icon: Icons.info_outline,
    backgroundColor: const Color(0xFF2196F3),
    iconColor: Colors.white,
    durationSeconds: durationSeconds,
  );
}

/// Notificación de advertencia (naranja)
void showWarningNotification(
  BuildContext context, {
  required String message,
  String? subtitle,
  int durationSeconds = 3,
}) {
  showHeadsUpNotification(
    context,
    message: message,
    subtitle: subtitle,
    icon: Icons.warning_amber_rounded,
    backgroundColor: const Color(0xFFFF9800),
    iconColor: Colors.white,
    durationSeconds: durationSeconds,
  );
}

// Widget interno para la notificación heads-up
class _HeadsUpNotification extends StatefulWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final int durationSeconds;
  final VoidCallback onDismiss;

  const _HeadsUpNotification({
    required this.message,
    this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.durationSeconds,
    required this.onDismiss,
  });

  @override
  State<_HeadsUpNotification> createState() => _HeadsUpNotificationState();
}

class _HeadsUpNotificationState extends State<_HeadsUpNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    // Auto-dismiss después del tiempo especificado
    Future.delayed(Duration(seconds: widget.durationSeconds), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 45.h,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 18.sp),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message,
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            Text(
                              widget.subtitle!,
                              style: GoogleFonts.openSans(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: _dismiss,
                      child: Icon(
                        Icons.close,
                        color: widget.iconColor,
                        size: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
