import 'package:flutter/material.dart';
import 'dart:async';

/// Widget que hace fade in de su hijo
class FadeIn extends StatefulWidget {
  const FadeIn({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  final Widget child;
  final Duration duration;

  @override
  _FadeInState createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(opacity: _opacityAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// Widget que hace scale in con efecto elástico
class ScaleIn extends StatefulWidget {
  const ScaleIn({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = const ElasticOutCurve(0.5),
    this.delay = Duration.zero,
  }) : super(key: key);

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  @override
  _ScaleInState createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// Widget que combina fade y slide
enum Direction { vertical, horizontal }

class SlideFadeTransition extends StatefulWidget {
  const SlideFadeTransition({
    required this.child,
    this.offset = 1,
    this.curve = Curves.decelerate,
    this.direction = Direction.vertical,
    this.delayStart = const Duration(seconds: 0),
    this.animationDuration = const Duration(milliseconds: 500),
    this.reverse = false,
  });

  final Widget child;
  final double offset;
  final Curve curve;
  final Direction direction;
  final Duration delayStart;
  final Duration animationDuration;
  final bool reverse;

  @override
  _SlideFadeTransitionState createState() => _SlideFadeTransitionState();
}

class _SlideFadeTransitionState extends State<SlideFadeTransition>
    with SingleTickerProviderStateMixin {
  late Animation<Offset> _animationSlide;
  late AnimationController _animationController;
  late Animation<double> _animationFade;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    if (widget.direction == Direction.vertical) {
      _animationSlide = Tween<Offset>(
        begin: Offset(0, widget.reverse ? -widget.offset : widget.offset),
        end: Offset(0, 0),
      ).animate(
        CurvedAnimation(curve: widget.curve, parent: _animationController),
      );
    } else {
      _animationSlide = Tween<Offset>(
        begin: Offset(widget.reverse ? -widget.offset : widget.offset, 0),
        end: Offset(0, 0),
      ).animate(
        CurvedAnimation(curve: widget.curve, parent: _animationController),
      );
    }

    _animationFade = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(curve: widget.curve, parent: _animationController),
    );

    Timer(widget.delayStart, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationFade,
      child: SlideTransition(position: _animationSlide, child: widget.child),
    );
  }
}

/// Widget para animar expansión/colapso
class AnimatedExpanded extends StatefulWidget {
  final Widget child;
  final bool expand;
  final Duration duration;
  final Curve sizeCurve;
  final Axis axis;

  const AnimatedExpanded({
    this.expand = false,
    required this.child,
    this.duration = const Duration(milliseconds: 425),
    this.sizeCurve = Curves.fastOutSlowIn,
    this.axis = Axis.vertical,
    super.key,
  });

  @override
  _AnimatedExpandedState createState() => _AnimatedExpandedState();
}

class _AnimatedExpandedState extends State<AnimatedExpanded>
    with SingleTickerProviderStateMixin {
  late AnimationController expandController;
  late Animation<double> sizeAnimation;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
  }

  void prepareAnimations() {
    expandController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.expand ? 1.0 : 0.0,
    );
    sizeAnimation = CurvedAnimation(
      parent: expandController,
      curve: widget.sizeCurve,
    );
    fadeAnimation = CurvedAnimation(
      parent: expandController,
      curve: Curves.easeInOut,
    );
    if (widget.expand) {
      expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedExpanded oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  void _runExpandCheck() {
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SizeTransition(
        axis: widget.axis,
        axisAlignment: 1.0,
        sizeFactor: sizeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget que anima cambios de tamaño suavemente
class AnimatedSizeSwitcher extends StatelessWidget {
  const AnimatedSizeSwitcher({
    required this.child,
    this.sizeCurve = Curves.easeInOutCubicEmphasized,
    this.sizeDuration = const Duration(milliseconds: 800),
    this.switcherDuration = const Duration(milliseconds: 250),
    this.sizeAlignment = AlignmentDirectional.center,
    this.clipBehavior = Clip.hardEdge,
    this.enabled = true,
    super.key,
  });
  final Widget child;
  final Curve sizeCurve;
  final Duration sizeDuration;
  final Duration switcherDuration;
  final AlignmentDirectional sizeAlignment;
  final Clip clipBehavior;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (enabled == false) return child;
    return AnimatedSize(
      clipBehavior: clipBehavior,
      duration: sizeDuration,
      curve: sizeCurve,
      alignment: sizeAlignment,
      child: AnimatedSwitcher(duration: switcherDuration, child: child),
    );
  }
}

/// Widget que combina scale y fade para switches
class ScaledAnimatedSwitcher extends StatelessWidget {
  const ScaledAnimatedSwitcher({
    required this.keyToWatch,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    Key? key,
  }) : super(key: key);

  final String keyToWatch;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Interval(0.5, 1)));

        final scaleAnimation = Tween<double>(
          begin: 0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Interval(0, 1.0)));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            alignment: Alignment.center,
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      child: SizedBox(key: ValueKey(keyToWatch), child: child),
    );
  }
}

/// Animación para botones FAB con retraso
class AnimateFABDelayed extends StatefulWidget {
  const AnimateFABDelayed({
    Key? key,
    required this.fab,
    this.delay = const Duration(milliseconds: 250),
  }) : super(key: key);

  final Widget fab;
  final Duration delay;

  @override
  State<AnimateFABDelayed> createState() => _AnimateFABDelayedState();
}

