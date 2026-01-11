import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Meta.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/models/api_response.dart';
import 'package:notificaciones/services/firestore_service.dart';

/// Wrapper simplificado sobre FirestoreService
/// Nota: Esta clase existe solo por compatibilidad con código legacy.
/// Se recomienda usar FirestoreService directamente en código nuevo.
class ApiService {
  // Instancia de FirestoreService
  final FirestoreService _firestoreService = FirestoreService();

  // ==================== TRANSACCIONES ====================

  /// Registrar transacción
  Future<String> registerTransaction(
    Transaction transaccion, {
    Account? cuenta,
    Account? cuentaOrigen,
    Account? cuentaDestino,
  }) async {
    try {
      return await _firestoreService.registrarTransaccion(
        transaccion: transaccion,
        cuenta: cuenta,
        cuentaOrigen: cuentaOrigen,
        cuentaDestino: cuentaDestino,
      );
    } catch (e) {
      throw ApiException('Error al registrar transacción: $e');
    }
  }

  /// Eliminar transacción por ID
  Future<void> eliminarFilaPorIdTransaccion(String transaccionId) async {
    try {
      await _firestoreService.eliminarTransaccion(transaccionId);
    } catch (e) {
      throw ApiException('Error al eliminar transacción: $e');
    }
  }

  // ==================== CUENTAS ====================

  /// Crear una nueva cuenta
  Future<String> crearCuenta({
    required String nombre,
    String imagen = '',
    String beneficiario = '',
    String? numeroTarjeta,
    String tipo = 'efectivo',
    double saldoInicial = 0,
  }) async {
    try {
      final nuevaCuenta = Account(
        id: '',
        nombre: nombre,
        saldo: saldoInicial,
        imagen: imagen,
        beneficiario: beneficiario,
        numeroTarjeta: numeroTarjeta,
        tipo: tipo,
        activa: true,
      );

      return await _firestoreService.crearCuenta(nuevaCuenta);
    } catch (e) {
      throw ApiException('Error al crear cuenta: $e');
    }
  }

  /// Actualizar saldo de cuenta
  Future<void> updateAccountBalance({
    required String cuentaId,
    required double nuevoSaldo,
  }) async {
    try {
      await _firestoreService.actualizarSaldoCuenta(cuentaId, nuevoSaldo);
    } catch (e) {
      throw ApiException('Error al actualizar saldo: $e');
    }
  }

  /// Eliminar cuenta
  Future<void> eliminarCuenta(String cuentaId) async {
    try {
      await _firestoreService.eliminarCuenta(cuentaId);
    } catch (e) {
      throw ApiException('Error al eliminar cuenta: $e');
    }
  }

  // ==================== METAS ====================

  /// Guardar o actualizar meta
  Future<String> saveMeta(Meta meta) async {
    try {
      if (meta.id.isEmpty) {
        return await _firestoreService.crearMeta(meta, null);
      } else {
        await _firestoreService.actualizarMeta(meta);
        return meta.id;
      }
    } catch (e) {
      throw ApiException('Error al guardar meta: $e');
    }
  }

  /// Eliminar meta
  Future<void> deleteMeta(String metaId) async {
    try {
      await _firestoreService.eliminarMeta(metaId);
    } catch (e) {
      throw ApiException('Error al eliminar meta: $e');
    }
  }
}
