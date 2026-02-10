import 'package:flutter/services.dart';

/// Utilidades centralizadas de haptic feedback.
/// Uso: `Haptics.light()`, `Haptics.medium()`, `Haptics.heavy()`, `Haptics.selection()`
class Haptics {
  Haptics._();

  /// Feedback ligero — selección de chips, toggles, cambio de tabs
  static void light() => HapticFeedback.lightImpact();

  /// Feedback medio — acciones exitosas, guardar, confirmar
  static void medium() => HapticFeedback.mediumImpact();

  /// Feedback fuerte — eliminar, error, acciones destructivas
  static void heavy() => HapticFeedback.heavyImpact();

  /// Feedback de selección — navegar, scroll snaps
  static void selection() => HapticFeedback.selectionClick();

  /// Vibración corta — notificaciones, alertas
  static void vibrate() => HapticFeedback.vibrate();
}
