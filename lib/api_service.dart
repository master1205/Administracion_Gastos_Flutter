import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/models/Meta.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/models/api_response.dart';
import 'package:notificaciones/services/firestore_service.dart';

class ApiService {
  final String baseUrl =
      "https://script.google.com/macros/s/AKfycbyl3CrDkwagnzKckvdPlQc_k_YFdice0ArfRwN5NA5huW_JtIVABLwiVWyKOvleIbz4/exec?action";

  // Instancia de FirestoreService para operaciones en tiempo real
  final FirestoreService _firestoreService = FirestoreService();

  // ==================== CACHE ====================

  /// Limpia el caché de Firebase y fuerza sincronización
  Future<void> limpiarCacheFirebase() async {
    try {
      await _firestoreService.limpiarCache();
    } catch (e) {
      throw ApiException('Error al limpiar caché de Firebase: $e');
    }
  }

  /// Obtiene cuentas directamente del servidor (sin caché)
  Future<List<Account>> fetchCuentasDesdeServidor() async {
    try {
      return await _firestoreService.obtenerCuentasDesdeServidor();
    } catch (e) {
      throw ApiException('Error al obtener cuentas desde servidor: $e');
    }
  }

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

  /// Obtener los saldos - AHORA USA FIREBASE
  Future<Map<String, dynamic>> fetchSaldos() async {
    try {
      // Obtener todas las cuentas activas desde Firebase
      final cuentas = await _firestoreService.obtenerCuentas().first;

      Map<String, dynamic> saldos = {};
      for (var cuenta in cuentas) {
        saldos[cuenta.nombre] = cuenta.saldo;
      }

      return saldos;
    } catch (e) {
      throw ApiException('Error al obtener saldos desde Firebase: $e');
    }
  }

  /// Obtener gastos por categoría - AHORA USA FIREBASE
  Future<Map<String, double>> fetchGastosPorCategoria() async {
    try {
      return await _firestoreService.obtenerGastosPorCategoriaMesActual();
    } catch (e) {
      throw ApiException(
        'Error al obtener gastos por categoría desde Firebase: $e',
      );
    }
  }

  /// Obtener transacciones categorizadas - AHORA USA FIREBASE
  Future<Map<String, double>> fetchTransaccionesCategorizadas() async {
    try {
      // Obtener transacciones del mes actual
      final transacciones =
          await _firestoreService.obtenerTransaccionesRecientes().first;

      Map<String, double> transaccionesPorCategoria = {};

      for (var transaccion in transacciones) {
        String categoria =
            transaccion.categoria.isNotEmpty
                ? transaccion.categoria
                : 'Sin Categoría';
        double monto = transaccion.monto;

        // Sumar el monto a la categoría correspondiente
        if (transaccionesPorCategoria.containsKey(categoria)) {
          transaccionesPorCategoria[categoria] =
              transaccionesPorCategoria[categoria]! + monto;
        } else {
          transaccionesPorCategoria[categoria] = monto;
        }
      }

      return transaccionesPorCategoria;
    } catch (e) {
      throw ApiException(
        'Error al obtener transacciones categorizadas desde Firebase: $e',
      );
    }
  }

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

  /// Obtener categorías
  Future<List<Categoria>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl=getCategorias'));

