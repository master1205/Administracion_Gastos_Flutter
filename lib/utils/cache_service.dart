import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de caché para optimizar consultas al backend
class CacheService {
  // Duraciones de caché por tipo de dato
  static const Duration CACHE_DURATION_SHORT = Duration(minutes: 1);
  static const Duration CACHE_DURATION_MEDIUM = Duration(minutes: 5);
  static const Duration CACHE_DURATION_LONG = Duration(minutes: 15);

  /// Obtiene un valor del caché
  static Future<T?> get<T>(
    String key,
    T Function(dynamic) fromJson, {
    Duration? maxAge,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      final timestamp = prefs.getInt('${key}_timestamp');

      if (cached != null && timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAgeMs = (maxAge ?? CACHE_DURATION_MEDIUM).inMilliseconds;

        if (age < maxAgeMs) {
          print(
            '📦 Cache HIT: $key (edad: ${(age / 1000).toStringAsFixed(1)}s)',
          );
          return fromJson(jsonDecode(cached));
        } else {
          print(
            '⏰ Cache EXPIRED: $key (edad: ${(age / 1000).toStringAsFixed(1)}s)',
          );
        }
      }

      print('❌ Cache MISS: $key');
      return null;
    } catch (e) {
      print('⚠️ Error al leer caché para $key: $e');
      return null;
    }
  }

  /// Guarda un valor en el caché
  static Future<void> set<T>(String key, T data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      await prefs.setInt(
        '${key}_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      print('💾 Cache SET: $key');
    } catch (e) {
      print('⚠️ Error al guardar caché para $key: $e');
    }
  }

  /// Invalida (elimina) una entrada específica del caché
  static Future<void> invalidate(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
      print('🗑️ Cache INVALIDATED: $key');
    } catch (e) {
      print('⚠️ Error al invalidar caché para $key: $e');
    }
  }

  /// Invalida múltiples entradas relacionadas
  static Future<void> invalidateMultiple(List<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in keys) {
        await prefs.remove(key);
        await prefs.remove('${key}_timestamp');
      }
      print('🗑️ Cache INVALIDATED: ${keys.join(", ")}');
    } catch (e) {
      print('⚠️ Error al invalidar múltiples cachés: $e');
    }
  }

  /// Limpia todo el caché
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => !key.endsWith('_timestamp'));

      for (final key in keys) {
        await prefs.remove(key);
        await prefs.remove('${key}_timestamp');
      }
      print('🗑️ Cache CLEARED ALL');
    } catch (e) {
      print('⚠️ Error al limpiar todo el caché: $e');
    }
  }

  /// Verifica si una entrada del caché está vigente
  static Future<bool> isValid(String key, {Duration? maxAge}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${key}_timestamp');

      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAgeMs = (maxAge ?? CACHE_DURATION_MEDIUM).inMilliseconds;
        return age < maxAgeMs;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la edad del caché en segundos
  static Future<int?> getCacheAge(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${key}_timestamp');

      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        return (age / 1000).round();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Claves de caché predefinidas
  static const String KEY_METAS = 'metas';
  static const String KEY_CUENTAS = 'cuentas';
  static const String KEY_TRANSACCIONES = 'transacciones';
  static const String KEY_CATEGORIAS = 'categorias';
  static const String KEY_DASHBOARD = 'dashboard_data';
  static const String KEY_GASTOS_CATEGORIA = 'gastos_categoria';
}
