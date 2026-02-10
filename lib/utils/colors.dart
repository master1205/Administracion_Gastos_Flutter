import 'package:flutter/material.dart';

/// Sistema de colores inspirado en Cashew
/// Proporciona una paleta completa de colores selectables y funciones helper

// ============================================================================
// 🎨 COLORES SELECTABLES - Palette Completa
// ============================================================================

/// Colores selectables para categorías, cuentas, metas, etc.
/// Basado en el sistema de Cashew con tonos mejorados
extension ColorsDefined on ColorScheme {
  // Rojos y Rosas
  Color get selectableColorRed => Colors.red.shade400;
  Color get selectableColorPink => Colors.pink.shade400;
  Color get selectableColorDeepOrange => Colors.deepOrange.shade400;

  // Naranjas y Amarillos
  Color get selectableColorOrange => Colors.orange.shade400;
  Color get selectableColorAmber => Colors.amber.shade400;
  Color get selectableColorYellow => Colors.yellow.shade400;

  // Verdes
  Color get selectableColorGreen => Colors.green.shade400;
  Color get selectableColorLightGreen => Colors.lightGreen.shade400;
  Color get selectableColorLime => Colors.lime.shade400;

  // Azules y Cianes
  Color get selectableColorCyan => Colors.cyan.shade400;
  Color get selectableColorTeal => Colors.teal.shade400;
  Color get selectableColorBlue => Colors.blue.shade400;
  Color get selectableColorLightBlue => Colors.lightBlue.shade400;

  // Purpuras e Indigos
  Color get selectableColorIndigo => Colors.indigo.shade500;
  Color get selectableColorDeepPurple => Colors.deepPurple.shade400;
  Color get selectableColorPurple => Colors.purple.shade400;

  // Neutros
  Color get selectableColorGrey => Colors.grey.shade400;
  Color get selectableColorBrown => Colors.brown.shade400;
  Color get selectableColorBlueGrey => Colors.blueGrey.shade400;
}

// ============================================================================
// 📊 LISTA DE COLORES SELECTABLES
// ============================================================================

/// Lista completa de colores para categorías (incluye todos los tonos)
List<Color> selectableColors(BuildContext context) {
  return [
    Theme.of(context).colorScheme.selectableColorRed,
    Theme.of(context).colorScheme.selectableColorPink,
    Theme.of(context).colorScheme.selectableColorDeepOrange,
    Theme.of(context).colorScheme.selectableColorOrange,
    Theme.of(context).colorScheme.selectableColorAmber,
    Theme.of(context).colorScheme.selectableColorYellow,
    Theme.of(context).colorScheme.selectableColorLime,
    Theme.of(context).colorScheme.selectableColorLightGreen,
    Theme.of(context).colorScheme.selectableColorGreen,
    Theme.of(context).colorScheme.selectableColorTeal,
    Theme.of(context).colorScheme.selectableColorCyan,
    Theme.of(context).colorScheme.selectableColorLightBlue,
    Theme.of(context).colorScheme.selectableColorBlue,
    Theme.of(context).colorScheme.selectableColorIndigo,
    Theme.of(context).colorScheme.selectableColorDeepPurple,
    Theme.of(context).colorScheme.selectableColorPurple,
    Theme.of(context).colorScheme.selectableColorBrown,
    Theme.of(context).colorScheme.selectableColorGrey,
    Theme.of(context).colorScheme.selectableColorBlueGrey,
  ];
}

/// Lista de colores para el selector de acento (tonos más vibrantes)
List<Color> selectableAccentColors(BuildContext context) {
  return [
    Theme.of(context).colorScheme.selectableColorGreen,
    Theme.of(context).colorScheme.selectableColorCyan,
    Theme.of(context).colorScheme.selectableColorBlue,
    Theme.of(context).colorScheme.selectableColorIndigo,
    Theme.of(context).colorScheme.selectableColorDeepPurple,
    Theme.of(context).colorScheme.selectableColorPurple,
    Theme.of(context).colorScheme.selectableColorRed,
    Theme.of(context).colorScheme.selectableColorOrange,
    Theme.of(context).colorScheme.selectableColorYellow,
  ];
}

// ============================================================================
// 🎨 FUNCIONES HELPER PARA MANIPULACIÓN DE COLORES
// ============================================================================

