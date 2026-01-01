import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/models/Transaccion.dart';

class ApiService {
  final String baseUrl =
      "https://script.google.com/macros/s/AKfycbx-ZH2MGDCb_D7YfXwdd9_saoUCJaS8vyIqx60tmzsqRUbiz556KypItqyEEnc9jQOx/exec?action"; // Cambia esta URL por la de tu API

  // Método para obtener los saldos desde Google Apps Script
  Future<Map<String, dynamic>> fetchSaldos() async {
    final response = await http.get(Uri.parse('$baseUrl=getSaldos'));

    if (response.statusCode == 200) {
      // Parsear el JSON devuelto por la API
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar los saldos');
    }
  }

  Future<Map<String, double>> fetchGastosPorCategoria() async {
    final response = await http.get(
      Uri.parse('$baseUrl=getGastosPorCategoria'),
    );

    if (response.statusCode == 200) {
      // Parsear el JSON devuelto por la API
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      // Convertir los valores a double
      Map<String, double> gastosPorCategoria = jsonResponse.map((key, value) {
        return MapEntry(key, (value as num).toDouble());
      });
      return gastosPorCategoria;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, double>> fetchTransaccionesCategorizadas() async {
    final response = await http.get(Uri.parse('$baseUrl=getTransacciones'));

    if (response.statusCode == 200) {
      // Si la respuesta es exitosa (status 200), parseamos el JSON
      List<dynamic> jsonData = json.decode(response.body);

      // Crear un mapa para almacenar la suma de los montos por categoría
      Map<String, double> categorySums = {};

      // Iterar por cada transacción
      for (var transaccion in jsonData) {
        // Filtrar solo transacciones con tipo "Gasto"
        if (transaccion['tipoTransaccion'] == 'Gasto') {
          String categoria = transaccion['categoria'];
          double monto = transaccion['monto'].toDouble();

          // Si la categoría ya está en el mapa, sumamos el monto
          if (categorySums.containsKey(categoria)) {
            categorySums[categoria] = categorySums[categoria]! + monto;
          } else {
            // Si no existe la categoría, la agregamos con el monto actual
            categorySums[categoria] = monto;
          }
        }
      }

      // Ordenar las categorías alfabéticamente
      var sortedEntries =
          categorySums.entries.toList()..sort(
            (a, b) => a.key.compareTo(b.key),
          ); // Ordena por nombre de la categoría

      // Crear un nuevo mapa con las categorías ordenadas
      Map<String, double> sortedCategorySums = Map.fromEntries(sortedEntries);

      return sortedCategorySums; // Devolvemos el mapa ordenado
    } else {
      // Si ocurre un error
      throw Exception('Error al obtener los datos de transacciones');
    }
  }

  Future<List<Reporte>> fetchReportes() async {
    final response = await http.get(Uri.parse('$baseUrl=listReportes'));

    if (response.statusCode == 200) {
      // Si la respuesta es exitosa, parseamos el JSON
      final data = json.decode(response.body);

      // Convertimos el JSON en una lista de reportes
      List<dynamic> items = data['items'];
      return items.map((item) => Reporte.fromJson(item)).toList();
    } else {
      // Si ocurre un error
      throw Exception('Error al obtener los reportes');
    }
  }

  Future<List<Transaction>> fetchTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl=getTransacciones'));

    if (response.statusCode == 200) {
      // Si la respuesta es exitosa, parseamos el JSON
      List<dynamic> data = json.decode(response.body);

      // Convertimos el JSON a una lista de objetos Transaction
      return data
          .map((transaction) => Transaction.fromJson(transaction))
          .toList();
    } else {
      // Si ocurre un error
      throw Exception('Error al obtener las transacciones');
    }
  }

  Future<List<Categoria>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl=getCategorias'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Convertimos el JSON a una lista de objetos Transaction
        return data
            .map((transaction) => Categoria.fromJson(transaction))
            .toList();
      } else {
        throw Exception('Error al obtener las categorías');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Account>> fetchAccounts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl=getCuentas'));

      if (response.statusCode == 200) {
        List<Account> accounts =
            (jsonDecode(response.body) as List)
                .map((data) => Account.fromJson(data))
                .toList();
        return accounts;
      } else {
        throw Exception('Error al obtener las cuentas');
      }
    } catch (e) {
      throw Exception('Error al hacer la solicitud: $e');
    }
  }

  Future<String> eliminarFilaPorIdTransaccion(String idTransaccion) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl=deleteTransaccion'),
        body: {
          'idTransaccion': idTransaccion,
        }, // Envía el idTransaccion como parámetro
      );

      if (response.statusCode == 302) {
        var redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final response = await http.get(Uri.parse(redirectUrl));
          if (response.statusCode == 200) {
            return response.body;
          } else {
            return "No se pudo eliminar la transaccion";
          }
        }
      } else if (response.statusCode == 200) {
        return response.body;
      } else {
        return "No se pudo eliminar la transaccion";
      }
    } catch (e) {
      return e.toString();
    }

    return "";
  }

  Future<String> registerTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      // Hacer la petición POST con los datos de la transacción
      var data = json.encode(transactionData);
      final response = await http.post(
        Uri.parse('$baseUrl=addTransacciones'),
        headers: {'Content-Type': 'application/json'},
        body: data,
      );
      if (response.statusCode == 302) {
        var redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final response = await http.get(Uri.parse(redirectUrl));
          if (response.statusCode == 200) {
            return response.body;
          } else {
            return "No se pudo guardar la transaccion";
          }
        }
      } else if (response.statusCode == 200) {
        return response.body;
      } else {
        return "No se pudo guardar la transaccion";
      }
    } catch (e) {
      return e.toString();
    }

    return "";
  }

  Future<List<Account>> fetchCuentas() async {
    try {
      // Realizar la solicitud GET a la API
      final response = await http.get(Uri.parse('$baseUrl=getNuevasCuentas'));

      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, parsear el JSON
        List<dynamic> data = json.decode(response.body);

        // Convertir el JSON en una lista de mapas
        return data.map((account) => Account.fromJson(account)).toList();
      } else {
        // Si la respuesta es incorrecta, lanzar una excepción
        throw Exception('Error al cargar las cuentas');
      }
    } catch (e) {
      // Manejo de errores en caso de que algo salga mal
      throw Exception('Error al conectar con la API: $e');
    }
  }
}
