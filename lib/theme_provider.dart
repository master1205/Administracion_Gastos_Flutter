import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // ============================================================================
  // PALETA DE COLORES MEJORADA - Material Design 3
  // ============================================================================

  // 🎨 MODO CLARO
  static const Color _lightBackground = Color(0xFFFAFBFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFF5F7FA);
  static const Color _lightPrimary = Color(0xFF667eea);
  static const Color _lightPrimaryVariant = Color(0xFF764ba2);
  static const Color _lightSecondary = Color(0xFF48c9b0);
  static const Color _lightError = Color(0xFFE74C3C);
  static const Color _lightOnSurface = Color(0xFF2D3436);
  static const Color _lightTextPrimary = Color(0xFF2D3436);
  static const Color _lightTextSecondary = Color(0xFF636E72);
  static const Color _lightDivider = Color(0xFFE8EBED);
  static const Color _lightCardShadow = Color(0x0F000000);

  // 🌙 MODO OSCURO - Tonos menos intensos para reducir fatiga visual
  static const Color _darkBackground = Color(0xFF0F1419);
  static const Color _darkSurface = Color(0xFF1A1F25);
  static const Color _darkSurfaceVariant = Color(0xFF252B33);
  static const Color _darkPrimary = Color(0xFF7C94F5);
  static const Color _darkPrimaryVariant = Color(0xFF9B7DC4);
  static const Color _darkSecondary = Color(0xFF5DD9C1);
  static const Color _darkError = Color(0xFFFF6B6B);
  static const Color _darkOnSurface = Color(0xFFDDE2E8);
  static const Color _darkTextPrimary = Color(0xFFE8EBED);
  static const Color _darkTextSecondary = Color(0xFFB2B9C0);
  static const Color _darkDivider = Color(0xFF2D3540);
  static const Color _darkCardShadow = Color(0x1A000000);

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
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

  // Actualizar UI del sistema (status bar, navigation bar)
  void _updateSystemUI() {
    if (_isDarkMode) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: _darkSurface,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: _lightSurface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Colores principales
      primaryColor: _lightPrimary,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightSecondary,
        error: _lightError,
        surface: _lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: _lightOnSurface,
        outline: _lightDivider,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shadowColor: _lightCardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _lightTextPrimary),
        titleTextStyle: TextStyle(
          color: _lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(color: _lightDivider, thickness: 1),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _lightTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: _lightTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: _lightTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: _lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: _lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: _lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: _lightTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: _lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: _lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: _lightTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: _lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: _lightTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: _lightTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Colores principales
      primaryColor: _darkPrimary,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary,
        error: _darkError,
        surface: _darkSurface,
        onPrimary: _darkBackground,
        onSecondary: _darkBackground,
        onError: Colors.white,
        onSurface: _darkOnSurface,
        outline: _darkDivider,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shadowColor: _darkCardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _darkTextPrimary),
        titleTextStyle: TextStyle(
          color: _darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(color: _darkDivider, thickness: 1),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _darkTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: _darkTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: _darkTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: _darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: _darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: _darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: _darkTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: _darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: _darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: _darkTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: _darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: _darkTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: _darkTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================================
  // COLORES PARA TIPOS DE TRANSACCIONES
  // ============================================================================

  // Gradientes optimizados para cada tipo de transacción
  List<Color> getGradientForTransaction(String type) {
    if (_isDarkMode) {
      switch (type) {
        case 'Reembolsos':
          return [
            const Color(0xFF9D4EDD).withValues(alpha: 0.7),
            const Color(0xFF7B2CBF).withValues(alpha: 0.7),
          ];
        case 'Pagos':
          return [
            const Color(0xFFFF9A00).withValues(alpha: 0.7),
            const Color(0xFFFF7A00).withValues(alpha: 0.7),
          ];
        case 'Traspasos':
          return [
            const Color(0xFF4895EF).withValues(alpha: 0.7),
            const Color(0xFF3A7BD5).withValues(alpha: 0.7),
          ];
        case 'Ingresos':
          return [
            const Color(0xFF06D6A0).withValues(alpha: 0.7),
            const Color(0xFF05A880).withValues(alpha: 0.7),
          ];
        case 'Gastos':
          return [
            const Color(0xFFEF476F).withValues(alpha: 0.7),
            const Color(0xFFD62B5C).withValues(alpha: 0.7),
          ];
        default:
          return [
            const Color(0xFF9CA3AF).withValues(alpha: 0.7),
            const Color(0xFF6B7280).withValues(alpha: 0.7),
          ];
      }
    } else {
      switch (type) {
        case 'Reembolsos':
          return [const Color(0xFFF3E5FF), const Color(0xFFE8D4FF)];
        case 'Pagos':
          return [const Color(0xFFFFE8D0), const Color(0xFFFFD8B0)];
        case 'Traspasos':
          return [const Color(0xFFD8EEFF), const Color(0xFFC0E0FF)];
        case 'Ingresos':
          return [const Color(0xFFD0F5E9), const Color(0xFFB8F0DD)];
        case 'Gastos':
          return [const Color(0xFFFFE0E6), const Color(0xFFFFD0DB)];
        default:
          return [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)];
      }
    }
  }

  // Color principal para cada tipo de transacción
  Color getColorForType(String type) {
    if (_isDarkMode) {
      switch (type) {
        case 'Reembolsos':
          return const Color(0xFF9D4EDD);
        case 'Pagos':
          return const Color(0xFFFF9A00);
        case 'Traspasos':
          return const Color(0xFF4895EF);
        case 'Ingresos':
          return const Color(0xFF06D6A0);
        case 'Gastos':
          return const Color(0xFFEF476F);
        default:
          return const Color(0xFF9CA3AF);
      }
    } else {
      switch (type) {
        case 'Reembolsos':
          return const Color(0xFF7B2CBF);
        case 'Pagos':
          return const Color(0xFFFF8500);
        case 'Traspasos':
          return const Color(0xFF3A7BD5);
        case 'Ingresos':
          return const Color(0xFF05A880);
        case 'Gastos':
          return const Color(0xFFD62B5C);
        default:
          return const Color(0xFF6B7280);
      }
    }
  }

  // ============================================================================
  // COLORES AUXILIARES PARA UI
  // ============================================================================

  // Color de superficie (para cards, modals, etc.)
  Color get surfaceColor => _isDarkMode ? _darkSurface : _lightSurface;

  // Color de superficie variante (para backgrounds secundarios)
  Color get surfaceVariant =>
      _isDarkMode ? _darkSurfaceVariant : _lightSurfaceVariant;

  // Color de texto primario
  Color get textPrimary => _isDarkMode ? _darkTextPrimary : _lightTextPrimary;

  // Color de texto secundario
  Color get textSecondary =>
      _isDarkMode ? _darkTextSecondary : _lightTextSecondary;

  // Color del divider
  Color get dividerColor => _isDarkMode ? _darkDivider : _lightDivider;

  // Color de sombra para cards
  Color get cardShadow => _isDarkMode ? _darkCardShadow : _lightCardShadow;

  // Color primario
  Color get primaryColor => _isDarkMode ? _darkPrimary : _lightPrimary;

  // Color primario variante
  Color get primaryVariant =>
      _isDarkMode ? _darkPrimaryVariant : _lightPrimaryVariant;

  // Color secundario
  Color get secondaryColor => _isDarkMode ? _darkSecondary : _lightSecondary;

  // Color de error
  Color get errorColor => _isDarkMode ? _darkError : _lightError;

  // Color de éxito
  Color get successColor =>
      _isDarkMode ? const Color(0xFF06D6A0) : const Color(0xFF05A880);

  // Color de advertencia
  Color get warningColor =>
      _isDarkMode ? const Color(0xFFFFC43D) : const Color(0xFFFF9800);

  // Color de información
  Color get infoColor =>
      _isDarkMode ? const Color(0xFF4895EF) : const Color(0xFF3A7BD5);

  // ============================================================================
  // GRADIENTES ESPECIALES
  // ============================================================================

  // Gradiente principal de la app
  LinearGradient get primaryGradient => LinearGradient(
    colors:
        _isDarkMode
            ? [_darkPrimary, _darkPrimaryVariant]
            : [_lightPrimary, _lightPrimaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradiente para headers
  LinearGradient get headerGradient => LinearGradient(
    colors:
        _isDarkMode
            ? [const Color(0xFF252B33), const Color(0xFF1A1F25)]
            : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Gradiente para FAB
  LinearGradient get fabGradient => LinearGradient(
    colors:
        _isDarkMode
            ? [const Color(0xFF7C94F5), const Color(0xFF9B7DC4)]
            : [const Color(0xFF667eea), const Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
