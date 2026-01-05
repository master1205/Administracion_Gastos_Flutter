import 'package:flutter/material.dart';

/// Iconos personalizados para categorías de transacciones

class CategoryIcons {
  CategoryIcons._();

  // ========== ICONOS POR CATEGORÍA ==========

  static const Map<String, IconData> categoryIconMap = {
    // Gastos comunes
    'Alimentos': Icons.restaurant_rounded,
    'Comida': Icons.fastfood_rounded,
    'Supermercado': Icons.shopping_cart_rounded,
    'Mercado': Icons.local_grocery_store_rounded,

    // Transporte
    'Transporte': Icons.directions_car_rounded,
    'Gasolina': Icons.local_gas_station_rounded,
    'Uber': Icons.local_taxi_rounded,
    'Taxi': Icons.local_taxi_rounded,

    // Entretenimiento
    'Entretenimiento': Icons.movie_rounded,
    'Cine': Icons.theaters_rounded,
    'Streaming': Icons.play_circle_filled_rounded,
    'Videojuegos': Icons.sports_esports_rounded,

    // Servicios
    'Internet': Icons.wifi_rounded,
    'Teléfono': Icons.phone_android_rounded,
    'Luz': Icons.lightbulb_rounded,
    'Agua': Icons.water_drop_rounded,
    'Gas': Icons.propane_tank_rounded,

    // Salud
    'Salud': Icons.local_hospital_rounded,
    'Médico': Icons.medical_services_rounded,
    'Farmacia': Icons.local_pharmacy_rounded,
    'Gym': Icons.fitness_center_rounded,

    // Educación
    'Educación': Icons.school_rounded,
    'Libros': Icons.book_rounded,
    'Cursos': Icons.class_rounded,

    // Otros
    'Ropa': Icons.checkroom_rounded,
    'Casa': Icons.home_rounded,
    'Renta': Icons.key_rounded,
    'Ahorro': Icons.savings_rounded,
    'Regalo': Icons.card_giftcard_rounded,
    'Mascota': Icons.pets_rounded,
    'Viaje': Icons.flight_rounded,

    // Tipos de transacción
    'Gastos': Icons.trending_down_rounded,
    'Ingresos': Icons.trending_up_rounded,
    'Pagos': Icons.monetization_on_rounded,
    'Traspasos': Icons.swap_horiz_rounded,
    'Reembolsos': Icons.restore_rounded,
  };

  // ========== COLORES POR CATEGORÍA ==========

  static const Map<String, Color> categoryColorMap = {
    // Gastos comunes
    'Alimentos': Color(0xFFFF6B6B),
    'Comida': Color(0xFFFF8C42),
    'Supermercado': Color(0xFF4ECDC4),
    'Mercado': Color(0xFF45B7D1),

    // Transporte
    'Transporte': Color(0xFF5F27CD),
    'Gasolina': Color(0xFF341F97),
    'Uber': Color(0xFF000000),
    'Taxi': Color(0xFFFFCA28),

    // Entretenimiento
    'Entretenimiento': Color(0xFFE056FD),
    'Cine': Color(0xFF8E44AD),
    'Streaming': Color(0xFFE74C3C),
    'Videojuegos': Color(0xFF2ECC71),

    // Servicios
    'Internet': Color(0xFF3498DB),
    'Teléfono': Color(0xFF1ABC9C),
    'Luz': Color(0xFFF39C12),
    'Agua': Color(0xFF3498DB),
    'Gas': Color(0xFFE67E22),

    // Salud
    'Salud': Color(0xFF27AE60),
    'Médico': Color(0xFF16A085),
    'Farmacia': Color(0xFF2ECC71),
    'Gym': Color(0xFFE74C3C),

    // Educación
    'Educación': Color(0xFF9B59B6),
    'Libros': Color(0xFF8E44AD),
    'Cursos': Color(0xFF3498DB),

    // Otros
    'Ropa': Color(0xFFE91E63),
    'Casa': Color(0xFF795548),
    'Renta': Color(0xFF607D8B),
    'Ahorro': Color(0xFF4CAF50),
    'Regalo': Color(0xFFFF5722),
    'Mascota': Color(0xFF795548),
    'Viaje': Color(0xFF00BCD4),

    // Tipos de transacción
    'Gastos': Color(0xFFE74C3C),
    'Ingresos': Color(0xFF2ECC71),
    'Pagos': Color(0xFFFF9800),
    'Traspasos': Color(0xFF3498DB),
    'Reembolsos': Color(0xFF9C27B0),
  };

  // ========== MÉTODOS AUXILIARES ==========

  /// Obtiene el icono para una categoría
  static IconData getIcon(String category, {IconData? defaultIcon}) {
    return categoryIconMap[category] ??
        defaultIcon ??
        Icons.attach_money_rounded;
  }

  /// Obtiene el color para una categoría
  static Color getColor(String category, {Color? defaultColor}) {
    return categoryColorMap[category] ?? defaultColor ?? Colors.grey;
  }

  /// Obtiene icono y color juntos
  static (IconData, Color) getIconAndColor(
    String category, {
    IconData? defaultIcon,
    Color? defaultColor,
  }) {
    return (
      getIcon(category, defaultIcon: defaultIcon),
      getColor(category, defaultColor: defaultColor),
    );
  }

  /// Widget de icono de categoría con fondo circular
  static Widget buildCategoryIcon({
    required String category,
    double size = 40,
    double iconSize = 24,
    bool withShadow = false,
  }) {
    final (icon, color) = getIconAndColor(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow:
            withShadow
                ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
