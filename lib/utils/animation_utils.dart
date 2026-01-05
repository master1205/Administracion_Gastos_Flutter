import 'package:flutter/material.dart';

/// Utilidades y constantes para animaciones de la app
class AnimationUtils {
  AnimationUtils._();

  // ========== DURACIONES ==========
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // ========== CURVES ==========
  static const Curve easeInOutCurve = Curves.easeInOut;
  static const Curve bounceInCurve = Curves.bounceIn;
  static const Curve elasticOutCurve = Curves.elasticOut;
  static const Curve fastOutSlowInCurve = Curves.fastOutSlowIn;

  // ========== SLIDE ANIMATIONS ==========

  /// Animación de deslizamiento desde abajo
  static Widget slideFromBottom(
    Widget child, {
    Duration duration = normal,
    Curve curve = fastOutSlowInCurve,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * value),
          child: Opacity(opacity: 1 - value, child: child),
        );
      },
      child: child,
    );
  }

  /// Animación de deslizamiento desde la derecha
  static Widget slideFromRight(
    Widget child, {
    Duration duration = normal,
    Curve curve = fastOutSlowInCurve,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * value, 0),
          child: Opacity(opacity: 1 - value, child: child),
        );
      },
      child: child,
    );
  }

  // ========== FADE ANIMATIONS ==========

  /// Animación de fade in
  static Widget fadeIn(
    Widget child, {
    Duration duration = normal,
    Curve curve = easeInOutCurve,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  // ========== SCALE ANIMATIONS ==========

  /// Animación de escala desde pequeño
  static Widget scaleIn(
    Widget child, {
    Duration duration = normal,
    Curve curve = elasticOutCurve,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  // ========== STAGGERED ANIMATIONS ==========

  /// Builder para animaciones escalonadas en listas
  static Widget staggeredAnimation({
    required int index,
    required Widget child,
    Duration delay = const Duration(milliseconds: 50),
    AnimationType type = AnimationType.slideFromBottom,
  }) {
    final totalDelay = delay.inMilliseconds * index;

    switch (type) {
      case AnimationType.slideFromBottom:
        return slideFromBottom(child, delay: totalDelay);
      case AnimationType.slideFromRight:
        return slideFromRight(child, delay: totalDelay);
      case AnimationType.fadeIn:
        return fadeIn(child, delay: totalDelay);
      case AnimationType.scaleIn:
        return scaleIn(child, delay: totalDelay);
    }
  }
}

/// Tipos de animación para listas
enum AnimationType { slideFromBottom, slideFromRight, fadeIn, scaleIn }

// ========== WIDGETS DE ANIMACIÓN ==========

/// Widget con animación de pulso infinito
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Widget con rebote al hacer tap
class BounceTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const BounceTapButton({
    Key? key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
  }) : super(key: key);

  @override
  State<BounceTapButton> createState() => _BounceTapButtonState();
}

class _BounceTapButtonState extends State<BounceTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Shimmer effect para loading
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoading({
    Key? key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        widget.baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor =
        widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
