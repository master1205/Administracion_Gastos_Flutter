import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:notificaciones/models/Transaccion.dart' as models;
import 'package:notificaciones/api_service.dart';

/// Callback que se ejecuta en background por AndroidAlarmManager (Semanal)
@pragma('vm:entry-point')
void cortesCallback() async {
  try {
    print('🔄 Ejecutando corte semanal en background');

    // Ejecutar el corte semanal
    await CortesService.ejecutarCorteSemanal();

    print('✅ Corte semanal en background completado');
  } catch (e) {
    print('❌ Error en corte semanal background: $e');
  }
}

/// Callback para corte mensual
@pragma('vm:entry-point')
void corteMensualCallback() async {
  try {
    print('🔄 Ejecutando corte mensual en background');

    // Ejecutar el corte mensual
    await CortesService.ejecutarCorteMensual();

    print('✅ Corte mensual en background completado');
  } catch (e) {
    print('❌ Error en corte mensual background: $e');
  }
}

class CortesService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String defaultUserId = 'default_user';
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Programa el corte semanal para domingos a la 1 AM
  static Future<void> programarCorteSemanal() async {
    // Inicializar AndroidAlarmManager
    await AndroidAlarmManager.initialize();

    // Cancelar alarmas previas
    await AndroidAlarmManager.cancel(100); // ID único para corte semanal

    // Calcular próximo domingo a la 1 AM
    final proximoDomingo = _calcularProximoDomingo();

    // Programar alarma periódica semanal (cada 7 días)
    await AndroidAlarmManager.periodic(
      const Duration(days: 7),
      100, // ID único
      cortesCallback,
      startAt: proximoDomingo,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    print('✅ Corte semanal programado con AndroidAlarmManager');
    print('📅 Se ejecutará cada domingo a la 1:00 AM');
    print('⏰ Próxima ejecución: $proximoDomingo');
  }

  /// Calcula la fecha del próximo domingo a la 1 AM
  static DateTime _calcularProximoDomingo() {
    final ahora = DateTime.now();
    var proximoDomingo = DateTime(ahora.year, ahora.month, ahora.day, 1, 0);

    // Si ya pasó la 1 AM de hoy y es domingo, ir al siguiente
    while (proximoDomingo.weekday != DateTime.sunday ||
        proximoDomingo.isBefore(ahora)) {
      proximoDomingo = proximoDomingo.add(const Duration(days: 1));
    }

    final duracion = proximoDomingo.difference(ahora);
    print(
      '⏰ Primera ejecución en: ${duracion.inDays} días y ${duracion.inHours % 24} horas',
    );

    return proximoDomingo;
  }

  /// Ejecuta el corte semanal de la categoría Alimentación
  /// Retorna un Map con: success (bool), message (String), total (double?), count (int?)
  static Future<Map<String, dynamic>> ejecutarCorteSemanal() async {
    try {
      final ahora = DateTime.now();

      // Calcular fecha de inicio: domingo de la semana pasada
      final diasDesdeUltimoDomingo =
          ahora.weekday == DateTime.sunday ? 7 : ahora.weekday;
      final domingoAnterior = ahora.subtract(
        Duration(days: diasDesdeUltimoDomingo),
      );
      final inicioSemana = DateTime(
        domingoAnterior.year,
        domingoAnterior.month,
        domingoAnterior.day,
      );

      // Calcular fecha fin: sábado (ayer si hoy es domingo)
      final sabado = inicioSemana.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      final inicioSemanaTimestamp = Timestamp.fromDate(inicioSemana);
      final finSemanaTimestamp = Timestamp.fromDate(sabado);

      print(
        '📅 Corte semanal: ${_formatearFecha(inicioSemana)} al ${_formatearFecha(sabado)}',
      );

      // Obtener transacciones de "Alimentación" de la semana
      final query =
          await _db
              .collection('transacciones')
              .where('usuarioId', isEqualTo: defaultUserId)
              .where('tipo', isEqualTo: 'Gasto')
              .where('categoria', isEqualTo: 'Alimentación')
              .where('fecha', isGreaterThanOrEqualTo: inicioSemanaTimestamp)
              .where('fecha', isLessThanOrEqualTo: finSemanaTimestamp)
              .get();

      // Calcular total
      double totalSemanal = 0;
      final transaccionesIds = <String>[];

      for (var doc in query.docs) {
        final data = doc.data();
        totalSemanal += (data['monto'] as num?)?.toDouble() ?? 0;
        transaccionesIds.add(doc.id);
      }

      final cantidadTransacciones = query.docs.length;

      // ✅ Solo hacer corte si hay transacciones
      if (transaccionesIds.isEmpty) {
        print('ℹ️ No hay transacciones esta semana. Corte omitido.');
        return {
          'success': true,
          'message': 'No hay transacciones esta semana',
          'total': 0.0,
          'count': 0,
        };
      }

      // Mostrar notificación con el resultado
      await _notificationsPlugin.show(
        10000, // ID único para resultado
        '🍽️ Corte Semanal',
        'Gastaste \$${totalSemanal.toStringAsFixed(2)} en $cantidadTransacciones transacciones esta semana',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'corte_resultado_channel',
            'Resultados de Corte',
            channelDescription: 'Notificaciones con resultados de cortes',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              'Del ${_formatearFecha(inicioSemana)} al ${_formatearFecha(sabado)}\n'
              '(Domingo a Sábado)\n'
              'Total: \$${totalSemanal.toStringAsFixed(2)}\n'
              'Transacciones: $cantidadTransacciones',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      // ✅ ELIMINAR las transacciones de Alimentación después del corte
      final batch = _db.batch();
      for (var id in transaccionesIds) {
        batch.delete(_db.collection('transacciones').doc(id));
      }
      await batch.commit();

      // ✅ Crear transacción resumen del corte semanal DESPUÉS de eliminar
      await _db.collection('transacciones').add({
        'usuarioId': defaultUserId,
        'tipo': 'Gasto',
        'categoria': 'Semanal',
        'monto': totalSemanal,
        'descripcion': 'Corte Semanal',
        'fecha': Timestamp.now(),
        'cuenta': '',
        'cuentaNombre': '',
        'cuentaOrigen': '',
        'cuentaOrigenNombre': '',
        'cuentaDestino': '',
        'cuentaDestinoNombre': '',
        'idTransaccion':
            'corte_semanal_${DateTime.now().millisecondsSinceEpoch}',
      });

      print(
        '✅ Transacción resumen creada: Corte Semanal - \$${totalSemanal.toStringAsFixed(2)}',
      );

      print(
        '✅ Corte semanal ejecutado: \$${totalSemanal.toStringAsFixed(2)} ($cantidadTransacciones transacciones eliminadas)',
      );

      return {
        'success': true,
        'message': 'Corte ejecutado exitosamente',
        'total': totalSemanal,
        'count': cantidadTransacciones,
      };
    } catch (e) {
      print('❌ Error en corte semanal: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'total': null,
        'count': null,
      };
    }
  }

  /// Cancela el corte semanal programado
  static Future<void> cancelarCorteSemanal() async {
    await AndroidAlarmManager.cancel(100); // ID único para corte semanal
    print('🚫 Corte semanal cancelado');
  }

  // ==================== CORTE MENSUAL ====================

  /// Programa el corte mensual para el 1º de cada mes a la 1 AM
  static Future<void> programarCorteMensual() async {
    // Inicializar AndroidAlarmManager (si no se hizo antes)
    await AndroidAlarmManager.initialize();

    // Cancelar alarmas previas
    await AndroidAlarmManager.cancel(200); // ID único para corte mensual

    // Calcular próximo 1º del mes a la 1 AM
    final proximoPrimerDia = _calcularProximoPrimerDiaMes();

    // Programar alarma periódica mensual (cada 30 días aprox)
    await AndroidAlarmManager.periodic(
      const Duration(days: 30),
      200, // ID único
      corteMensualCallback,
      startAt: proximoPrimerDia,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    print('✅ Corte mensual programado con AndroidAlarmManager');
    print('📅 Se ejecutará el 1º de cada mes a la 1:00 AM');
    print('⏰ Próxima ejecución: $proximoPrimerDia');
  }

  /// Calcula la fecha del próximo 1º del mes a la 1 AM
  static DateTime _calcularProximoPrimerDiaMes() {
    final ahora = DateTime.now();
    DateTime proximoPrimerDia;

    // Si es antes de la 1 AM del día 1, programar para hoy
    if (ahora.day == 1 && ahora.hour < 1) {
      proximoPrimerDia = DateTime(ahora.year, ahora.month, 1, 1, 0);
    } else {
      // Programar para el próximo mes
      if (ahora.month == 12) {
        proximoPrimerDia = DateTime(ahora.year + 1, 1, 1, 1, 0);
      } else {
        proximoPrimerDia = DateTime(ahora.year, ahora.month + 1, 1, 1, 0);
      }
    }

    final duracion = proximoPrimerDia.difference(ahora);
    print(
      '⏰ Primera ejecución mensual en: ${duracion.inDays} días y ${duracion.inHours % 24} horas',
    );

    return proximoPrimerDia;
  }

  /// Ejecuta el corte mensual de todas las transacciones
  /// Retorna un Map con: success (bool), message (String), total (double?), count (int?)
  static Future<Map<String, dynamic>> ejecutarCorteMensual() async {
    try {
      final ahora = DateTime.now();

      // Calcular mes anterior completo
      final DateTime inicioMesAnterior;
      final DateTime finMesAnterior;

      if (ahora.month == 1) {
        // Si estamos en enero, el mes anterior es diciembre del año pasado
        inicioMesAnterior = DateTime(ahora.year - 1, 12, 1);
        finMesAnterior = DateTime(ahora.year - 1, 12, 31, 23, 59, 59);
      } else {
        // Mes anterior del mismo año
        inicioMesAnterior = DateTime(ahora.year, ahora.month - 1, 1);
        // Último día del mes anterior
        finMesAnterior = DateTime(ahora.year, ahora.month, 0, 23, 59, 59);
      }

      final inicioTimestamp = Timestamp.fromDate(inicioMesAnterior);
      final finTimestamp = Timestamp.fromDate(finMesAnterior);

      print(
        '📅 Corte mensual: ${_formatearFecha(inicioMesAnterior)} al ${_formatearFecha(finMesAnterior)}',
      );

      // Obtener TODAS las transacciones del mes anterior
      final query =
          await _db
              .collection('transacciones')
              .where('usuarioId', isEqualTo: defaultUserId)
              .where('fecha', isGreaterThanOrEqualTo: inicioTimestamp)
              .where('fecha', isLessThanOrEqualTo: finTimestamp)
              .get();

      if (query.docs.isEmpty) {
        print('ℹ️ No hay transacciones del mes anterior. Corte omitido.');
        return {
          'success': true,
          'message': 'No hay transacciones del mes anterior',
          'total': 0.0,
          'count': 0,
        };
      }

      // Convertir a lista de transacciones
      final transacciones =
          query.docs.map((doc) {
            return models.Transaction.fromFirestore(doc);
          }).toList();

      final cantidadTransacciones = transacciones.length;
      double totalGeneral = 0;
      double totalIngresos = 0;
      double totalGastos = 0;

      // Calcular totales por tipo
      for (var t in transacciones) {
        totalGeneral += t.monto;

        if (t.tipoTransaccion == 'Ingresos') {
          totalIngresos += t.monto;
        } else if (t.tipoTransaccion == 'Gastos' ||
            t.tipoTransaccion == 'Pagos') {
          totalGastos += t.monto;
        }
      }

      // Obtener saldo total de todas las cuentas desde Firebase
      print('💰 Consultando saldo total de cuentas...');
      final cuentasSnapshot =
          await _db
              .collection('cuentas')
              .where('usuarioId', isEqualTo: defaultUserId)
              .where('activa', isEqualTo: true)
              .get();

      double saldoTotal = 0;
      for (var doc in cuentasSnapshot.docs) {
        final saldo = (doc.data()['saldo'] as num?)?.toDouble() ?? 0;
        saldoTotal += saldo;
      }

      print(
        '📊 Resumen financiero: Ingresos: \$${totalIngresos.toStringAsFixed(2)}, '
        'Gastos: \$${totalGastos.toStringAsFixed(2)}, '
        'Saldo Total: \$${saldoTotal.toStringAsFixed(2)}',
      );

      print(
        '📊 Total de transacciones a enviar: $cantidadTransacciones (\$${totalGeneral.toStringAsFixed(2)})',
      );

      // Enviar transacciones y resumen a Google Sheets
      final resultadoEnvio = await ApiService.enviarTransaccionesASheets(
        transacciones,
        totalIngresos,
        totalGastos,
        saldoTotal,
      );

      if (!resultadoEnvio['success']) {
        return {
          'success': false,
          'message':
              'Error al enviar a Google Sheets: ${resultadoEnvio['error']}',
          'total': null,
          'count': null,
        };
      }

      // ✅ Guardar reporte en Firebase si se generó correctamente
      final reporteData = resultadoEnvio['data'] as Map<String, dynamic>?;
      final reporteUrl = reporteData?['reporteUrl'] as String?;

      if (reporteUrl != null && reporteUrl.isNotEmpty) {
        await _guardarReporteEnFirebase(
          inicioMesAnterior,
          finMesAnterior,
          reporteUrl,
        );
        print('✅ Reporte guardado en Firebase: $reporteUrl');
      } else {
        print('⚠️ No se generó URL de reporte o hubo un error');
      }

      // Mostrar notificación con el resultado
      await _notificationsPlugin.show(
        20000, // ID único para corte mensual
        '📊 Corte Mensual Completado',
        'Registradas $cantidadTransacciones transacciones (\$${totalGeneral.toStringAsFixed(2)}) en Google Sheets',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'corte_mensual_channel',
            'Corte Mensual',
            channelDescription: 'Notificaciones de corte mensual',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              'Del ${_formatearFecha(inicioMesAnterior)} al ${_formatearFecha(finMesAnterior)}\n'
              'Total: \$${totalGeneral.toStringAsFixed(2)}\n'
              'Transacciones: $cantidadTransacciones\n'
              '✅ Registradas en Google Sheets',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      // ✅ ELIMINAR las transacciones de Firebase después de registrar en Sheets
      final batch = _db.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print(
        '✅ Corte mensual ejecutado: $cantidadTransacciones transacciones enviadas a Sheets y eliminadas de Firebase',
      );

      return {
        'success': true,
        'message': 'Corte mensual ejecutado exitosamente',
        'total': totalGeneral,
        'count': cantidadTransacciones,
      };
    } catch (e) {
      print('❌ Error en corte mensual: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'total': null,
        'count': null,
      };
    }
  }

  /// Guarda el reporte mensual en Firebase
  static Future<void> _guardarReporteEnFirebase(
    DateTime inicioMes,
    DateTime finMes,
    String urlReporte,
  ) async {
    try {
      final mes = _obtenerNombreMes(inicioMes.month);
      final anio = inicioMes.year;

      final reporteData = {
        'nombre': 'Reporte_Mensual.pdf',
        'año': anio,
        'mes': mes,
        'urlReporte': urlReporte,
        'usuarioId': 'default_user',
        'fechaCreacion': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('reportes').add(reporteData);

      print('✅ Reporte guardado en Firebase: $mes $anio');
    } catch (e) {
      print('❌ Error al guardar reporte en Firebase: $e');
    }
  }

  /// Obtiene el nombre del mes en español
  static String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }

  /// Cancela el corte mensual programado
  static Future<void> cancelarCorteMensual() async {
    await AndroidAlarmManager.cancel(200); // ID único para corte mensual
    print('🚫 Corte mensual cancelado');
  }

  static String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
