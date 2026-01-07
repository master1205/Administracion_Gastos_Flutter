import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/services/firestore_service.dart';

/// Servicio de sincronización Firebase → Google Sheets
class SyncService {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String defaultUserId = 'default_user';
  static const int batchSize = 50;

  // ==================== SINCRONIZACIÓN MANUAL ====================

  /// Sincroniza todas las transacciones pendientes con Google Sheets
  /// NOTA: Este método ya no se usa en automático, solo para pruebas manuales
  Future<SyncResult> sincronizarTransacciones() async {
    try {
      print('🔄 Iniciando sincronización con Google Sheets...');

      // Obtener transacciones no sincronizadas
      final transacciones =
          await _firestoreService.obtenerTransaccionesNoSincronizadas();

      if (transacciones.isEmpty) {
        print('✅ No hay transacciones pendientes de sincronizar');
        return SyncResult(
          success: true,
          sincronizadas: 0,
          errores: 0,
          mensaje: 'No hay transacciones pendientes',
        );
      }

      print('📤 Enviando ${transacciones.length} transacciones a Sheets...');

      int sincronizadas = 0;
      int errores = 0;
      final List<String> mensajesError = [];

      // Enviar cada transacción a Sheets
      for (var transaccion in transacciones) {
        try {
          // Enviar a Google Sheets
          await _apiService.enviarTransaccionASheets(transaccion);

          // Marcar como sincronizada
          await _firestoreService.marcarComoSincronizado(
            transaccion.idTransaccion,
          );
          sincronizadas++;

          print('✅ Sincronizada: ${transaccion.descripcion}');
        } catch (e) {
          errores++;
          final mensaje = 'Error en ${transaccion.descripcion}: $e';
          mensajesError.add(mensaje);
          print('❌ $mensaje');
        }
      }

      print(
        '🎉 Sincronización completada: $sincronizadas exitosas, $errores errores',
      );

      return SyncResult(
        success: errores == 0,
        sincronizadas: sincronizadas,
        errores: errores,
        mensaje: 'Sincronizadas: $sincronizadas | Errores: $errores',
        mensajesError: mensajesError,
      );
    } catch (e) {
      print('❌ Error general en sincronización: $e');
      return SyncResult(
        success: false,
        sincronizadas: 0,
        errores: 0,
        mensaje: 'Error: $e',
      );
    }
  }

  // ==================== SINCRONIZACIÓN MENSUAL ====================

  /// Sincroniza todas las transacciones del mes actual a Google Sheets
  /// Se ejecuta el último día del mes antes del reporte
  Future<SyncResult> sincronizarMesCompleto() async {
    try {
      print('📅 Iniciando sincronización mensual completa...');

      final ahora = DateTime.now();
      final primerDiaMes = DateTime(ahora.year, ahora.month, 1);
      final ultimoDiaMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

      // Obtener TODAS las transacciones del mes actual
      // Sin orderBy para evitar índice compuesto
      final snapshot =
          await _db
              .collection('transacciones')
              .where('usuarioId', isEqualTo: defaultUserId)
              .where(
                'fecha',
                isGreaterThanOrEqualTo: Timestamp.fromDate(primerDiaMes),
              )
              .where(
                'fecha',
                isLessThanOrEqualTo: Timestamp.fromDate(ultimoDiaMes),
              )
              .get();

      if (snapshot.docs.isEmpty) {
        print('✅ No hay transacciones del mes para sincronizar');
        return SyncResult(
          success: true,
          sincronizadas: 0,
          errores: 0,
          mensaje: 'No hay transacciones del mes',
        );
      }

      // Ordenar en memoria por fecha
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final fechaA = (a.data()['fecha'] as Timestamp).toDate();
        final fechaB = (b.data()['fecha'] as Timestamp).toDate();
        return fechaA.compareTo(fechaB);
      });

      print('📤 Sincronizando ${docs.length} transacciones del mes...');

      int sincronizadas = 0;
      int errores = 0;
      final List<String> mensajesError = [];

      // Convertir y enviar cada transacción
      for (var doc in docs) {
        try {
          final transaccion = Transaction.fromFirestore(doc);

          // Enviar a Google Sheets
          await _apiService.enviarTransaccionASheets(transaccion);

          sincronizadas++;
          print('✅ Sincronizada: ${transaccion.descripcion}');
        } catch (e) {
          errores++;
          final mensaje = 'Error en transacción: $e';
          mensajesError.add(mensaje);
          print('❌ $mensaje');
        }
      }

      print(
        '🎉 Sincronización mensual completada: $sincronizadas exitosas, $errores errores',
      );