class _AnimateFABDelayedState extends State<AnimateFABDelayed> {
  bool scaleIn = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          scaleIn = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scaleIn ? 1 : 0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOutCubicEmphasized,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 100),
        opacity: scaleIn ? 1 : 0,
        child: widget.fab,
      ),
    );
  }
}

/// Widget que anima scale y opacity juntos
class AnimatedScaleOpacity extends StatelessWidget {
  const AnimatedScaleOpacity({
    required this.child,
    required this.animateIn,
    this.duration = const Duration(milliseconds: 500),
    this.durationOpacity = const Duration(milliseconds: 100),
    this.alignment = AlignmentDirectional.center,
    this.curve = Curves.easeInOutCubicEmphasized,
    super.key,
  });
  final Widget child;
  final bool animateIn;
  final Duration duration;
  final Duration durationOpacity;
  final AlignmentDirectional alignment;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: durationOpacity,
      opacity: animateIn ? 1 : 0,
      child: AnimatedScale(
        scale: animateIn ? 1 : 0,
        duration: duration,
        curve: curve,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Widget que respira (crece y encoge continuamente)
class BreathingWidget extends StatefulWidget {
  final Widget child;
  final Curve curve;
  final Duration duration;
  final double endScale;

  const BreathingWidget({
    Key? key,
    required this.child,
    this.curve = Curves.ease,
    this.duration = const Duration(milliseconds: 3000),
    this.endScale = 1.3,
  }) : super(key: key);

  @override
  _BreathingWidgetState createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: widget.endScale).animate(
        CurvedAnimation(parent: _animationController, curve: widget.curve),
      ),
      child: widget.child,
    );
  }
}

/// Widget que rebota
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final bool animate;
  final double amountEnd;
  final Duration duration;

  const BouncingWidget({
    required this.child,
    required this.animate,
    this.amountEnd = -8,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  _BouncingWidgetState createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(begin: 0.0, end: widget.amountEnd).animate(
      CurvedAnimation(
        parent: _controller,
        curve: ElasticOutCurve(0.6),
        reverseCurve: Curves.bounceIn,
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed && widget.animate) {
        if (widget.animate) {
          _controller.forward();
        }
      }
    });

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BouncingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_isAnimating) {
      _controller.forward();
    }
    _isAnimating = widget.animate;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
    );
  }
}

/// Widget que sacude horizontalmente
class ShakeAnimation extends StatefulWidget {
  const ShakeAnimation({
    Key? key,
    this.duration = const Duration(milliseconds: 2500),
    this.deltaX = 20,
    this.curve = const ElasticInOutCurve(0.19),
    required this.child,
    this.animate = true,
    required this.delay,
  }) : super(key: key);

  final Duration duration;
  final double deltaX;
  final Widget child;
  final Curve curve;
  final bool animate;
  final Duration delay;

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation> {
  bool startAnimation = false;

  @override
  void initState() {
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          startAnimation = true;
        });
      }
    });
    super.initState();
  }

  double shakeAnimation(double animation) =>
      0.3 * (0.5 - (0.5 - widget.curve.transform(animation)).abs());

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: widget.key,
      tween: Tween(
        begin: 0.0,
        end: widget.animate == false || startAnimation == false ? 0 : 1,
      ),
      curve: Curves.easeOut,
      duration: widget.duration,
      builder:
          (context, animation, child) => Transform.translate(
            offset: Offset(widget.deltaX * shakeAnimation(animation), 0),
            child: child,
          ),
      child: widget.child,
    );
  }
}

/// Widget simple de slide animation
class SlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset begin;
  final Duration delay;

  const SlideAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.begin = const Offset(0, 20),
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(offset: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// Widget para elementos de lista animados con fade y slide
class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final bool enableHero;
  final Duration delay;

  const AnimatedListItem({
    Key? key,
    required this.index,
    required this.child,
    this.enableHero = false,
    this.delay = const Duration(milliseconds: 50),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: SlideAnimation(
        duration: const Duration(milliseconds: 400),
        begin: const Offset(0, 20),
        delay: delay * index,
        child: child,
      ),
    );
  }
}

/// Widget para mostrar estado vacío con animaciones
class AnimatedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AnimatedEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleIn(
              child: Icon(icon, size: 80, color: Colors.grey.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            FadeIn(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              FadeIn(
                child: Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wrapper para RefreshIndicator con animaciones
class CustomRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const CustomRefreshIndicator({
    Key? key,
    required this.onRefresh,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}

/// Chip de filtro animado
class AnimatedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const AnimatedFilterChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

/// Botón que escala al ser presionado
class BounceTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const BounceTapButton({
    Key? key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
  }) : super(key: key);

  @override
  State<BounceTapButton> createState() => _BounceTapButtonState();
}

class _BounceTapButtonState extends State<BounceTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Container con animaciones morphing
class MorphingContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const MorphingContainer({
    Key? key,
    this.child,
    this.margin,
    this.padding,
    this.color,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border:
            borderColor != null
                ? Border.all(color: borderColor!, width: borderWidth)
                : null,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

/// Widget para barra de progreso animada
class AnimatedProgressIndicator extends StatelessWidget {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const AnimatedProgressIndicator({
    Key? key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.height = 12.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: FractionallySizedBox(
            widthFactor: animatedValue,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
              ),
            ),
          ),
        );
      },
    );
  }
}
