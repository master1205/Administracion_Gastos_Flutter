import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'sync_service.dart';

/// Nombres de las tareas programadas
class BackgroundTasks {
  static const int syncMensualTaskId = 1;
  static const int corteSemanalTaskId = 2;
}

/// Callback que se ejecuta en segundo plano para sincronización mensual
@pragma('vm:entry-point')
Future<void> callbackSyncMensual() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("🔄 Ejecutando sincronización mensual automática");
    await _ejecutarSincronizacionMensual();
  } catch (e, stackTrace) {
    print("❌ Error en sync mensual: $e");
    print("Stack trace: $stackTrace");
  }
}

/// Callback que se ejecuta en segundo plano para corte semanal
@pragma('vm:entry-point')
Future<void> callbackCorteSemanal() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("🔄 Ejecutando corte semanal automático");
    await _ejecutarCorteSemanal();
  } catch (e, stackTrace) {
    print("❌ Error en corte semanal: $e");
    print("Stack trace: $stackTrace");
  }
}

/// Ejecuta la sincronización mensual completa
Future<void> _ejecutarSincronizacionMensual() async {
  print("📅 Iniciando sincronización mensual...");

  final syncService = SyncService();

  // Ejecutar sincronización del mes completo
  final resultado = await syncService.sincronizarMesCompleto();

  print("📊 Resultado sincronización:");
  print("   - Exitosas: ${resultado.exitosas}");
  print("   - Fallidas: ${resultado.fallidas}");
  print("   - Duracion: ${resultado.duracion.inSeconds}s");

  if (resultado.mensajesError.isNotEmpty) {
    print("⚠️ Errores encontrados:");
    for (var error in resultado.mensajesError) {
      print("   - $error");
    }
  }
}

/// Ejecuta el corte semanal de transacciones de Supermercado
Future<void> _ejecutarCorteSemanal() async {
  print("📦 Iniciando corte semanal...");

  final syncService = SyncService();

  // Ejecutar corte semanal
  final resultado = await syncService.ejecutarCorteSemanal();

  print("📊 Resultado corte semanal:");
  print("   - Transacciones agrupadas: ${resultado.transaccionesAgrupadas}");
  print("   - Monto total: \$${resultado.montoTotal.toStringAsFixed(2)}");
  print("   - Duracion: ${resultado.duracion.inSeconds}s");

  if (resultado.error != null) {
    print("⚠️ Error: ${resultado.error}");
  }
}

/// Clase para gestionar las tareas programadas
class BackgroundTaskManager {
  /// Inicializa el AndroidAlarmManager
  static Future<void> inicializar() async {
    await AndroidAlarmManager.initialize();
    print("✅ AndroidAlarmManager inicializado");
  }

