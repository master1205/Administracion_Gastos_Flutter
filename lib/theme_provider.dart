import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/colors.dart';

/// Sistema de temas idéntico a Cashew:
/// - ColorScheme.fromSeed() sin modificar primary (M3 puro)
/// - Solo override: background (tintado con accent si materialYou=true)
/// - Detecta accents grises y usa scheme manual
/// - Material You toggle para fondos/superficies tintadas
/// - textTheme centralizado vía GoogleFonts
class ThemeManager extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  bool _materialYou = true;
  bool get materialYou => _materialYou;

  Color _accentColor = const Color(0xFF667eea);
  Color get accentColor => _accentColor;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _materialYou = prefs.getBool('materialYou') ?? true;

    final savedColorHex = prefs.getString('accentColor');
    if (savedColorHex != null) {
      _accentColor = HexColor(savedColorHex);
    }

    notifyListeners();
    _updateSystemUI();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
    _updateSystemUI();
  }

  Future<void> toggleMaterialYou() async {
    final prefs = await SharedPreferences.getInstance();
    _materialYou = !_materialYou;
    await prefs.setBool('materialYou', _materialYou);
    notifyListeners();
    _updateSystemUI();
  }

  Future<void> setAccentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    _accentColor = color;
    await prefs.setString('accentColor', toHexString(color) ?? '0xFF667eea');
    notifyListeners();
    _updateSystemUI();
  }

  void _updateSystemUI() {
    final colorScheme = themeData.colorScheme;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
        statusBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  // ============================================================================
  // COLORSCHEME — Idéntico a Cashew
  // ============================================================================

  /// Detecta si el color es gris/neutro (M3 genera schemes feos con grises)
  bool _isGrayScale(Color color, {int threshold = 15}) {
    return (color.red - color.green).abs() <= threshold &&
        (color.red - color.blue).abs() <= threshold &&
        (color.green - color.blue).abs() <= threshold;
  }

  /// Genera un ColorScheme manual para accents grises (igual que Cashew)
  ColorScheme _getGrayScaleColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return ColorScheme.light(
        primary: Colors.blueGrey.shade700,
        onPrimary: Colors.white,
        primaryContainer: Colors.blueGrey.shade100,
        onPrimaryContainer: Colors.blueGrey.shade900,
        secondary: Colors.blueGrey.shade500,
        onSecondary: Colors.white,
        secondaryContainer: Colors.blueGrey.shade50,
        onSecondaryContainer: Colors.blueGrey.shade800,
        surface:
            _materialYou
                ? lightenPastel(Colors.blueGrey.shade200, amount: 0.85)
                : Colors.white,
        onSurface: Colors.grey.shade900,
        error: Colors.red.shade700,
        onError: Colors.white,
        outline: Colors.grey.shade400,
        outlineVariant: Colors.grey.shade200,
        shadow: Colors.black,
      );
    } else {
      return ColorScheme.dark(
        primary: Colors.blueGrey.shade300,
        onPrimary: Colors.black87,
        primaryContainer: Colors.blueGrey.shade800,
        onPrimaryContainer: Colors.blueGrey.shade100,
        secondary: Colors.blueGrey.shade400,
        onSecondary: Colors.black87,
        secondaryContainer: Colors.blueGrey.shade700,
        onSecondaryContainer: Colors.blueGrey.shade200,
        surface:
            _materialYou
                ? darkenPastel(Colors.blueGrey.shade800, amount: 0.7)
                : Colors.black,
        onSurface: Colors.grey.shade200,
        error: Colors.red.shade300,
        onError: Colors.black87,
        outline: Colors.grey.shade600,
        outlineVariant: Colors.grey.shade700,
        shadow: Colors.black,
      );
    }
  }

  /// Genera ColorScheme exactamente como Cashew:
  /// - Sin tocar primary (M3 puro)
  /// - Solo override de background/surface según materialYou
  /// - Grayscale fallback para accents neutros
  ColorScheme _getColorScheme(Brightness brightness) {
    // Accents grises → scheme manual (Cashew pattern)
    if (_isGrayScale(_accentColor)) {
      return _getGrayScaleColorScheme(brightness);
    }

    if (brightness == Brightness.light) {
      return ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: Brightness.light,
        surface:
            _materialYou
                ? lightenPastel(_accentColor, amount: 0.91)
                : Colors.white,
      );
    } else {
      return ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: Brightness.dark,
        surface:
            _materialYou
                ? darkenPastel(_accentColor, amount: 0.92)
                : Colors.black,
      );
    }
  }

  // ============================================================================
  // TEXTTHEME — Centralizado (elimina 566 GoogleFonts inline)
  // ============================================================================
  TextTheme _getTextTheme(Brightness brightness) {
    // Fuente base: Lato (la más usada en el proyecto)
    // Poppins para títulos/headings
    // Pasar la tipografía correcta para que los colores adapten a light/dark
    final base =
        brightness == Brightness.light
            ? Typography.material2021().black
            : Typography.material2021().white;
    final baseTextTheme = GoogleFonts.latoTextTheme(base);
    final poppins = GoogleFonts.poppinsTextTheme(base);

    return baseTextTheme.copyWith(
      // Display
      displayLarge: poppins.displayLarge,
      displayMedium: poppins.displayMedium,
      displaySmall: poppins.displaySmall,
      // Headlines
      headlineLarge: poppins.headlineLarge,
      headlineMedium: poppins.headlineMedium,
      headlineSmall: poppins.headlineSmall,
      // Titles
      titleLarge: poppins.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: poppins.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: poppins.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      // Body (Lato — inherited from base)
      // Labels
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium,
      labelSmall: baseTextTheme.labelSmall,
    );
  }

  // ============================================================================
  // LIGHT THEME — Sistema Cashew
  // ============================================================================
  ThemeData get lightTheme {
    final colorScheme = _getColorScheme(Brightness.light);

    // Splash color tintado como Cashew (materialYou)
    final splashColor =
        _materialYou
            ? darkenPastel(
              lightenPastel(_accentColor, amount: 0.8),
              amount: 0.2,
            ).withValues(alpha: 0.5)
            : null;

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _getTextTheme(Brightness.light),
      typography: Typography.material2021(),
      splashColor: splashColor,
    );

    final appColors = getAppColors(
      brightness: Brightness.light,
      accentColor: _accentColor,
      themeData: baseTheme,
      materialYou: _materialYou,
    );

    return baseTheme.copyWith(
      extensions: [appColors],

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: _getTextTheme(
          Brightness.light,
        ).titleLarge?.copyWith(color: colorScheme.onSurface, fontSize: 20),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.secondary.withOpacity(0.15),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.secondary.withOpacity(0.15),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================================
  // DARK THEME — Sistema Cashew
  // ============================================================================
  ThemeData get darkTheme {
    final colorScheme = _getColorScheme(Brightness.dark);

    // Splash color tintado como Cashew (materialYou)
    final splashColor =
        _materialYou
            ? darkenPastel(
              lightenPastel(_accentColor, amount: 0.86),
              amount: 0.1,
            ).withValues(alpha: 0.2)
            : null;

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _getTextTheme(Brightness.dark),
      typography: Typography.material2021(),
      splashColor: splashColor,
    );

    final appColors = getAppColors(
      brightness: Brightness.dark,
      accentColor: _accentColor,
      themeData: baseTheme,
      materialYou: _materialYou,
    );

    return baseTheme.copyWith(
      extensions: [appColors],

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: _getTextTheme(
          Brightness.dark,
        ).titleLarge?.copyWith(color: colorScheme.onSurface, fontSize: 20),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.secondary.withOpacity(0.15),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.secondary.withOpacity(0.15),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  ColorScheme get colorScheme => themeData.colorScheme;

  Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
