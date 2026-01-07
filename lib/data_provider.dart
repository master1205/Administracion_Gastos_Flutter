import 'package:flutter/material.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'api_service.dart';
import 'dart:async';

class DataProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();

  String loadingMessage = "Consultando datos";

  late Map<String, dynamic> saldos;
  List<Account> cuentas = [];
  late Map<String, double> transaccionesCategorizadas;
  List<Reporte> reportes = [];
  List<Categoria> categorias = [];
  List<Transaction> transacciones = [];

  // Subscripciones a streams
  StreamSubscription<List<Account>>? _cuentasSubscription;

  @override
  void dispose() {
    _cuentasSubscription?.cancel();
    super.dispose();
  }

  // Método que carga los datos de la API
  Future<void> loadData() async {
    try {
      notifyListeners();

      // Cancelar subscripción anterior si existe
      await _cuentasSubscription?.cancel();

      // Suscribirse al stream de cuentas para actualizaciones en tiempo real
      _cuentasSubscription = _firestoreService.obtenerCuentas().listen((
        cuentasActualizadas,
      ) {
        cuentas = cuentasActualizadas;
        notifyListeners();
      });

      // Cargar reportes y categorías (estos no cambian frecuentemente)
      //Future<List<Reporte>> reportesFuture = apiService.fetchReportes();
      Future<List<Categoria>> categoriasFuture = apiService.fetchCategories();

      // Esperamos que todas las peticiones se completen en paralelo
      var results = await Future.wait([categoriasFuture]);

      // Asignamos los resultados una vez que todas las peticiones se completaron
      categorias = results[0];
    } catch (e) {
      print("Error al cargar datos: $e");
    }
  }
}
