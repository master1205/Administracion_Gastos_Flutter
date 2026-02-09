import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Budget.dart';
import 'package:notificaciones/models/Meta.dart';
import 'package:notificaciones/models/Transaccion.dart' as models;
import 'package:notificaciones/models/Apartado.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String defaultUserId = 'default_user';

  // ==================== TRANSACCIONES ====================

  /// Registra o actualiza una transacción con denormalization
  Future<String> registrarTransaccion({
    required models.Transaction transaccion,
    Account? cuenta,
    Account? cuentaOrigen,
    Account? cuentaDestino,
  }) async {
    final fecha =
        transaccion.fechaTimestamp ?? DateTime.parse(transaccion.fecha);
    final mes = fecha.toString().substring(0, 7); // YYYY-MM

    final data = {
      'fecha': Timestamp.fromDate(fecha),
      'mes': mes,
      'categoria': transaccion.categoria,
      'monto': transaccion.monto,
      'descripcion': transaccion.descripcion,
      'tipo': transaccion.tipoTransaccion,
      'usuarioId': defaultUserId,
      'sincronizado': false,
    };

    // Denormalización
    if (transaccion.esTraspaso) {
      if (cuentaOrigen != null) {
        data['cuentaOrigenId'] = cuentaOrigen.id;
        data['cuentaOrigenNombre'] = cuentaOrigen.nombre;
      }
      if (cuentaDestino != null) {
        data['cuentaDestinoId'] = cuentaDestino.id;
        data['cuentaDestinoNombre'] = cuentaDestino.nombre;
      }
    } else {
      if (cuenta != null) {
        data['cuentaId'] = cuenta.id;
        data['cuentaNombre'] = cuenta.nombre;
      }
    }

    final bool esEdicion = transaccion.idTransaccion.isNotEmpty;
    String transaccionId;

    if (esEdicion) {
      // ACTUALIZAR transacción existente
      print('✏️ Actualizando transacción: ${transaccion.idTransaccion}');

      // Obtener la transacción anterior para revertir saldos
      final docAnterior =
          await _db
              .collection('transacciones')
              .doc(transaccion.idTransaccion)
              .get();

      if (docAnterior.exists) {
        final dataAnterior = docAnterior.data()!;
        final montoAnterior = (dataAnterior['monto'] as num).toDouble();
        final tipoAnterior = dataAnterior['tipo'] as String;

        // Revertir los saldos de la transacción anterior
        if (tipoAnterior == 'Traspasos') {
          final cuentaOrigenIdAnterior =
              dataAnterior['cuentaOrigenId'] as String?;
          final cuentaDestinoIdAnterior =
              dataAnterior['cuentaDestinoId'] as String?;

          if (cuentaOrigenIdAnterior != null) {
            final cuentaOrigenDoc =
                await _db
                    .collection('cuentas')
                    .doc(cuentaOrigenIdAnterior)
                    .get();
            if (cuentaOrigenDoc.exists) {
              final saldoActual =
                  (cuentaOrigenDoc.data()!['saldo'] as num).toDouble();
              await actualizarSaldoCuenta(
                cuentaOrigenIdAnterior,
                saldoActual + montoAnterior,
              );
            }
          }
          if (cuentaDestinoIdAnterior != null) {
            final cuentaDestinoDoc =
                await _db
                    .collection('cuentas')
                    .doc(cuentaDestinoIdAnterior)
                    .get();
            if (cuentaDestinoDoc.exists) {
              final saldoActual =
                  (cuentaDestinoDoc.data()!['saldo'] as num).toDouble();
              await actualizarSaldoCuenta(
                cuentaDestinoIdAnterior,
                saldoActual - montoAnterior,
              );
            }
          }
        } else {
          final cuentaIdAnterior = dataAnterior['cuentaId'] as String?;
          if (cuentaIdAnterior != null) {
            final cuentaDoc =
                await _db.collection('cuentas').doc(cuentaIdAnterior).get();
            if (cuentaDoc.exists) {
              final saldoActual =
                  (cuentaDoc.data()!['saldo'] as num).toDouble();
              if (tipoAnterior == 'Gastos' || tipoAnterior == 'Pagos') {
                await actualizarSaldoCuenta(
                  cuentaIdAnterior,
                  saldoActual + montoAnterior,
                );
              } else {
                await actualizarSaldoCuenta(
                  cuentaIdAnterior,
                  saldoActual - montoAnterior,
                );
              }
            }
          }
        }
      }

      // Actualizar con los nuevos datos
      await _db
          .collection('transacciones')
          .doc(transaccion.idTransaccion)
          .update(data);
      transaccionId = transaccion.idTransaccion;
    } else {
      // CREAR nueva transacción
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _db.collection('transacciones').add(data);
      transaccionId = docRef.id;
    }

    // Aplicar los nuevos saldos
    if (transaccion.esTraspaso) {
      // Traspaso: restar de origen y sumar a destino
      if (cuentaOrigen != null) {
        // Leer el saldo actual de Firebase (ya revertido si es edición)
        final cuentaOrigenDoc =
            await _db.collection('cuentas').doc(cuentaOrigen.id).get();
        if (cuentaOrigenDoc.exists) {
          final saldoActual =
              (cuentaOrigenDoc.data()!['saldo'] as num).toDouble();
          final nuevoSaldoOrigen = saldoActual - transaccion.monto.abs();
          await actualizarSaldoCuenta(cuentaOrigen.id, nuevoSaldoOrigen);
          await sincronizarMetaConCuenta(cuentaOrigen.id);
        }
      }
      if (cuentaDestino != null) {
        // Leer el saldo actual de Firebase (ya revertido si es edición)
        final cuentaDestinoDoc =
            await _db.collection('cuentas').doc(cuentaDestino.id).get();
        if (cuentaDestinoDoc.exists) {
          final saldoActual =
              (cuentaDestinoDoc.data()!['saldo'] as num).toDouble();
          final nuevoSaldoDestino = saldoActual + transaccion.monto.abs();
          await actualizarSaldoCuenta(cuentaDestino.id, nuevoSaldoDestino);
          await sincronizarMetaConCuenta(cuentaDestino.id);
        }
      }
    } else if (cuenta != null) {
      // Gasto/Ingreso: actualizar saldo según tipo
      // Leer el saldo actual de Firebase (ya revertido si es edición)
      final cuentaDoc = await _db.collection('cuentas').doc(cuenta.id).get();
      if (cuentaDoc.exists) {
        final saldoActual = (cuentaDoc.data()!['saldo'] as num).toDouble();
        double nuevoSaldo;
        if (transaccion.tipoTransaccion == 'Gastos' ||
            transaccion.tipoTransaccion == 'Pagos') {
          nuevoSaldo = saldoActual - transaccion.monto.abs();
        } else {
          nuevoSaldo = saldoActual + transaccion.monto.abs();
        }
        await actualizarSaldoCuenta(cuenta.id, nuevoSaldo);
        await sincronizarMetaConCuenta(cuenta.id);
      }
    }

    return transaccionId;
  }

  /// Obtiene transacciones recientes (últimos 30 días)
  Stream<List<models.Transaction>> obtenerTransaccionesRecientes({
    String? usuarioId,
  }) {
    final uid = usuarioId ?? defaultUserId;
    final hace30Dias = DateTime.now().subtract(const Duration(days: 30));

    return _db
        .collection('transacciones')
        .where('usuarioId', isEqualTo: uid)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(hace30Dias))
        .orderBy('fecha', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => models.Transaction.fromFirestore(doc))
                  .toList(),
        );
  }

  // ==================== CUENTAS ====================

  /// Obtiene todas las cuentas activas del usuario
  Stream<List<Account>> obtenerCuentas({String? usuarioId}) {
    final uid = usuarioId ?? defaultUserId;

    return _db
        .collection('cuentas')
        .where('usuarioId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: false) // Solo cambios del servidor
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList(),
        );
  }

  /// Actualiza el saldo de una cuenta
  Future<void> actualizarSaldoCuenta(String cuentaId, double nuevoSaldo) async {
    await _db.collection('cuentas').doc(cuentaId).update({
      'saldo': nuevoSaldo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Incrementa o decrementa el saldo retenido de una cuenta
  Future<void> _actualizarSaldoRetenido(String cuentaId, double delta) async {
    final cuentaDoc = await _db.collection('cuentas').doc(cuentaId).get();
    if (!cuentaDoc.exists) return;

    final saldoRetenidoActual =
        (cuentaDoc.data()!['saldoRetenido'] as num?)?.toDouble() ?? 0.0;
    final nuevoRetenido = (saldoRetenidoActual + delta).clamp(
      0.0,
      double.infinity,
    );

    await _db.collection('cuentas').doc(cuentaId).update({
      'saldoRetenido': nuevoRetenido,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Crea una nueva cuenta
  Future<String> crearCuenta(Account cuenta) async {
    final docRef = await _db
        .collection('cuentas')
        .add(cuenta.toFirestore(isNew: true));
    return docRef.id;
  }

  // ==================== METAS ====================

  /// Obtiene todas las metas del usuario
  Stream<List<Meta>> obtenerMetas({String? usuarioId}) {
    final uid = usuarioId ?? defaultUserId;

    return _db
        .collection('metas')
        .where('usuarioId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Meta.fromFirestore(doc)).toList(),
        );
  }

  /// Actualiza el avance de una meta
  Future<void> actualizarAvanceMeta(String metaId, double nuevoMonto) async {
    await _db.collection('metas').doc(metaId).update({
      'montoActual': nuevoMonto,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sincroniza el montoActual de una meta con el saldo de su cuenta asociada
  Future<void> sincronizarMetaConCuenta(String cuentaId) async {
    // Buscar si existe una meta asociada a esta cuenta
    final metasSnapshot =
        await _db
            .collection('metas')
            .where('cuentaId', isEqualTo: cuentaId)
            .limit(1)
            .get();

    if (metasSnapshot.docs.isNotEmpty) {
      final metaDoc = metasSnapshot.docs.first;

      // Obtener el saldo actual de la cuenta
      final cuentaDoc = await _db.collection('cuentas').doc(cuentaId).get();
      if (cuentaDoc.exists) {
        final saldoCuenta =
            (cuentaDoc.data()?['saldo'] as num?)?.toDouble() ?? 0.0;

        // Actualizar el montoActual de la meta con el saldo de la cuenta
        await actualizarAvanceMeta(metaDoc.id, saldoCuenta);
      }
    }
  }

  /// Crea una nueva meta con denormalización
  Future<String> crearMeta(Meta meta, Account? cuenta) async {
    final data = meta.toFirestore(isNew: true);

    // Agregar denormalization de la cuenta
    if (cuenta != null) {
      data['cuentaId'] = cuenta.id;
      data['cuentaNombre'] = cuenta.nombre;
    }

    final docRef = await _db.collection('metas').add(data);
    return docRef.id;
  }

  // ==================== DASHBOARD ====================

  /// Obtiene gastos por categoría del mes actual
  Future<Map<String, double>> obtenerGastosPorCategoriaMesActual({
    String? usuarioId,
  }) async {
    final uid = usuarioId ?? defaultUserId;
    final mesActual = DateTime.now().toString().substring(0, 7); // YYYY-MM

    final snapshot =
        await _db
            .collection('transacciones')
            .where('usuarioId', isEqualTo: uid)
            .where('mes', isEqualTo: mesActual)
            .where('tipo', isEqualTo: 'Gastos')
            .get();

    final gastosMap = <String, double>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final categoria = data['categoria'] as String;
      final monto = (data['monto'] as num).toDouble();
      gastosMap[categoria] = (gastosMap[categoria] ?? 0) + monto;
    }

    return gastosMap;
  }

  // ==================== SYNC ====================

  // ==================== ACTUALIZAR/ELIMINAR ====================

  /// Actualizar meta completa
  Future<void> actualizarMeta(Meta meta) async {
    await _db
        .collection('metas')
        .doc(meta.id)
        .set(meta.toFirestore(), SetOptions(merge: true));
  }

  /// Eliminar meta y su cuenta asociada
  Future<void> eliminarMeta(String metaId) async {
    // Primero obtener la meta para ver si tiene cuenta asociada
    final metaDoc = await _db.collection('metas').doc(metaId).get();

    if (metaDoc.exists) {
      final cuentaId = metaDoc.data()?['cuentaId'] as String?;

      // Eliminar la meta
      await _db.collection('metas').doc(metaId).delete();

      // Eliminar completamente la cuenta asociada si existe
      if (cuentaId != null && cuentaId.isNotEmpty) {
        await _db.collection('cuentas').doc(cuentaId).delete();
      }
    }
  }

  /// Eliminar transacción y revertir el cambio en el saldo
  Future<void> eliminarTransaccion(String transaccionId) async {
    // Primero obtener la transacción para revertir el saldo
    final doc = await _db.collection('transacciones').doc(transaccionId).get();

    if (!doc.exists) {
      throw Exception('Transacción no encontrada');
    }

    final data = doc.data() as Map<String, dynamic>;
    final tipo = data['tipo'] ?? '';
    final monto = (data['monto'] as num?)?.toDouble() ?? 0.0;
    final cuentaId = data['cuentaId'] as String?;
    final cuentaOrigenId = data['cuentaOrigenId'] as String?;
    final cuentaDestinoId = data['cuentaDestinoId'] as String?;

    // Revertir el cambio en el saldo
    if (tipo == 'Traspasos') {
      // Traspaso: revertir (sumar a origen, restar de destino)
      if (cuentaOrigenId != null) {
        final cuentaOrigenDoc =
            await _db.collection('cuentas').doc(cuentaOrigenId).get();
        if (cuentaOrigenDoc.exists) {
          final saldoActual =
              (cuentaOrigenDoc.data()?['saldo'] as num?)?.toDouble() ?? 0.0;
          await actualizarSaldoCuenta(
            cuentaOrigenId,
            saldoActual + monto.abs(),
          );
          // Sincronizar meta si existe
          await sincronizarMetaConCuenta(cuentaOrigenId);
        }
      }
      if (cuentaDestinoId != null) {
        final cuentaDestinoDoc =
            await _db.collection('cuentas').doc(cuentaDestinoId).get();
        if (cuentaDestinoDoc.exists) {
          final saldoActual =
              (cuentaDestinoDoc.data()?['saldo'] as num?)?.toDouble() ?? 0.0;
          await actualizarSaldoCuenta(
            cuentaDestinoId,
            saldoActual - monto.abs(),
          );
          // Sincronizar meta si existe
          await sincronizarMetaConCuenta(cuentaDestinoId);
        }
      }
    } else if (cuentaId != null) {
      // Gasto/Ingreso: revertir
      final cuentaDoc = await _db.collection('cuentas').doc(cuentaId).get();
      if (cuentaDoc.exists) {
        final saldoActual =
            (cuentaDoc.data()?['saldo'] as num?)?.toDouble() ?? 0.0;
        double nuevoSaldo;

        if (tipo == 'Gastos' || tipo == 'Pagos') {
          // Era un gasto, devolver el dinero (sumar)
          nuevoSaldo = saldoActual + monto.abs();
        } else {
          // Era un ingreso, quitarlo (restar)
          nuevoSaldo = saldoActual - monto.abs();
        }

        await actualizarSaldoCuenta(cuentaId, nuevoSaldo);
        // Sincronizar meta si existe
        await sincronizarMetaConCuenta(cuentaId);
      }
    }

    // Finalmente eliminar la transacción
    await _db.collection('transacciones').doc(transaccionId).delete();
  }

  /// Verifica si una cuenta está asociada a una meta
  Future<bool> cuentaEstaAsociadaAMeta(String cuentaId) async {
    final snapshot =
        await _db
            .collection('metas')
            .where('cuentaId', isEqualTo: cuentaId)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Eliminar cuenta (soft delete)
  Future<void> eliminarCuenta(String cuentaId) async {
    await _db.collection('cuentas').doc(cuentaId).delete();
  }

  // ==================== CATEGORÍAS ====================

  /// Obtiene categorías en tiempo real
  Stream<List<Map<String, dynamic>>> obtenerCategorias({String? usuarioId}) {
    final uid = usuarioId ?? defaultUserId;

    return _db
        .collection('categorias')
        .where('usuarioId', isEqualTo: uid)
        .orderBy('categoria')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  /// Crea una nueva categoría
  Future<String> crearCategoria({
    required String nombre,
    required String imagen,
    required String tipoTransaccion,
    String? usuarioId,
  }) async {
    final uid = usuarioId ?? defaultUserId;

    final docRef = await _db.collection('categorias').add({
      'categoria': nombre,
      'imagen': imagen,
      'tipoTransaccion': tipoTransaccion,
      'usuarioId': uid,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Actualiza una categoría existente
  Future<void> actualizarCategoria({
    required String categoriaId,
    required String nombre,
    required String imagen,
    required String tipoTransaccion,
  }) async {
    await _db.collection('categorias').doc(categoriaId).update({
      'categoria': nombre,
      'imagen': imagen,
      'tipoTransaccion': tipoTransaccion,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina una categoría
  Future<void> eliminarCategoria(String categoriaId) async {
    await _db.collection('categorias').doc(categoriaId).delete();
  }

  /// Obtiene un mapa de nombre de categoría → imagen (codePoint)
  Future<Map<String, String>> obtenerImagenesCategorias({
    String? usuarioId,
  }) async {
    final uid = usuarioId ?? defaultUserId;
    final snapshot =
        await _db
            .collection('categorias')
            .where('usuarioId', isEqualTo: uid)
            .get();

    final imagenesMap = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final nombre = data['categoria'] as String? ?? '';
      final imagen = data['imagen'] as String? ?? 'category';
      if (nombre.isNotEmpty) {
        imagenesMap[nombre] = imagen;
      }
    }
    return imagenesMap;
  }

  /// Verifica si una categoría está en uso
  Future<bool> categoriaEnUso(String nombreCategoria) async {
    final transacciones =
        await _db
            .collection('transacciones')
            .where('categoria', isEqualTo: nombreCategoria)
            .limit(1)
            .get();

    return transacciones.docs.isNotEmpty;
  }

  // ==================== PRESUPUESTOS ====================

  /// Obtiene el inicio de la semana (Domingo)
  static DateTime obtenerInicioSemana(DateTime fecha) {
    final diaActual = fecha.weekday;
    // En Dart: Lunes=1, Domingo=7
    // Queremos: Domingo como día de inicio
    final diasDesdeInicio = diaActual == 7 ? 0 : diaActual;
    final domingo = fecha.subtract(Duration(days: diasDesdeInicio));
    return DateTime(domingo.year, domingo.month, domingo.day, 0, 0, 0);
  }

  /// Obtiene el fin de la semana (Sábado)
  static DateTime obtenerFinSemana(DateTime inicio) {
    final sabado = inicio.add(const Duration(days: 6));
    return DateTime(sabado.year, sabado.month, sabado.day, 23, 59, 59);
  }

  /// Obtiene el inicio del mes
  static DateTime obtenerInicioMes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, 1, 0, 0, 0);
  }

  /// Obtiene el fin del mes
  static DateTime obtenerFinMes(DateTime fecha) {
    final ultimoDia = DateTime(fecha.year, fecha.month + 1, 0);
    return DateTime(ultimoDia.year, ultimoDia.month, ultimoDia.day, 23, 59, 59);
  }

  /// Crea un nuevo presupuesto
  Future<String> crearPresupuesto({
    required String nombre,
    required double montoLimite,
    required String periodo,
    DateTime? fechaInicio,
    List<String> categorias = const [],
    bool esRecurrente = true,
    bool alertaActiva = true,
    double porcentajeAlerta = 80.0,
    int? colorAsignado,
    String? usuarioId,
  }) async {
    final uid = usuarioId ?? defaultUserId;
    final ahora = fechaInicio ?? DateTime.now();

    DateTime inicio;
    DateTime fechaFin;
    if (periodo == 'semanal') {
      inicio = obtenerInicioSemana(ahora);
      fechaFin = obtenerFinSemana(inicio);
    } else {
      // mensual
      inicio = obtenerInicioMes(ahora);
      fechaFin = obtenerFinMes(inicio);
    }

    final docRef = await _db.collection('presupuestos').add({
      'nombre': nombre,
      'montoLimite': montoLimite,
      'montoGastado': 0.0,
      'periodo': periodo,
      'fechaInicio': Timestamp.fromDate(inicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'categorias': categorias,
      'esRecurrente': esRecurrente,
      'alertaActiva': alertaActiva,
      'porcentajeAlerta': porcentajeAlerta,
      'colorAsignado': colorAsignado,
      'usuarioId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'presupuestoOriginalId': null,
    });

    return docRef.id;
  }

  /// Obtiene presupuestos activos con gasto calculado en tiempo real
  /// Se actualiza cuando cambian presupuestos O transacciones
  Stream<List<Budget>> obtenerPresupuestosActivos({String? usuarioId}) {
    final uid = usuarioId ?? defaultUserId;
    final ahora = DateTime.now();

    late StreamController<List<Budget>> controller;
    StreamSubscription? presSub;
    StreamSubscription? transSub;
    bool isCalculating = false;

    Future<void> recalcular() async {
      if (isCalculating) return; // Evitar cálculos concurrentes
      isCalculating = true;

      try {
        final presSnap =
            await _db
                .collection('presupuestos')
                .where('usuarioId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .get();

        final presupuestos = <Budget>[];

        for (var doc in presSnap.docs) {
          final presupuesto = Budget.fromFirestore(doc);

          // Filtrar solo activos (fechaFin >= ahora)
          if (presupuesto.fechaFin.isAfter(ahora) ||
              presupuesto.fechaFin.isAtSameMomentAs(ahora)) {
            // Calcular gasto real desde transacciones
            final gasto = await _calcularGastoPresupuesto(presupuesto, uid);

            presupuestos.add(presupuesto.copyWith(montoGastado: gasto));
          }
        }

        // Ordenar por fecha de fin (los que vencen antes primero)
        presupuestos.sort((a, b) => a.fechaFin.compareTo(b.fechaFin));

        if (!controller.isClosed) {
          controller.add(presupuestos);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      } finally {
        isCalculating = false;
      }
    }

    controller = StreamController<List<Budget>>.broadcast(
      onListen: () {
        // Escuchar cambios en presupuestos
        presSub = _db
            .collection('presupuestos')
            .where('usuarioId', isEqualTo: uid)
            .snapshots()
            .listen((_) => recalcular());

        // Escuchar cambios en transacciones
        transSub = _db
            .collection('transacciones')
            .where('usuarioId', isEqualTo: uid)
            .snapshots()
            .listen((_) => recalcular());

        // Cálculo inicial
        recalcular();
      },
      onCancel: () {
        presSub?.cancel();
        transSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Obtiene todos los presupuestos (activos e históricos)
  /// Se actualiza cuando cambian presupuestos O transacciones
  Stream<List<Budget>> obtenerTodosPresupuestos({String? usuarioId}) {
    final uid = usuarioId ?? defaultUserId;

    late StreamController<List<Budget>> controller;
    StreamSubscription? presSub;
    StreamSubscription? transSub;
    bool isCalculating = false;

    Future<void> recalcular() async {
      if (isCalculating) return; // Evitar cálculos concurrentes
      isCalculating = true;

      try {
        final presSnap =
            await _db
                .collection('presupuestos')
                .where('usuarioId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .get();

        final presupuestos = <Budget>[];

        for (var doc in presSnap.docs) {
          final presupuesto = Budget.fromFirestore(doc);

          // Calcular gasto real
          final gasto = await _calcularGastoPresupuesto(presupuesto, uid);

          presupuestos.add(presupuesto.copyWith(montoGastado: gasto));
        }

        if (!controller.isClosed) {
          controller.add(presupuestos);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      } finally {
        isCalculating = false;
      }
    }

    controller = StreamController<List<Budget>>.broadcast(
      onListen: () {
        // Escuchar cambios en presupuestos
        presSub = _db
            .collection('presupuestos')
            .where('usuarioId', isEqualTo: uid)
            .snapshots()
            .listen((_) => recalcular());

        // Escuchar cambios en transacciones
        transSub = _db
            .collection('transacciones')
            .where('usuarioId', isEqualTo: uid)
            .snapshots()
            .listen((_) => recalcular());

        // Cálculo inicial
        recalcular();
      },
      onCancel: () {
        presSub?.cancel();
        transSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Calcula el gasto total de un presupuesto desde las transacciones
  Future<double> _calcularGastoPresupuesto(
    Budget presupuesto,
    String usuarioId,
  ) async {
    // Obtener todas las transacciones del usuario (sin filtros de fecha en query)
    // para evitar índices compuestos
    final snapshot =
        await _db
            .collection('transacciones')
            .where('usuarioId', isEqualTo: usuarioId)
            .get();

    double total = 0.0;

    for (var doc in snapshot.docs) {
      final transaccion = models.Transaction.fromFirestore(doc);

      // Filtrar por rango de fechas (lado cliente)
      final fechaTransaccion =
          transaccion.fechaTimestamp ?? DateTime.tryParse(transaccion.fecha);
      if (fechaTransaccion == null) continue;

      // Verificar si está en el rango del presupuesto (inclusive)
      // Comparar solo fechas, sin horas
      final fechaTrans = DateTime(
        fechaTransaccion.year,
        fechaTransaccion.month,
        fechaTransaccion.day,
      );
      final fechaIni = DateTime(
        presupuesto.fechaInicio.year,
        presupuesto.fechaInicio.month,
        presupuesto.fechaInicio.day,
      );
      final fechaFn = DateTime(
        presupuesto.fechaFin.year,
        presupuesto.fechaFin.month,
        presupuesto.fechaFin.day,
      );

      final enRango =
          !fechaTrans.isBefore(fechaIni) && !fechaTrans.isAfter(fechaFn);

      if (!enRango) continue;

      // Solo contar Gastos y Pagos (case-insensitive)
      final tipo = transaccion.tipoTransaccion.toLowerCase();
      if (tipo != 'gastos' &&
          tipo != 'gasto' &&
          tipo != 'pagos' &&
          tipo != 'pago') {
        continue;
      }

      // Si el presupuesto tiene categorías específicas, filtrar
      if (presupuesto.categorias.isNotEmpty) {
        if (!presupuesto.categorias.contains(transaccion.categoria)) {
          continue;
        }
      }

      total += transaccion.monto.abs();
    }

    return total;
  }

  /// Obtiene las transacciones que aplican a un presupuesto específico
  Future<List<models.Transaction>> obtenerTransaccionesPresupuesto(
    Budget presupuesto, {
    String? usuarioId,
  }) async {
    final uid = usuarioId ?? defaultUserId;
    final snapshot =
        await _db
            .collection('transacciones')
            .where('usuarioId', isEqualTo: uid)
            .get();

    final transacciones = <models.Transaction>[];

    for (var doc in snapshot.docs) {
      final transaccion = models.Transaction.fromFirestore(doc);

      final fechaTransaccion =
          transaccion.fechaTimestamp ?? DateTime.tryParse(transaccion.fecha);
      if (fechaTransaccion == null) continue;

      final fechaTrans = DateTime(
        fechaTransaccion.year,
        fechaTransaccion.month,
        fechaTransaccion.day,
      );
      final fechaIni = DateTime(
        presupuesto.fechaInicio.year,
        presupuesto.fechaInicio.month,
        presupuesto.fechaInicio.day,
      );
      final fechaFn = DateTime(
        presupuesto.fechaFin.year,
        presupuesto.fechaFin.month,
        presupuesto.fechaFin.day,
      );

      final enRango =
          !fechaTrans.isBefore(fechaIni) && !fechaTrans.isAfter(fechaFn);
      if (!enRango) continue;

      final tipo = transaccion.tipoTransaccion.toLowerCase();
      if (tipo != 'gastos' &&
          tipo != 'gasto' &&
          tipo != 'pagos' &&
          tipo != 'pago') {
        continue;
      }

      if (presupuesto.categorias.isNotEmpty) {
        if (!presupuesto.categorias.contains(transaccion.categoria)) {
          continue;
        }
      }

      transacciones.add(transaccion);
    }

    // Ordenar por fecha descendente
    transacciones.sort((a, b) {
      final fechaA =
          a.fechaTimestamp ?? DateTime.tryParse(a.fecha) ?? DateTime.now();
      final fechaB =
          b.fechaTimestamp ?? DateTime.tryParse(b.fecha) ?? DateTime.now();
      return fechaB.compareTo(fechaA);
    });

    return transacciones;
  }

  /// Obtiene las transacciones agrupadas por categoría para un presupuesto
  Future<Map<String, double>> obtenerGastoPorCategoriaPresupuesto(
    Budget presupuesto, {
    String? usuarioId,
  }) async {
    final transacciones = await obtenerTransaccionesPresupuesto(
      presupuesto,
      usuarioId: usuarioId,
    );

    final gastosPorCategoria = <String, double>{};
    for (var t in transacciones) {
      final cat = t.categoria.isNotEmpty ? t.categoria : 'Sin categoría';
      gastosPorCategoria[cat] = (gastosPorCategoria[cat] ?? 0) + t.monto.abs();
    }

    return gastosPorCategoria;
  }

  /// Actualiza un presupuesto existente
  Future<void> actualizarPresupuesto({
    required String presupuestoId,
    String? nombre,
    double? montoLimite,
    String? periodo,
    List<String>? categorias,
    bool? esRecurrente,
    bool? alertaActiva,
    double? porcentajeAlerta,
    int? colorAsignado,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (nombre != null) updateData['nombre'] = nombre;
    if (montoLimite != null) updateData['montoLimite'] = montoLimite;
    if (periodo != null) updateData['periodo'] = periodo;
    if (categorias != null) updateData['categorias'] = categorias;
    if (esRecurrente != null) updateData['esRecurrente'] = esRecurrente;
    if (alertaActiva != null) updateData['alertaActiva'] = alertaActiva;
    if (porcentajeAlerta != null)
      updateData['porcentajeAlerta'] = porcentajeAlerta;
    if (colorAsignado != null) updateData['colorAsignado'] = colorAsignado;

    await _db.collection('presupuestos').doc(presupuestoId).update(updateData);
  }

  /// Elimina un presupuesto
  Future<void> eliminarPresupuesto(String presupuestoId) async {
    await _db.collection('presupuestos').doc(presupuestoId).delete();
  }

  /// Obtiene el historial de periodos anteriores de un presupuesto
  Future<List<Map<String, dynamic>>> obtenerHistorialPresupuesto(
    String presupuestoId, {
    int limite = 12,
  }) async {
    final snapshot =
        await _db
            .collection('presupuestos')
            .doc(presupuestoId)
            .collection('historial')
            .orderBy('fechaCorte', descending: true)
            .limit(limite)
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Renueva un presupuesto al siguiente período
  Future<String> renovarPresupuesto(String presupuestoId) async {
    final doc = await _db.collection('presupuestos').doc(presupuestoId).get();

    if (!doc.exists) {
      throw Exception('Presupuesto no encontrado');
    }

    final presupuestoActual = Budget.fromFirestore(doc);

    // Crear presupuesto histórico (copia)
    await _db.collection('presupuestos').add({
      ...presupuestoActual.toFirestore(),
      'presupuestoOriginalId': presupuestoId,
      'esRecurrente': false, // Los históricos no se renuevan
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Calcular nuevo período
    DateTime nuevoInicio;
    DateTime nuevoFin;

    if (presupuestoActual.periodo == 'semanal') {
      nuevoInicio = presupuestoActual.fechaFin.add(const Duration(days: 1));
      nuevoInicio = obtenerInicioSemana(nuevoInicio);
      nuevoFin = obtenerFinSemana(nuevoInicio);
    } else {
      // mensual
      final siguienteMes = DateTime(
        presupuestoActual.fechaFin.year,
        presupuestoActual.fechaFin.month + 1,
        1,
      );
      nuevoInicio = obtenerInicioMes(siguienteMes);
      nuevoFin = obtenerFinMes(siguienteMes);
    }

    // Actualizar presupuesto actual con nuevo período
    await _db.collection('presupuestos').doc(presupuestoId).update({
      'fechaInicio': Timestamp.fromDate(nuevoInicio),
      'fechaFin': Timestamp.fromDate(nuevoFin),
      'montoGastado': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return presupuestoId;
  }

  /// Verifica y renueva presupuestos vencidos automáticamente
  Future<void> verificarYRenovarPresupuestos({String? usuarioId}) async {
    final uid = usuarioId ?? defaultUserId;
    final ahora = DateTime.now();

    final vencidos =
        await _db
            .collection('presupuestos')
            .where('usuarioId', isEqualTo: uid)
            .where('esRecurrente', isEqualTo: true)
            .where('fechaFin', isLessThan: Timestamp.fromDate(ahora))
            .get();

    for (var doc in vencidos.docs) {
      await renovarPresupuesto(doc.id);
    }
  }

  /// Obtiene presupuestos que aplican a una categoría específica
  Future<List<Budget>> obtenerPresupuestosPorCategoria({
    required String categoria,
    String? usuarioId,
  }) async {
    final uid = usuarioId ?? defaultUserId;
    final ahora = DateTime.now();

    // Obtener todos los presupuestos del usuario (sin filtro de fecha en query)
    final snapshot =
        await _db
            .collection('presupuestos')
            .where('usuarioId', isEqualTo: uid)
            .get();

    final presupuestos = <Budget>[];

    for (var doc in snapshot.docs) {
      final presupuesto = Budget.fromFirestore(doc);

      // Filtrar activos manualmente
      final esActivo =
          presupuesto.fechaFin.isAfter(ahora) ||
          presupuesto.fechaFin.isAtSameMomentAs(ahora);

      // Verificar si aplica: activo Y (todas las categorías O categoría específica)
      if (esActivo &&
          (presupuesto.aplicaTodasCategorias ||
              presupuesto.categorias.contains(categoria))) {
        // Calcular gasto actual
        final gasto = await _calcularGastoPresupuesto(presupuesto, uid);
        presupuestos.add(presupuesto.copyWith(montoGastado: gasto));
      }
    }

    return presupuestos;
  }

  // ==================== APARTADOS ====================

  /// Obtiene todos los apartados del usuario
  Stream<List<Apartado>> obtenerApartados({String? usuarioId}) {
    final uid = usuarioId ?? defaultUserId;

    return _db
        .collection('apartados')
        .where('usuarioId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Apartado.fromFirestore(doc)).toList(),
        );
  }

  /// Obtiene apartados activos del usuario
  Stream<List<Apartado>> obtenerApartadosActivos({String? usuarioId}) {
    final uid = usuarioId ?? defaultUserId;

    return _db
        .collection('apartados')
        .where('usuarioId', isEqualTo: uid)
        .where('estado', whereIn: ['activo', 'completado'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Apartado.fromFirestore(doc)).toList(),
        );
  }

  /// Crea un nuevo apartado
  Future<String> crearApartado(Apartado apartado) async {
    final data = apartado.toFirestore(isNew: true);
    final docRef = await _db.collection('apartados').add(data);
    return docRef.id;
  }

  /// Actualiza un apartado
  Future<void> actualizarApartado(Apartado apartado) async {
    await _db
        .collection('apartados')
        .doc(apartado.id)
        .set(apartado.toFirestore(isNew: false), SetOptions(merge: true));
  }

  /// Elimina un apartado y sus abonos
  Future<void> eliminarApartado(String apartadoId) async {
    // Obtener apartado para liberar saldo retenido
    final apartadoDoc = await _db.collection('apartados').doc(apartadoId).get();
    if (apartadoDoc.exists) {
      final apartado = Apartado.fromFirestore(apartadoDoc);
      if (apartado.cuentaId != null &&
          apartado.montoApartado > 0 &&
          apartado.estado != 'pagado') {
        await _actualizarSaldoRetenido(
          apartado.cuentaId!,
          -apartado.montoApartado,
        );
      }
    }

    // Eliminar abonos subcollection
    final abonosSnap =
        await _db
            .collection('apartados')
            .doc(apartadoId)
            .collection('abonos')
            .get();
    for (var doc in abonosSnap.docs) {
      await doc.reference.delete();
    }
    // Eliminar apartado
    await _db.collection('apartados').doc(apartadoId).delete();
  }

  /// Registra un abono en un apartado
  Future<void> registrarAbono({
    required String apartadoId,
    required double monto,
    required int numeroAbono,
    String? nota,
  }) async {
    final abonoData = {
      'monto': monto,
      'numeroAbono': numeroAbono,
      'fechaAbono': FieldValue.serverTimestamp(),
      'nota': nota,
    };

    // Guardar abono en subcollección
    await _db
        .collection('apartados')
        .doc(apartadoId)
        .collection('abonos')
        .add(abonoData);

    // Obtener apartado actual
    final doc = await _db.collection('apartados').doc(apartadoId).get();
    if (!doc.exists) return;

    final apartado = Apartado.fromFirestore(doc);
    final nuevoMontoApartado = apartado.montoApartado + monto;
    final nuevosPagosRealizados = apartado.pagosRealizados + 1;
    final estaCompleto = nuevoMontoApartado >= apartado.montoTotal;

    // Calcular próximo pago
    DateTime? proximoPago;
    if (!estaCompleto) {
      proximoPago = _calcularProximoPago(DateTime.now(), apartado.frecuencia);
    }

    await _db.collection('apartados').doc(apartadoId).update({
      'montoApartado': nuevoMontoApartado,
      'pagosRealizados': nuevosPagosRealizados,
      'estado': estaCompleto ? 'completado' : 'activo',
      'fechaProximoPago':
          proximoPago != null ? Timestamp.fromDate(proximoPago) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Retener el monto del abono en la cuenta asociada
    if (apartado.cuentaId != null) {
      await _actualizarSaldoRetenido(apartado.cuentaId!, monto);
    }
  }

  /// Obtiene los abonos de un apartado
  Stream<List<Abono>> obtenerAbonos(String apartadoId) {
    return _db
        .collection('apartados')
        .doc(apartadoId)
        .collection('abonos')
        .orderBy('fechaAbono', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Abono.fromFirestore(doc)).toList(),
        );
  }

  /// Marca un apartado como pagado y registra la transacción
  Future<void> marcarApartadoComoPagado({
    required Apartado apartado,
    required Account cuenta,
  }) async {
    // 1. Registrar la transacción de pago
    final transaccion = models.Transaction(
      idTransaccion: '',
      categoria: apartado.categoria,
      descripcion: apartado.nombre,
      monto: apartado.montoTotal,
      fecha: DateTime.now().toString().substring(0, 10),
      fechaTimestamp: DateTime.now(),
      tipoTransaccion: 'Pagos',
      cuentaId: cuenta.id,
      cuentaNombre: cuenta.nombre,
      usuarioId: apartado.usuarioId,
    );

    await registrarTransaccion(transaccion: transaccion, cuenta: cuenta);

    // 2. Liberar el saldo retenido de la cuenta
    if (apartado.cuentaId != null) {
      await _actualizarSaldoRetenido(
        apartado.cuentaId!,
        -apartado.montoApartado, // Liberar todo lo retenido
      );
    }

    // 3. Actualizar estado del apartado
    await _db.collection('apartados').doc(apartado.id).update({
      'estado': 'pagado',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Si es recurrente, crear un nuevo apartado con las mismas propiedades
    if (apartado.esRecurrente) {
      final now = DateTime.now();
      DateTime proximoPago;
      switch (apartado.frecuencia) {
        case 'semanal':
          proximoPago = now.add(const Duration(days: 7));
          break;
        case 'quincenal':
          proximoPago = now.add(const Duration(days: 15));
          break;
        case 'mensual':
          proximoPago = DateTime(now.year, now.month + 1, now.day);
          break;
        default:
          proximoPago = now.add(const Duration(days: 7));
      }

      // Calcular nueva fecha límite según la frecuencia y número de pagos
      DateTime nuevaFechaLimite;
      switch (apartado.frecuencia) {
        case 'semanal':
          nuevaFechaLimite = now.add(Duration(days: 7 * apartado.numeroPagos));
          break;
        case 'quincenal':
          nuevaFechaLimite = now.add(Duration(days: 15 * apartado.numeroPagos));
          break;
        case 'mensual':
          nuevaFechaLimite = DateTime(
            now.year,
            now.month + apartado.numeroPagos,
            now.day,
          );
          break;
        default:
          nuevaFechaLimite = now.add(Duration(days: 7 * apartado.numeroPagos));
      }

      final nuevoApartado = Apartado(
        id: '',
        nombre: apartado.nombre,
        descripcion: apartado.descripcion,
        icono: apartado.icono,
        color: apartado.color,
        montoTotal: apartado.montoTotal,
        montoApartado: 0,
        numeroPagos: apartado.numeroPagos,
        pagosRealizados: 0,
        fechaLimite: nuevaFechaLimite,
        fechaProximoPago: proximoPago,
        frecuencia: apartado.frecuencia,
        estado: 'activo',
        categoria: apartado.categoria,
        cuentaId: apartado.cuentaId,
        cuentaNombre: apartado.cuentaNombre,
        esRecurrente: true,
        usuarioId: apartado.usuarioId,
      );

      await crearApartado(nuevoApartado);
    }
  }

  DateTime _calcularProximoPago(DateTime desde, String frecuencia) {
    switch (frecuencia) {
      case 'semanal':
        return desde.add(const Duration(days: 7));
      case 'quincenal':
        return desde.add(const Duration(days: 15));
      case 'mensual':
        return DateTime(desde.year, desde.month + 1, desde.day);
      default:
        return desde.add(const Duration(days: 7));
    }
  }
}
