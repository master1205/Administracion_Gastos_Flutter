import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

enum SuccessAnimationType { confetti, moneyRain, ripple, simple }

class SuccessAnimationDialog extends StatefulWidget {
  final String message;
  final VoidCallback onComplete;
  final SuccessAnimationType type;

  const SuccessAnimationDialog({
    super.key,
    this.message = 'Transacción registrada exitosamente',
    required this.onComplete,
    this.type = SuccessAnimationType.confetti,
  });

  @override
  State<SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<SuccessAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _rippleController;

  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rippleAnimation;

  final List<ConfettiParticle> confettiParticles = [];
  final List<MoneyParticle> moneyParticles = [];

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Generate particles based on animation type
    if (widget.type == SuccessAnimationType.confetti) {
      _generateConfetti();
    } else if (widget.type == SuccessAnimationType.moneyRain) {
      _generateMoneyRain();
    }

    _startAnimation();
  }

  void _generateConfetti() {
    final random = Random();
    for (int i = 0; i < 30; i++) {
      confettiParticles.add(
        ConfettiParticle(
          angle: (i * 12.0) * (pi / 180),
          distance: 150.0 + random.nextDouble() * 100,
          color: Colors.primaries[random.nextInt(Colors.primaries.length)],
          size: 12 + random.nextInt(12).toDouble(),
          rotation: random.nextDouble() * 6.28,
        ),
      );
    }
  }

  void _generateMoneyRain() {
    final random = Random();
    for (int i = 0; i < 25; i++) {
      moneyParticles.add(
        MoneyParticle(
          startX: random.nextDouble(),
          delay: random.nextDouble() * 0.4,
          duration: 1.2 + random.nextDouble() * 0.5,
          icon: random.nextBool() ? '💵' : '💰',
        ),
      );
    }
  }

  Future<void> _startAnimation() async {
    await _scaleController.forward();

    if (widget.type == SuccessAnimationType.ripple) {
      _rippleController.forward();
    }

    await _checkController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    await _fadeController.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _checkAnimation,
        _fadeAnimation,
        _rippleAnimation,
      ]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: _buildAnimationByType(),
          ),
        );
      },
    );
  }

  Widget _buildAnimationByType() {
    switch (widget.type) {
      case SuccessAnimationType.confetti:
        return _buildConfettiAnimation();
      case SuccessAnimationType.moneyRain:
        return _buildMoneyRainAnimation();
      case SuccessAnimationType.ripple:
        return _buildRippleAnimation();
      case SuccessAnimationType.simple:
        return _buildSimpleAnimation();
    }
  }

  Widget _buildConfettiAnimation() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Confetti particles
          ...confettiParticles.asMap().entries.map((entry) {
            final particle = entry.value;
            final progress = _checkAnimation.value;
            return Transform.translate(
              key: ValueKey('confetti_${entry.key}'),
              offset: Offset(
                particle.distance * cos(particle.angle) * progress,
                particle.distance * sin(particle.angle) * progress,
              ),
              child: Transform.rotate(
                angle: particle.rotation * progress * 3,
                child: Opacity(
                  opacity: (1.0 - (progress * 0.7)).clamp(0.3, 1.0),
                  child: Container(
                    width: particle.size,
                    height: particle.size,
                    decoration: BoxDecoration(
                      color: particle.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),

          Center(child: _buildSuccessCard()),
        ],
      ),
    );
  }

  Widget _buildMoneyRainAnimation() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Money particles
          ...moneyParticles.asMap().entries.map((entry) {
            final particle = entry.value;
            final progress =
                (_checkAnimation.value - particle.delay).clamp(0.0, 1.0) /
                particle.duration;
            if (progress <= 0)
              return SizedBox.shrink(key: ValueKey('money_empty_${entry.key}'));

            return Positioned(
              key: ValueKey('money_${entry.key}'),
              left: MediaQuery.of(context).size.width * particle.startX,
              top: MediaQuery.of(context).size.height * progress,
              child: Opacity(
                opacity: (1.0 - (progress * 0.7)).clamp(0.3, 1.0),
                child: Transform.rotate(
                  angle: progress * 6.28 * 2,
                  child: Text(particle.icon, style: TextStyle(fontSize: 28.sp)),
                ),
              ),
            );
          }),

          Center(child: _buildSuccessCard()),
        ],
      ),
    );
  }

  Widget _buildRippleAnimation() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple circles
          ...List.generate(3, (index) {
            final delay = index * 0.15;
            final size = 200.0 + (index * 100);
            final progress = (_rippleAnimation.value - delay).clamp(0.0, 1.0);

            return Container(
              key: ValueKey('ripple_$index'),
              width: size * progress,
              height: size * progress,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.withOpacity(
                    (1.0 - (progress * 0.6)).clamp(0.4, 1.0),
                  ),
                  width: 4,
                ),
              ),
            );
          }),

          Center(child: _buildSuccessCard()),
        ],
      ),
    );
  }

  Widget _buildSimpleAnimation() {
    return _buildSuccessCard();
  }

  Widget _buildSuccessCard() {
    return Transform.scale(
      scale: _scaleAnimation.value,
      child: Container(
        padding: EdgeInsets.all(40.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20.r,
              spreadRadius: 5.r,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated checkmark
            Transform.scale(
              scale: _checkAnimation.value,
              child: Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 15.r,
                      spreadRadius: 3.r,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 50.sp,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '¡Éxito!',
              style: GoogleFonts.lato(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfettiParticle {
  final double angle;
  final double distance;
  final Color color;
  final double size;
  final double rotation;

  ConfettiParticle({
    required this.angle,
    required this.distance,
    required this.color,
    required this.size,
    required this.rotation,
  });
}

class MoneyParticle {
  final double startX;
  final double delay;
  final double duration;
  final String icon;

  MoneyParticle({
    required this.startX,
    required this.delay,
    required this.duration,
    required this.icon,
  });
}

/// Helper function to show success animation
Future<void> showSuccessAnimation(
  BuildContext context, {
  String message = 'Transacción registrada exitosamente',
  SuccessAnimationType type = SuccessAnimationType.confetti,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    builder:
        (context) => SuccessAnimationDialog(
          message: message,
          type: type,
          onComplete: () => Navigator.of(context).pop(),
        ),
  );
}

/// Get animation type based on transaction type
SuccessAnimationType getAnimationType(String tipoTransaccion) {
  switch (tipoTransaccion) {
    case 'Ingresos':
      return SuccessAnimationType.moneyRain;
    case 'Traspasos':
      return SuccessAnimationType.ripple;
    case 'Gastos':
    case 'Pagos':
    case 'Reembolsos':
      return SuccessAnimationType.confetti;
    default:
      return SuccessAnimationType.simple;
  }
}
