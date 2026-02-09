class Reporte {
  final String name;
  final String file;
  final String fechaCorte;
  // Resumen financiero
  final double totalIngresos;
  final double totalGastos;
  final double saldoTotal;
  final int cantidadTransacciones;
  // Desgloses
  final Map<String, double> gastosPorCategoria;
  final Map<String, double> gastosPorCuenta;

  Reporte({
    required this.name,
    required this.file,
    required this.fechaCorte,
    this.totalIngresos = 0,
    this.totalGastos = 0,
    this.saldoTotal = 0,
    this.cantidadTransacciones = 0,
    this.gastosPorCategoria = const {},
    this.gastosPorCuenta = const {},
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      name: json['name'],
      file: json['file'],
      fechaCorte: json['fechaCorte'],
    );
  }

  /// Indica si el reporte tiene datos de resumen (reportes nuevos)
  bool get tieneResumen => totalIngresos > 0 || totalGastos > 0;

  /// Balance del mes (ingresos - gastos)
  double get balance => totalIngresos - totalGastos;
}
