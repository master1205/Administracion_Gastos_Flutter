class Account {
  final int? idCuenta;
  final String nombre;
  final double? saldo;
  final String? imagen;
  final String? beneficiario;
  final String? numeroTarjeta;

  Account({
    this.idCuenta,
    required this.nombre,
    this.saldo,
    this.imagen,
    this.beneficiario,
    this.numeroTarjeta,
  });

  // Método para crear una instancia de Account desde un JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      idCuenta:
          json['idCuenta'] is int
              ? json['idCuenta']
              : int.tryParse(json['idCuenta']?.toString() ?? '0'),
      nombre: json['nombre']?.toString() ?? '',
      saldo:
          json['saldo'] is double
              ? json['saldo']
              : (json['saldo'] is int
                  ? (json['saldo'] as int).toDouble()
                  : double.tryParse(json['saldo']?.toString() ?? '0') ?? 0.0),
      imagen: json['imagen']?.toString(),
      beneficiario: json['beneficiario']?.toString(),
      numeroTarjeta: json['numeroTarjeta']?.toString(),
    );
  }

  // Método para convertir una instancia de Account a un Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'idCuenta': idCuenta,
      'nombre': nombre,
      'saldo': saldo,
      'imagen': imagen,
      'beneficiario': beneficiario,
      'numeroTarjeta': numeroTarjeta,
    };
  }
}
