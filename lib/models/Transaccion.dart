class Transaction {
  final String idTransaccion;
  final String categoria;
  final String descripcion;
  final double monto;
  final String fecha;
  final String tipoTransaccion;
  final String cuenta;
  final String cuentaOrigen;
  final String cuentaDestino;

  Transaction({
    required this.idTransaccion,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.tipoTransaccion,
    this.cuenta = '',
    this.cuentaOrigen = '',
    this.cuentaDestino = '',
  });

  // Factory constructor para convertir el JSON a un objeto Transaction
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      idTransaccion: json['idTransaccion'],
      categoria: json['categoria'],
      descripcion: json['descripcion'],
      monto: json['monto'].toDouble(),
      fecha: json['fecha'],
      tipoTransaccion: json['tipoTransaccion'],
      cuenta: json['cuenta'],
      cuentaOrigen: json['cuentaOrigen'],
      cuentaDestino: json['cuentaDestino'],
    );
  }
}