/// Oscurece un color usando HSL
Color darken(Color color, [double amount = 0.1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}

/// Aclara un color usando HSL
Color lighten(Color color, [double amount = 0.1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslLight.toColor();
}

/// Aclara un color mezclando con blanco (estilo pastel)
Color lightenPastel(Color color, {double amount = 0.1}) {
  return Color.alphaBlend(Colors.white.withOpacity(amount), color);
}

/// Oscurece un color mezclando con negro (estilo pastel)
Color darkenPastel(Color color, {double amount = 0.1}) {
  return Color.alphaBlend(Colors.black.withOpacity(amount), color);
}

/// Mezcla dos colores
Color blend(Color colorToBlend, Color baseColor, {double amount = 0.1}) {
  return Color.alphaBlend(baseColor.withOpacity(amount), colorToBlend);
}

/// Crea un color pastel dinámico según el tema (claro/oscuro)
/// Aclara en modo claro, oscurece en modo oscuro
Color dynamicPastel(
  BuildContext context,
  Color color, {
  double amount = 0.1,
  bool inverse = false,
  double? amountLight,
  double? amountDark,
}) {
  amountLight ??= amount;
  amountDark ??= amount;

  if (amountLight > 1) amountLight = 1;
  if (amountDark > 1) amountDark = 1;
  if (amount > 1) amount = 1;

  if (inverse) {
    if (Theme.of(context).brightness == Brightness.light) {
      return darkenPastel(color, amount: amountDark);
    } else {
      return lightenPastel(color, amount: amountLight);
    }
  } else {
    if (Theme.of(context).brightness == Brightness.light) {
      return lightenPastel(color, amount: amountLight);
    } else {
      return darkenPastel(color, amount: amountDark);
    }
  }
}

// ============================================================================
// 🔧 EXTENSIÓN PARA COLORES PERSONALIZADOS DEL TEMA
// ============================================================================

/// Extensión personalizada del tema para colores adicionales
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.colors});

  final Map<String, Color> colors;

  @override
  AppColors copyWith({Map<String, Color>? colors}) {
    return AppColors(colors: colors ?? this.colors);
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }

    final Map<String, Color> lerpColors = {};
    colors.forEach((key, value) {
      lerpColors[key] = Color.lerp(colors[key], other.colors[key], t) ?? value;
    });

    return AppColors(colors: lerpColors);
  }
}

/// Helper para obtener colores personalizados del tema
Color getColor(BuildContext context, String colorName) {
  return Theme.of(context).extension<AppColors>()?.colors[colorName] ??
      Theme.of(context).colorScheme.primary;
}

/// Obtiene colores personalizados según el tema (sistema Cashew)
AppColors getAppColors({
  required Brightness brightness,
  required Color accentColor,
  required ThemeData themeData,
  required bool materialYou,
}) {
  // Color base para contenedores (igual que Cashew)
  final Color lightDarkAccentHeavyLight;
  if (brightness == Brightness.light) {
    lightDarkAccentHeavyLight =
        materialYou ? lightenPastel(accentColor, amount: 0.92) : Colors.white;
  } else {
    lightDarkAccentHeavyLight =
        materialYou
            ? darkenPastel(accentColor, amount: 0.8)
            : const Color(0xFF242424);
  }

  if (brightness == Brightness.light) {
    return AppColors(
      colors: {
        'white': Colors.white,
        'black': Colors.black,
        'textLight':
            materialYou
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF888888),
        'lightDarkAccent':
            materialYou
                ? lightenPastel(accentColor, amount: 0.6)
                : const Color(0xFFF7F7F7),
        'lightDarkAccentHeavyLight': lightDarkAccentHeavyLight,
        'canvasContainer': const Color(0xFFEBEBEB),
        'lightDarkAccentHeavy': const Color(0xFFEBEBEB),
        'shadowColor': const Color(0x655A5A5A),
        'shadowColorLight': const Color(0x2D5A5A5A),
        'unPaidUpcoming': const Color(0xFF58A4C2),
        'unPaidOverdue': const Color(0xFF6577E0),
        'incomeAmount': const Color(0xFF59A849),
        'expenseAmount': const Color(0xFFCA5A5A),
        'warningOrange': const Color(0xFFCA995A),
        'starYellow': const Color(0xFFFFD723),
        'dividerColor':
            materialYou ? const Color(0x0F000000) : const Color(0xFFF0F0F0),
        'standardContainerColor':
            materialYou
                ? lightenPastel(
                  themeData.colorScheme.secondaryContainer,
                  amount: 0.3,
                )
                : lightDarkAccentHeavyLight,
      },
    );
  } else {
    return AppColors(
      colors: {
        'white': Colors.black,
        'black': Colors.white,
        'textLight':
            materialYou
                ? Colors.white.withValues(alpha: 0.25)
                : const Color(0xFF494949),
        'lightDarkAccent':
            materialYou
                ? darkenPastel(accentColor, amount: 0.83)
                : const Color(0xFF161616),
        'lightDarkAccentHeavyLight': lightDarkAccentHeavyLight,
        'canvasContainer': const Color(0xFF242424),
        'lightDarkAccentHeavy': const Color(0xFF444444),
        'shadowColor': const Color(0x69BDBDBD),
        'shadowColorLight':
            materialYou ? Colors.transparent : const Color(0x28747474),
        'unPaidUpcoming': const Color(0xFF7DB6CC),
        'unPaidOverdue': const Color(0xFF8395FF),
        'incomeAmount': const Color(0xFF62CA77),
        'expenseAmount': const Color(0xFFDA7272),
        'warningOrange': const Color(0xFFDA9C72),
        'starYellow': Colors.yellow,
        'dividerColor':
            materialYou ? const Color(0x13FFFFFF) : const Color(0x6F363636),
        'standardContainerColor':
            materialYou
                ? darkenPastel(
                  themeData.colorScheme.secondaryContainer,
                  amount: 0.6,
                )
                : lightDarkAccentHeavyLight,
      },
    );
  }
}