      return SyncResult(
        success: errores == 0,
        sincronizadas: sincronizadas,
        errores: errores,
        mensaje:
            'Mes sincronizado: $sincronizadas transacciones | Errores: $errores',
        mensajesError: mensajesError,
      );
    } catch (e) {
      print('❌ Error en sincronización mensual: $e');
      return SyncResult(
        success: false,
        sincronizadas: 0,
        errores: 0,
        mensaje: 'Error: $e',
      );
    }
  }

  // ==================== CORTE SEMANAL ====================

  /// Ejecuta el corte semanal de transacciones de Supermercado
  /// Agrupa transacciones de la semana y crea una sola transacción "Corte Semanal"
  Future<CorteResult> ejecutarCorteSemanal() async {
    try {
      print('🗓️ Iniciando corte semanal...');

      // Calcular rango de fechas (última semana)
      final ahora = DateTime.now();
      final inicioSemana = ahora.subtract(Duration(days: 7));

      // Buscar transacciones de Supermercado de la última semana en Firebase
      final snapshot =
          await _db
              .collection('transacciones')
              .where('usuarioId', isEqualTo: defaultUserId)
              .where('categoria', isEqualTo: 'Supermercado')
              .where('tipo', isEqualTo: 'Gastos')
              .where(
                'fecha',
                isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemana),
              )
              .get();

      if (snapshot.docs.isEmpty) {
        print('✅ No hay transacciones de supermercado para agrupar');
        return CorteResult(
          success: true,
          transaccionesAgrupadas: 0,
          montoTotal: 0,
          mensaje: 'No hay transacciones de supermercado',
        );
      }

      // Sumar montos y recolectar IDs
      double montoTotal = 0;
      final List<String> idsEliminar = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        montoTotal += (data['monto'] as num).toDouble().abs();
        idsEliminar.add(doc.id);
      }

      print(
        '📊 Encontradas ${snapshot.docs.length} transacciones, total: \$$montoTotal',
      );

      // Crear transacción de corte semanal en Firebase
      final fechaCorte = ahora.toIso8601String().split('T')[0];

      final dataCorte = {
        'fecha': Timestamp.fromDate(ahora),
        'mes': fechaCorte.substring(0, 7), // YYYY-MM
        'categoria': 'Semanal',
        'monto': -montoTotal.abs(), // Negativo porque es gasto
        'descripcion': 'Corte Semanal Supermercado',
        'tipo': 'Gastos',
        'usuarioId': defaultUserId,
        'sincronizado': false,
        'createdAt': FieldValue.serverTimestamp(),
        'cuentaId': '',
        'cuentaNombre': '',
      };

      // Guardar la transacción de corte
      await _db.collection('transacciones').add(dataCorte);
      print('✅ Transacción de corte semanal creada');

      // Eliminar transacciones individuales de Firebase
      final batch = _db.batch();
      for (var id in idsEliminar) {
        batch.delete(_db.collection('transacciones').doc(id));
      }
      await batch.commit();

      print(
        '✅ Corte semanal completado: ${snapshot.docs.length} transacciones agrupadas',
      );

      return CorteResult(
        success: true,
        transaccionesAgrupadas: snapshot.docs.length,
        montoTotal: montoTotal,
        mensaje:
            'Agrupadas ${snapshot.docs.length} transacciones por \$$montoTotal',
      );
    } catch (e) {
      print('❌ Error en corte semanal: $e');
      return CorteResult(
        success: false,
        transaccionesAgrupadas: 0,
        montoTotal: 0,
        mensaje: 'Error: $e',
      );
    }
  }

  // ==================== VERIFICACIÓN ====================

  /// Cuenta transacciones pendientes de sincronizar
  Future<int> contarPendientes() async {
    final transacciones =
        await _firestoreService.obtenerTransaccionesNoSincronizadas();
    return transacciones.length;
  }

  /// Verifica el estado de la sincronización
  Future<SyncStatus> obtenerEstadoSync() async {
    try {
      final ahora = DateTime.now();
      final primerDiaMes = DateTime(ahora.year, ahora.month, 1);

      // Contar transacciones del mes actual
      final snapshot =
          await _db
              .collection('transacciones')
              .where('usuarioId', isEqualTo: defaultUserId)
              .where(
                'fecha',
                isGreaterThanOrEqualTo: Timestamp.fromDate(primerDiaMes),
              )
              .get();

      return SyncStatus(
        pendientes: snapshot.docs.length,
        ultimaSincronizacion: null,
        sincronizacionActiva: false,
      );
    } catch (e) {
      print('❌ Error obteniendo estado: $e');
      return SyncStatus(
        pendientes: 0,
        ultimaSincronizacion: null,
        sincronizacionActiva: false,
      );
    }
  }
}

// ==================== MODELOS DE RESULTADO ====================

class SyncResult {
  final bool success;
  final int sincronizadas;
  final int errores;
  final String mensaje;
  final List<String> mensajesError;

  SyncResult({
    required this.success,
    required this.sincronizadas,
    required this.errores,
    required this.mensaje,
    this.mensajesError = const [],
  });

  // Alias para compatibilidad con background_tasks.dart
  int get exitosas => sincronizadas;
  int get fallidas => errores;
  Duration get duracion => const Duration(seconds: 0);
}

class CorteResult {
  final bool success;
  final int transaccionesAgrupadas;
  final double montoTotal;
  final String mensaje;

  CorteResult({
    required this.success,
    required this.transaccionesAgrupadas,
    required this.montoTotal,
    required this.mensaje,
  });

  // Alias para compatibilidad con background_tasks.dart
  Duration get duracion => const Duration(seconds: 0);
  String? get error => success ? null : mensaje;
}

class SyncStatus {
  final int pendientes;
  final DateTime? ultimaSincronizacion;
  final bool sincronizacionActiva;

  SyncStatus({
    required this.pendientes,
    this.ultimaSincronizacion,
    required this.sincronizacionActiva,
  });
}
