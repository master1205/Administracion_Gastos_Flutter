import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sa3_liquid/sa3_liquid.dart';
import 'dart:math';

/// Widget que crea un fondo animado con efecto de plasma/líquido
/// Similar al efecto usado en Cashew app
class AnimatedGooBackground extends StatelessWidget {
  const AnimatedGooBackground({
    Key? key,
    required this.color,
    this.randomOffset = 1,
    this.enableAnimation = true,
  }) : super(key: key);

  final Color color;
  final int randomOffset;
  final bool enableAnimation;

  @override
  Widget build(BuildContext context) {
    // Si las animaciones están desactivadas o es web, usa color sólido
    if (!enableAnimation || kIsWeb) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
          ),
        ),
      );
    }

    final isLight = Theme.of(context).brightness == Brightness.light;

    // Transform para evitar artefactos gráficos
    return Transform(
      transform: Matrix4.skewX(0.001),
      child: Container(
        decoration: BoxDecoration(
          // Fondo con tinte del color para que los blancos no dominen
          color:
              isLight
                  ? Color.lerp(color, Colors.white, 0.65)!
                  : Colors.black.withOpacity(0.3),
        ),
        child: PlasmaRenderer(
          type: PlasmaType.infinity,
          particles: 10,
          color: isLight ? color.withOpacity(0.2) : color.withOpacity(0.25),
          blur: 0.35,
          size: 1.4,
          speed: 2.8,
          offset: 0,
          blendMode: BlendMode.plus,
          particleType: ParticleType.atlas,
          variation1: 0,
          variation2: 0,
          variation3: 0,
          rotation: _getRotation(randomOffset),
        ),
      ),
    );
  }

  double _getRotation(int offset) {
    final random = Random(offset);
    return random.nextDouble() * 2 * pi;
  }
}