      if (response.statusCode == 200) {
        return _handleApiResponse<List<Categoria>>(response.body, (data) {
          List<dynamic> jsonData = data as List<dynamic>;
          return jsonData
              .map((categoria) => Categoria.fromJson(categoria))
              .toList();
        });
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al obtener las categorías: $e');
    }
  }

  /// Obtener cuentas - AHORA USA FIREBASE
  Future<List<Account>> fetchAccounts() async {
    try {
      // Obtener desde Firebase (tiempo real)
      final stream = _firestoreService.obtenerCuentas();
      return await stream.first;
    } catch (e) {
      throw ApiException('Error al obtener cuentas desde Firebase: $e');
    }
  }

  /// Obtener nuevas cuentas - AHORA USA FIREBASE (no necesita caché, Firebase es rápido)
  Future<List<Account>> fetchCuentas({bool forceRefresh = false}) async {
    try {
      // Firebase es tan rápido que no necesitamos caché local
      final stream = _firestoreService.obtenerCuentas();
      return await stream.first;
    } catch (e) {
      throw ApiException('Error al cargar cuentas desde Firebase: $e');
    }
  }

  // ==================== MÉTODOS POST ====================

  /// Obtener todas las metas - AHORA USA FIREBASE (no necesita caché)
  Future<List<Meta>> getMetas({bool forceRefresh = false}) async {
    try {
      // Firebase es rápido, no necesitamos caché local
      final stream = _firestoreService.obtenerMetas();
      return await stream.first;
    } catch (e) {
      throw ApiException('Error al obtener metas desde Firebase: $e');
    }
  }

  /// Obtener todos los datos del dashboard - AHORA USA FIREBASE
  Future<Map<String, dynamic>> getDashboardData({
    bool forceRefresh = false,
  }) async {
    try {
      // Obtener datos del mes actual desde Firebase
      final gastosPorCategoria =
          await _firestoreService.obtenerGastosPorCategoriaMesActual();
      final ingresosMes = await _firestoreService.obtenerIngresosMesActual();
      final cuentasStream = _firestoreService.obtenerCuentas();
      final cuentas = await cuentasStream.first;

      // Calcular totales
      final totalGastos = gastosPorCategoria.values.fold(
        0.0,
        (sum, monto) => sum + monto,
      );
      final saldoTotal = cuentas.fold(0.0, (sum, cuenta) => sum + cuenta.saldo);

      return {
        'gastosPorCategoria': gastosPorCategoria,
        'totalGastos': totalGastos,
        'totalIngresos': ingresosMes,
        'saldoTotal': saldoTotal,
        'cuentas': cuentas.map((c) => c.toJson()).toList(),
      };
    } catch (e) {
      throw ApiException(
        'Error al cargar datos del dashboard desde Firebase: $e',
      );
    }
  }

  /// Registrar transacción - AHORA USA FIREBASE DIRECTAMENTE
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

  /// Enviar transacción a Google Sheets (para sincronización)
  Future<void> enviarTransaccionASheets(Transaction transaccion) async {
    try {
      // Usar cargarTransacciones que acepta JSON en el body
      final url =
          'https://script.google.com/macros/s/AKfycbyl3CrDkwagnzKckvdPlQc_k_YFdice0ArfRwN5NA5huW_JtIVABLwiVWyKOvleIbz4/exec';

      // Formato que espera cargarTransacciones (JSON en postData.contents)
      final datos = {
        'idTransaccion': transaccion.idTransaccion,
        'tipoTransaccion': transaccion.tipoTransaccion,
        'monto': transaccion.monto,
        'descripcion': transaccion.descripcion,
        'fecha': transaccion.fecha,
        'categoria': transaccion.categoria,
        'cuenta': transaccion.cuenta,
        'cuentaOrigen': transaccion.cuentaOrigen,
        'cuentaDestino': transaccion.cuentaDestino,
      };

      print('📤 Enviando a Sheets: $url?action=addTransaccion');
      print('📦 Datos: ${jsonEncode(datos)}');

      // Usar HttpClient para seguir redirects automáticamente
      final uri = Uri.parse('$url?action=addTransaccion');
      final request = await HttpClient().postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(datos));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: $responseBody');

      if (response.statusCode != 200) {
        throw ApiException('Error HTTP ${response.statusCode}: $responseBody');
      }

      final json = jsonDecode(responseBody);
      // El backend devuelve codE: 0 para éxito
      if (json['codE'] != 0) {
        throw ApiException(
          json['msgE'] ?? 'Error desconocido al enviar a Sheets',
        );
      }

      print('✅ Transacción enviada exitosamente a Sheets');
    } catch (e) {
      print('❌ Error al enviar transacción a Sheets: $e');
      throw ApiException('Error al enviar transacción a Sheets: $e');
    }
  }

  /// Eliminar transacción por ID - AHORA USA FIREBASE
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
