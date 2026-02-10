import 'package:flutter/material.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Apartado.dart';
import 'package:notificaciones/models/Budget.dart';
import 'package:notificaciones/models/Meta.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'api_service.dart';
import 'dart:async';

class DataProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();

  String loadingMessage = "Consultando datos";

  // ── Datos centralizados ──
  List<Account> cuentas = [];
  List<Transaction> transacciones = [];
  List<Meta> metas = [];
  List<Budget> presupuestosActivos = [];
  List<Budget> todosPresupuestos = [];
  List<Apartado> apartados = [];
  List<Apartado> apartadosActivos = [];
  List<Map<String, dynamic>> categorias = [];
  List<Reporte> reportes = [];

  // ── Estado de carga ──
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ── Getters de conteo (para badges en HomeScreen) ──
  int get cantidadMetas => metas.length;
  int get cantidadPresupuestos => presupuestosActivos.length;
  int get cantidadApartados => apartadosActivos.length;

  // ── Subscripciones a streams ──
  StreamSubscription<List<Account>>? _cuentasSubscription;
  StreamSubscription<List<Transaction>>? _transaccionesSubscription;
  StreamSubscription<List<Meta>>? _metasSubscription;
  StreamSubscription<List<Budget>>? _presupuestosSubscription;
  StreamSubscription<List<Budget>>? _todosPresupuestosSubscription;
  StreamSubscription<List<Apartado>>? _apartadosSubscription;
  StreamSubscription<List<Apartado>>? _apartadosActivosSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _categoriasSubscription;
  StreamSubscription<List<Reporte>>? _reportesSubscription;

  @override
  void dispose() {
    _cuentasSubscription?.cancel();
    _transaccionesSubscription?.cancel();
    _metasSubscription?.cancel();
    _presupuestosSubscription?.cancel();
    _todosPresupuestosSubscription?.cancel();
    _apartadosSubscription?.cancel();
    _apartadosActivosSubscription?.cancel();
    _categoriasSubscription?.cancel();
    _reportesSubscription?.cancel();
    super.dispose();
  }

  /// Inicializa todos los streams de Firestore.
  /// Llamar una sola vez desde LoadingScreen o al iniciar la app.
  Future<void> loadData() async {
    try {
      // Cancelar subscripciones anteriores
      _cuentasSubscription?.cancel();
      _transaccionesSubscription?.cancel();
      _metasSubscription?.cancel();
      _presupuestosSubscription?.cancel();
      _todosPresupuestosSubscription?.cancel();
      _apartadosSubscription?.cancel();
      _apartadosActivosSubscription?.cancel();
      _categoriasSubscription?.cancel();
      _reportesSubscription?.cancel();

      // ── Cuentas ──
      _cuentasSubscription = _firestoreService.obtenerCuentas().listen((data) {
        cuentas = data;
        notifyListeners();
      });

      // ── Transacciones (últimos 30 días) ──
      _transaccionesSubscription = _firestoreService
          .obtenerTransaccionesRecientes()
          .listen((data) {
            transacciones = data;
            notifyListeners();
          });

      // ── Metas ──
      _metasSubscription = _firestoreService.obtenerMetas().listen((data) {
        metas = data;
        notifyListeners();
      });

      // ── Presupuestos activos ──
      _presupuestosSubscription = _firestoreService
          .obtenerPresupuestosActivos()
          .listen((data) {
            presupuestosActivos = data;
            notifyListeners();
          });

      // ── Todos los presupuestos ──
      _todosPresupuestosSubscription = _firestoreService
          .obtenerTodosPresupuestos()
          .listen((data) {
            todosPresupuestos = data;
            notifyListeners();
          });

      // ── Todos los apartados ──
      _apartadosSubscription = _firestoreService.obtenerApartados().listen((
        data,
      ) {
        apartados = data;
        notifyListeners();
      });

      // ── Apartados activos (para conteo y dashboard) ──
      _apartadosActivosSubscription = _firestoreService
          .obtenerApartadosActivos()
          .listen((data) {
            apartadosActivos = data;
            notifyListeners();
          });

      // ── Categorías ──
      _categoriasSubscription = _firestoreService.obtenerCategorias().listen((
        data,
      ) {
        categorias = data;
        notifyListeners();
      });

      // ── Reportes ──
      _reportesSubscription = _firestoreService.obtenerReportes().listen((
        data,
      ) {
        reportes = data;
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error al cargar datos: $e");
    }
  }
}