  /// Registra la tarea de sincronización mensual
  /// Se ejecuta el día 1 de cada mes a las 12:00 AM (medianoche)
  static Future<void> registrarSincronizacionMensual() async {
    final delay = _calcularDelayHastaPrimerDiaMes();

    await AndroidAlarmManager.periodic(
      const Duration(days: 30),
      BackgroundTasks.syncMensualTaskId,
      callbackSyncMensual,
      startAt: DateTime.now().add(delay),
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    print("📅 Tarea mensual registrada");
  }

  /// Registra la tarea de corte semanal
  /// Se ejecuta todos los domingos a las 3:00 AM
  static Future<void> registrarCorteSemanal() async {
    final delay = _calcularDelayHastaDomingo3AM();

    await AndroidAlarmManager.periodic(
      const Duration(days: 7),
      BackgroundTasks.corteSemanalTaskId,
      callbackCorteSemanal,
      startAt: DateTime.now().add(delay),
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    print("📦 Tarea semanal registrada");
  }

  /// Cancela todas las tareas programadas
  static Future<void> cancelarTodasLasTareas() async {
    await AndroidAlarmManager.cancel(BackgroundTasks.syncMensualTaskId);
    await AndroidAlarmManager.cancel(BackgroundTasks.corteSemanalTaskId);
    print("🛑 Todas las tareas canceladas");
  }

  /// Cancela solo la sincronización mensual
  static Future<void> cancelarSincronizacionMensual() async {
    await AndroidAlarmManager.cancel(BackgroundTasks.syncMensualTaskId);
    print("🛑 Tarea mensual cancelada");
  }

  /// Cancela solo el corte semanal
  static Future<void> cancelarCorteSemanal() async {
    await AndroidAlarmManager.cancel(BackgroundTasks.corteSemanalTaskId);
    print("🛑 Tarea semanal cancelada");
  }

  /// Calcula el delay hasta el día 1 del próximo mes a las 12:00 AM
  static Duration _calcularDelayHastaPrimerDiaMes() {
    final ahora = DateTime.now();

    // Si estamos antes del día 1, calcular hasta el día 1 del mes actual
    // Si ya pasó el día 1, calcular hasta el día 1 del próximo mes
    DateTime proximaEjecucion;

    if (ahora.day == 1 && ahora.hour < 1) {
      // Hoy es día 1 y aún no es la 1 AM, ejecutar a medianoche de hoy
      proximaEjecucion = DateTime(ahora.year, ahora.month, 1, 0, 0);
    } else {
      // Ya pasó el día 1, programar para el día 1 del próximo mes
      if (ahora.month == 12) {
        proximaEjecucion = DateTime(ahora.year + 1, 1, 1, 0, 0);
      } else {
        proximaEjecucion = DateTime(ahora.year, ahora.month + 1, 1, 0, 0);
      }
    }

    final delay = proximaEjecucion.difference(ahora);
    print("📅 Próxima sincronización mensual: $proximaEjecucion");
    print("   Delay: ${delay.inHours}h ${delay.inMinutes % 60}m");

    return delay;
  }

  /// Calcula el delay hasta el próximo domingo a las 3:00 AM
  static Duration _calcularDelayHastaDomingo3AM() {
    final ahora = DateTime.now();

    // Calcular días hasta el próximo domingo (weekday: 7 = domingo)
    int diasHastaDomingo = (DateTime.sunday - ahora.weekday) % 7;

    // Si hoy es domingo y aún no son las 3 AM, ejecutar hoy
    DateTime proximaEjecucion;
    if (diasHastaDomingo == 0 && ahora.hour < 3) {
      proximaEjecucion = DateTime(ahora.year, ahora.month, ahora.day, 3, 0);
    } else {
      // Próximo domingo a las 3 AM
      if (diasHastaDomingo == 0) diasHastaDomingo = 7;
      proximaEjecucion = DateTime(
        ahora.year,
        ahora.month,
        ahora.day + diasHastaDomingo,
        3,
        0,
      );
    }

    final delay = proximaEjecucion.difference(ahora);
    print("📦 Próximo corte semanal: $proximaEjecucion");
    print("   Delay: ${delay.inHours}h ${delay.inMinutes % 60}m");

    return delay;
  }

  /// Método de prueba para ejecutar sincronización mensual inmediatamente
  /// Solo para testing
  static Future<void> ejecutarSyncMensualAhora() async {
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 5),
      BackgroundTasks.syncMensualTaskId + 100, // ID diferente para test
      callbackSyncMensual,
      exact: true,
      wakeup: true,
    );
    print("🧪 Tarea de prueba mensual programada (5 segundos)");
  }

  /// Método de prueba para ejecutar corte semanal inmediatamente
  /// Solo para testing
  static Future<void> ejecutarCorteSemanalAhora() async {
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 5),
      BackgroundTasks.corteSemanalTaskId + 100, // ID diferente para test
      callbackCorteSemanal,
      exact: true,
      wakeup: true,
    );
    print("🧪 Tarea de prueba semanal programada (5 segundos)");
  }
}
