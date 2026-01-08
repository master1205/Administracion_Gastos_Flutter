import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Meta.dart';
import 'package:notificaciones/models/Transaccion.dart' as models;

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
}
