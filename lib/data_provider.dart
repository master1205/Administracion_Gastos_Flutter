import 'package:flutter/material.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'api_service.dart';

class DataProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();

  String loadingMessage = "Consultando datos";

  late Map<String, dynamic> saldos;
  List<Account> cuentas = [];
  late Map<String, double> transaccionesCategorizadas;
  List<Reporte> reportes = [];
  List<Categoria> categorias = [];
  List<Transaction> transacciones = [];

  // Método que carga los datos de la API
  Future<void> loadData() async {
    try {
      notifyListeners();
      Future<List<Account>> cuentasFuture = apiService.fetchCuentas();
      Future<List<Reporte>> reportesFuture = apiService.fetchReportes();
      Future<List<Categoria>> categoriasFuture = apiService.fetchCategories();

      // Esperamos que todas las peticiones se completen en paralelo
      var results = await Future.wait([
        cuentasFuture,
        reportesFuture,
        categoriasFuture,
      ]);

      // Asignamos los resultados una vez que todas las peticiones se completaron
      cuentas = results[0] as List<Account>;
      reportes = results[1] as List<Reporte>;
      categorias = results[2] as List<Categoria>;
    } catch (e) {
      print("Error al cargar datos: $e");
    }
  }
}
