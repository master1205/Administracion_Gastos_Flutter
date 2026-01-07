import 'package:flutter/material.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/models/api_response.dart';
import 'package:notificaciones/models/Transaccion.dart' as models;

/// Ejemplos de uso de la nueva estructura de respuestas API

// ============================================
// EJEMPLO 1: Obtener Datos (GET)
// ============================================

Future<void> ejemploObtenerDatos() async {
  final apiService = ApiService();

  try {
    // Obtener transacciones
    final transacciones = await apiService.fetchTransactions();
    print('✅ Se obtuvieron ${transacciones.length} transacciones');

    // Obtener saldos
    final saldos = await apiService.fetchSaldos();
    print('✅ Saldos: $saldos');

    // Obtener gastos por categoría
    final gastos = await apiService.fetchGastosPorCategoria();
    print('✅ Gastos por categoría: $gastos');
  } on ApiException catch (e) {
    // Manejo de errores de la API
    print('❌ Error de API: ${e.message}');
    print('Código de error: ${e.errorCode}');
  } catch (e) {
    // Otros errores
    print('❌ Error inesperado: $e');
  }
}

// ============================================
// EJEMPLO 2: Registrar Transacción (POST)
// ============================================

Future<void> ejemploRegistrarTransaccion(BuildContext context) async {
  final apiService = ApiService();

  final transaccionData = {
    'monto': 1500.0,
    'descripcion': 'Compra de supermercado',
    'fecha': '2024-01-15',
    'tipoTransaccion': 'Egreso',
    'categoria': 'Alimentos',
    'cuenta': 'Efectivo',
  };

  try {
    // Registrar la transacción
    final transaccion = models.Transaction.fromJson(transaccionData);
    final transaccionId = await apiService.registerTransaction(transaccion);

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text('Transacción registrada exitosamente'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  } on ApiException catch (e) {
    // Mostrar error específico de la API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(e.message)), // ✅ Mensaje de error del servidor
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    // Error inesperado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error inesperado: $e'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// ============================================
// EJEMPLO 3: Eliminar Transacción (POST)
// ============================================

Future<void> ejemploEliminarTransaccion(
  BuildContext context,
  String idTransaccion,
) async {
  final apiService = ApiService();

  try {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Estás seguro de eliminar esta transacción?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    // Eliminar la transacción
    await apiService.eliminarFilaPorIdTransaccion(idTransaccion);

    // Mostrar mensaje de éxito
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text('Transacción eliminada exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } on ApiException catch (e) {
    // Error de la API
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }
}

// ============================================
// EJEMPLO 4: Manejo de Carga con Estado
// ============================================

class EjemploWidget extends StatefulWidget {
  const EjemploWidget({super.key});

  @override
  State<EjemploWidget> createState() => _EjemploWidgetState();
}

class _EjemploWidgetState extends State<EjemploWidget> {
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final saldos = await _apiService.fetchSaldos();
      // Procesar datos...
      print('Datos cargados: $saldos');
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message; // ✅ Mensaje descriptivo del servidor
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejemplo API')),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : _errorMessage != null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargarDatos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
                : ElevatedButton(
                  onPressed: _cargarDatos,
                  child: const Text('Cargar Datos'),
                ),
      ),
    );
  }
}

// ============================================
// EJEMPLO 5: Validación de Saldo Insuficiente
// ============================================

Future<void> ejemploTraspasoConValidacion(BuildContext context) async {
  final apiService = ApiService();

  final traspasoData = {
    'monto': 5000.0,
    'descripcion': 'Traspaso a ahorros',
    'fecha': '2024-01-15',
    'tipoTransaccion': 'Traspasos',
    'cuentaOrigen': 'Efectivo',
    'cuentaDestino': 'Ahorros',
  };

  try {
    final transaccion = models.Transaction.fromJson(traspasoData);
    final transaccionId = await apiService.registerTransaction(transaccion);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Traspaso registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      // El backend ya validó el saldo y envió un mensaje descriptivo
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Error en Traspaso'),
                ],
              ),
              content: Text(
                e.message,
              ), // ✅ "Saldo insuficiente en la cuenta de origen"
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
      );
    }
  }
}

// ============================================
// EJEMPLO 6: Múltiples Llamadas con Validación
// ============================================

Future<Map<String, dynamic>> ejemploCargaCompleta() async {
  final apiService = ApiService();

  try {
    // Cargar múltiples datos en paralelo
    final results = await Future.wait([
      apiService.fetchSaldos(),
      apiService.fetchTransactions(),
      apiService.fetchCategories(),
      apiService.fetchAccounts(),
    ]);

    return {
      'saldos': results[0],
      'transacciones': results[1],
      'categorias': results[2],
      'cuentas': results[3],
      'success': true,
    };
  } on ApiException catch (e) {
    return {'success': false, 'error': e.message, 'errorCode': e.errorCode};
  } catch (e) {
    return {'success': false, 'error': 'Error inesperado: $e'};
  }
}