// ============================================================================
// 🔄 CONVERSIÓN DE COLORES HEX
// ============================================================================

/// Convierte un color a string hexadecimal
String? toHexString(Color? color) {
  if (color == null) return null;
  String valueString = color.value.toRadixString(16);
  return '0x$valueString';
}

/// Clase para crear colores desde strings hexadecimales
class HexColor extends Color {
  static int _getColorFromHex(String? hexColor, Color? defaultColor) {
    try {
      if (hexColor == null) {
        return defaultColor?.value ?? Colors.grey.value;
      }
      hexColor = hexColor.replaceAll('#', '').replaceAll('0x', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return int.parse(hexColor, radix: 16);
    } catch (e) {
      return defaultColor?.value ?? Colors.grey.value;
    }
  }

  HexColor(final String? hexColor, {final Color? defaultColor})
    : super(_getColorFromHex(hexColor, defaultColor));
}

// ============================================================================
// 📱 COLORES ESPECIALES PARA ESTADOS
// ============================================================================

/// Colores para diferentes tipos de transacciones
class TransactionColors {
  static const Color income = Color(0xFF59A849);
  static const Color expense = Color(0xFFCA5A5A);
  static const Color transfer = Color(0xFF58A4C2);

  static const Color incomeLight = Color(0xFF7BC96D);
  static const Color expenseLight = Color(0xFFE67676);
  static const Color transferLight = Color(0xFF7DB6CC);

  static const Color incomeDark = Color(0xFF62CA77);
  static const Color expenseDark = Color(0xFFDA7272);
  static const Color transferDark = Color(0xFF8BC9E8);
}

/// Colores para estados de pagos
class PaymentColors {
  static const Color upcoming = Color(0xFF58A4C2);
  static const Color overdue = Color(0xFF6577E0);
  static const Color paid = Color(0xFF59A849);

  static const Color upcomingLight = Color(0xFF7DB6CC);
  static const Color overdueLight = Color(0xFF8395FF);
  static const Color paidLight = Color(0xFF7BC96D);

  static const Color upcomingDark = Color(0xFF8BC9E8);
  static const Color overdueDark = Color(0xFFA0ADFF);
  static const Color paidDark = Color(0xFF62CA77);
}

/// Colores para alertas y estados
class StatusColors {
  static const Color warning = Color(0xFFCA995A);
  static const Color warningLight = Color(0xFFE6B47B);
  static const Color warningDark = Color(0xFFDA9C72);

  static const Color success = Color(0xFF59A849);
  static const Color successLight = Color(0xFF7BC96D);
  static const Color successDark = Color(0xFF62CA77);

  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFF6B6B);
  static const Color errorDark = Color(0xFFDA7272);

  static const Color info = Color(0xFF58A4C2);
  static const Color infoLight = Color(0xFF7DB6CC);
  static const Color infoDark = Color(0xFF8BC9E8);
}

// ============================================================================
// 🎯 COLORES DE GRADIENTE
// ============================================================================

/// Gradientes predefinidos para UI
class AppGradients {
  /// Gradiente principal (morado-azul)
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente secundario (verde-cyan)
  static const LinearGradient secondary = LinearGradient(
    colors: [Color(0xFF48c9b0), Color(0xFF2ecc71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente de ingreso
  static const LinearGradient income = LinearGradient(
    colors: [Color(0xFF59A849), Color(0xFF7BC96D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente de gasto
  static const LinearGradient expense = LinearGradient(
    colors: [Color(0xFFCA5A5A), Color(0xFFE67676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente suave (para fondos)
  static LinearGradient soft(Color color) => LinearGradient(
    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradiente con contexto de tema
  static LinearGradient dynamicPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return LinearGradient(
      colors:
          isDark
              ? [darken(primary, 0.1), darken(secondary, 0.1)]
              : [lighten(primary, 0.1), lighten(secondary, 0.1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// ============================================================================
// 🎨 HELPER PARA SOMBRAS
// ============================================================================

/// Sombras personalizadas para diferentes contextos
class AppShadows {
  /// Sombra general para cards
  static List<BoxShadow> cardShadow(BuildContext context) {
    final shadow = Theme.of(context).colorScheme.shadow;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: shadow.withValues(alpha: isDark ? 0.3 : 0.08),
        blurRadius: isDark ? 12 : 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Sombra ligera
  static List<BoxShadow> lightShadow(BuildContext context) {
    final shadow = Theme.of(context).colorScheme.shadow;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: shadow.withValues(alpha: isDark ? 0.2 : 0.04),
        blurRadius: isDark ? 8 : 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// Sombra fuerte (para elementos elevados)
  static List<BoxShadow> strongShadow(BuildContext context) {
    final shadow = Theme.of(context).colorScheme.shadow;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: shadow.withValues(alpha: isDark ? 0.5 : 0.15),
        blurRadius: isDark ? 20 : 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
