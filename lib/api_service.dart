import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/models/api_response.dart';

class ApiService {
  final String baseUrl =
      "https://script.google.com/macros/s/AKfycbxc2QugLHMIjNK7FWH6VrkDCGx_1sig4M8CmPJodwSg3h1NEebIbpxm_kS3niTPmEWB7Q/exec?action";

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

  /// Método auxiliar para respuestas que solo retornan mensaje (sin data)
  ApiResponse<void> _handleApiResponseMessage(String responseBody) {
    final json = jsonDecode(responseBody);
    final apiResponse = ApiResponse<void>.fromJson(json, null);

    if (!apiResponse.isSuccess) {
      throw ApiException(apiResponse.msgE, errorCode: apiResponse.codE);
    }

    return apiResponse;
  }

  // ==================== MÉTODOS GET ====================

  /// Obtener los saldos desde Google Apps Script
  Future<Map<String, dynamic>> fetchSaldos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl=getSaldos'));

      if (response.statusCode == 200) {
        return _handleApiResponse<Map<String, dynamic>>(
          response.body,
          (data) => data as Map<String, dynamic>,
        );
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al obtener los saldos: $e');
    }
  }

  /// Obtener gastos por categoría
  Future<Map<String, double>> fetchGastosPorCategoria() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl=getGastosPorCategoria'),
      );

      if (response.statusCode == 200) {
        return _handleApiResponse<Map<String, double>>(response.body, (data) {
          Map<String, dynamic> jsonData = data as Map<String, dynamic>;
          return jsonData.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        });
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al obtener gastos por categoría: $e');
    }
  }

  /// Obtener transacciones categorizadas
  Future<Map<String, double>> fetchTransaccionesCategorizadas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl=getTransacciones'));

      if (response.statusCode == 200) {
        return _handleApiResponse<Map<String, double>>(response.body, (data) {
          List<dynamic> jsonData = data as List<dynamic>;

          // Crear un mapa para almacenar la suma de los montos por categoría
          Map<String, double> transaccionesPorCategoria = {};

          for (var transaction in jsonData) {
            String categoria = transaction['categoria'] ?? 'Sin Categoría';
            double monto = (transaction['monto'] as num).toDouble();

            // Sumar el monto a la categoría correspondiente
            if (transaccionesPorCategoria.containsKey(categoria)) {
              transaccionesPorCategoria[categoria] =
                  transaccionesPorCategoria[categoria]! + monto;
            } else {
              transaccionesPorCategoria[categoria] = monto;
            }
          }

          return transaccionesPorCategoria;
        });
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al obtener transacciones categorizadas: $e');
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

  /// Obtener transacciones
  Future<List<Transaction>> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl=getTransacciones'));

      if (response.statusCode == 200) {
        return _handleApiResponse<List<Transaction>>(response.body, (data) {
          List<dynamic> jsonData = data as List<dynamic>;
          return jsonData
              .map((transaction) => Transaction.fromJson(transaction))
              .toList();
        });
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al obtener las transacciones: $e');
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

  /// Obtener cuentas
  Future<List<Account>> fetchAccounts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl=getCuentas'));

      if (response.statusCode == 200) {
        return _handleApiResponse<List<Account>>(response.body, (data) {
          List<dynamic> jsonData = data as List<dynamic>;
          return jsonData.map((account) => Account.fromJson(account)).toList();
        });
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al obtener las cuentas: $e');
    }
  }

  /// Obtener nuevas cuentas
  Future<List<Account>> fetchCuentas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl=getNuevasCuentas'));

      if (response.statusCode == 200) {
        return _handleApiResponse<List<Account>>(response.body, (data) {
          List<dynamic> jsonData = data as List<dynamic>;
          return jsonData.map((account) => Account.fromJson(account)).toList();
        });
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al cargar las cuentas: $e');
    }
  }

  // ==================== MÉTODOS POST ====================

  /// Registrar transacción
  Future<ApiResponse<void>> registerTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      var data = json.encode(transactionData);
      final response = await http.post(
        Uri.parse('$baseUrl=addTransacciones'),
        headers: {'Content-Type': 'application/json'},
        body: data,
      );

      // Manejar redirecciones 302
      if (response.statusCode == 302) {
        var redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            return _handleApiResponseMessage(redirectResponse.body);
          } else {
            throw ApiException(
              'Error en redirección: ${redirectResponse.statusCode}',
            );
          }
        } else {
          throw ApiException('Redirección sin URL');
        }
      } else if (response.statusCode == 200) {
        return _handleApiResponseMessage(response.body);
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al guardar la transacción: $e');
    }
  }

  /// Eliminar transacción por ID
  Future<ApiResponse<void>> eliminarFilaPorIdTransaccion(
    String idTransaccion,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl=deleteTransaccion'),
        body: {'idTransaccion': idTransaccion},
      );

      // Manejar redirecciones 302
      if (response.statusCode == 302) {
        var redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            return _handleApiResponseMessage(redirectResponse.body);
          } else {
            throw ApiException(
              'Error en redirección: ${redirectResponse.statusCode}',
            );
          }
        } else {
          throw ApiException('Redirección sin URL');
        }
      } else if (response.statusCode == 200) {
        return _handleApiResponseMessage(response.body);
      } else {
        throw ApiException('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al eliminar la transacción: $e');
    }
  }
}
