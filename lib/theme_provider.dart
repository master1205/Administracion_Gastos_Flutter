import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode; // Alterna el valor actual
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        headlineLarge: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: Colors.black,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Gradientes según el tipo de transacción, con tonos más cálidos en modo oscuro.
  List<Color> getGradientForTransaction(String type) {
    if (_isDarkMode) {
      switch (type) {
        case 'Reembolsos':
          return [
            Colors.deepOrange.shade700.withOpacity(0.8),
            Colors.deepOrange.shade400.withOpacity(0.8),
          ];
        case 'Pagos':
          return [
            Colors.deepOrange.shade800.withOpacity(0.8),
            Colors.deepOrange.shade600.withOpacity(0.8),
          ];
        case 'Traspasos':
          return [
            Colors.blue.shade700.withOpacity(0.8),
            Colors.blue.shade500.withOpacity(0.8),
          ];
        case 'Ingresos':
          return [
            Colors.lightGreen.shade700.withOpacity(0.8),
            Colors.lightGreen.shade500.withOpacity(0.8),
          ];
        case 'Gastos':
          return [
            Colors.red.shade800.withOpacity(0.8),
            Colors.red.shade600.withOpacity(0.8),
          ];
        default:
          return [
            Colors.brown.shade800.withOpacity(0.8),
            Colors.brown.shade600.withOpacity(0.8),
          ];
      }
    } else {
      switch (type) {
        case 'Reembolsos':
          return [Colors.purple.shade100, Colors.purple.shade50];
        case 'Pagos':
          return [Colors.orange.shade100, Colors.orange.shade50];
        case 'Traspasos':
          return [Colors.blue.shade100, Colors.blue.shade50];
        case 'Ingresos':
          return [Colors.green.shade100, Colors.green.shade50];
        case 'Gastos':
          return [Colors.red.shade100, Colors.red.shade50];
        default:
          return [Colors.grey.shade100, Colors.grey.shade50];
      }
    }
  }

  // Color de cada tipo según el tema, con menos intensidad en modo oscuro.
  Color getColorForType(String type) {
    if (_isDarkMode) {
      switch (type) {
        case 'Reembolsos':
          return Colors.deepOrange.withOpacity(0.8);
        case 'Pagos':
          return Colors.deepOrange.withOpacity(0.8);
        case 'Traspasos':
          return Colors.blue.withOpacity(0.8);
        case 'Ingresos':
          return Colors.lightGreen.withOpacity(0.8);
        case 'Gastos':
          return Colors.red.withOpacity(0.8);
        default:
          return Colors.white.withOpacity(0.8);
      }
    } else {
      switch (type) {
        case 'Reembolsos':
          return Colors.purple;
        case 'Pagos':
          return Colors.orange;
        case 'Traspasos':
          return Colors.blue;
        case 'Ingresos':
          return Colors.green;
        case 'Gastos':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }
  }
}
