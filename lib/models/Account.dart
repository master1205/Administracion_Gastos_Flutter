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
      idCuenta: json['idCuenta'],
      nombre: json['nombre'],
      saldo: json['saldo'].toDouble(),
      imagen: json['imagen'],
      beneficiario: json['beneficiario'],
      numeroTarjeta: json['numeroTarjeta'],
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
