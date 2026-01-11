import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Meta.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/models/api_response.dart';
import 'package:notificaciones/services/firestore_service.dart';

class ApiService {
  final String baseUrl =
      "https://script.google.com/macros/s/AKfycbyrz_gkYboT5mc_R2UC8zWBycuc8i29yAmiPUn04lJ6dYyyxfiMgDsLFMYW3KnxUgW_/exec?action";

  // Instancia de FirestoreService para operaciones en tiempo real
  final FirestoreService _firestoreService = FirestoreService();

  /// Método auxiliar para manejar respuestas de la API
  T _handleApiResponse<T>(String responseBody, T Function(dynamic) dataParser) {
    final json = jsonDecode(responseBody);
    final apiResponse = ApiResponse<T>.fromJson(json, dataParser);

    if (apiResponse.isSuccess) {
      if (apiResponse.data != null) {
        return apiResponse.data as T;
      }
      throw ApiException('Respuesta exitosa pero sin datos');
    } else {
      throw ApiException(apiResponse.msgE, errorCode: apiResponse.codE);
    }
  }

  // ==================== MÉTODOS GET ====================

  /// Obtener reportes
  Future<List<Reporte>> fetchReportes() async {
    try {
      final url = '$baseUrl=listReportes';
      print('📡 Llamando a: $url'); // Debug
      final response = await http.get(Uri.parse(url));

      print('📥 Status: ${response.statusCode}'); // Debug
      print('📥 Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        return _handleApiResponse<List<Reporte>>(response.body, (data) {
          // El backend puede devolver directamente una lista o un objeto con 'items'
          List<dynamic> jsonData;
          if (data is List) {
            jsonData = data;
          } else if (data is Map && data.containsKey('items')) {
            jsonData = data['items'] as List<dynamic>;
          } else {
            throw ApiException('Formato de respuesta inesperado');
          }
          return jsonData.map((item) => Reporte.fromJson(item)).toList();
        });
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al obtener reportes: $e');
    }
  }

  /// Obtener transacciones - AHORA USA FIREBASE
  Future<List<Transaction>> fetchTransactions() async {
    try {
      // Obtener del mes actual desde Firebase (mucho más rápido)
      final stream = _firestoreService.obtenerTransaccionesRecientes();
      return await stream.first;
    } catch (e) {
      throw ApiException('Error al obtener transacciones desde Firebase: $e');
    }
  }

  // ==================== FIREBASE WRAPPERS ====================

  /// Obtener todas las metas desde Firebase
  Future<List<Meta>> getMetas() async {
    try {
      final stream = _firestoreService.obtenerMetas();
      return await stream.first;
    } catch (e) {
      throw ApiException('Error al obtener metas desde Firebase: $e');
    }
  }

  /// Obtener cuentas desde Firebase
  Future<List<Account>> fetchCuentas() async {
    try {
      final stream = _firestoreService.obtenerCuentas();
      return await stream.first;
    } catch (e) {
      throw ApiException('Error al cargar cuentas desde Firebase: $e');
    }
  }

  /// Registrar transacción - USA FIREBASE DIRECTAMENTE
  /// Nota: Este método ahora espera un objeto Transaction, no un Map
  Future<String> registerTransaction(
    Transaction transaccion, {
    Account? cuenta,
    Account? cuentaOrigen,
    Account? cuentaDestino,
  }) async {
    try {
      // Guardar directamente en Firebase
      final transaccionId = await _firestoreService.registrarTransaccion(
        transaccion: transaccion,
        cuenta: cuenta,
        cuentaOrigen: cuentaOrigen,
        cuentaDestino: cuentaDestino,
      );

      return transaccionId;
    } catch (e) {
      throw ApiException('Error al registrar transacción en Firebase: $e');
    }
  }

  /// Eliminar transacción por ID - USA FIREBASE
  Future<void> eliminarFilaPorIdTransaccion(String transaccionId) async {
    try {
      await _firestoreService.eliminarTransaccion(transaccionId);
    } catch (e) {
      throw ApiException('Error al eliminar transacción en Firebase: $e');
    }
  }

  /// Actualizar saldo de cuenta - AHORA USA FIREBASE
  Future<void> updateAccountBalance({
    required String cuentaId,
    required double nuevoSaldo,
  }) async {
    try {
      await _firestoreService.actualizarSaldoCuenta(cuentaId, nuevoSaldo);
    } catch (e) {
      throw ApiException('Error al actualizar saldo en Firebase: $e');
    }
  }

  /// Crear una nueva cuenta - AHORA USA FIREBASE
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
        id: '', // Firebase genera el ID
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
      throw ApiException('Error al crear cuenta en Firebase: $e');
    }
  }

  /// Eliminar cuenta - AHORA USA FIREBASE
  Future<void> eliminarCuenta(String cuentaId) async {
    try {
      await _firestoreService.eliminarCuenta(cuentaId);
    } catch (e) {
      throw ApiException('Error al eliminar cuenta en Firebase: $e');
    }
  }

  // ==================== METAS DE AHORRO ====================

  /// Guardar o actualizar meta - AHORA USA FIREBASE
  Future<String> saveMeta(Meta meta) async {
    try {
      if (meta.id.isEmpty) {
        // Crear nueva meta
        return await _firestoreService.crearMeta(meta, null);
      } else {
        // Actualizar meta existente
        await _firestoreService.actualizarMeta(meta);
        return meta.id;
      }
    } catch (e) {
      throw ApiException('Error al guardar meta en Firebase: $e');
    }
  }

  /// Eliminar meta - AHORA USA FIREBASE
  Future<void> deleteMeta(String metaId) async {
    try {
      await _firestoreService.eliminarMeta(metaId);
    } catch (e) {
      throw ApiException('Error al eliminar meta en Firebase: $e');
    }
  }

  /// Actualizar progreso de meta - AHORA USA FIREBASE
  Future<void> updateMetaProgress(String metaId, double montoActual) async {
    try {
      await _firestoreService.actualizarAvanceMeta(metaId, montoActual);
    } catch (e) {
      throw ApiException(
        'Error al actualizar progreso de meta en Firebase: $e',
      );
    }
  }
}
