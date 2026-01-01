class Categoria {
  final int? idCategoria;
  final String categoria;
  final String imagen;
  final String tipoTransaccion;

  Categoria({
    this.idCategoria,
    required this.categoria,
    required this.imagen,
    required this.tipoTransaccion,
  });

  // Método para crear un objeto Category a partir de un JSON
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['idCategoria'],
      categoria: json['categoria'],
      imagen: json['imagen'],
      tipoTransaccion: json['tipoTransaccion'],
    );
  }

  // Método para convertir un objeto Category a JSON
  Map<String, dynamic> toJson() {
    return {
      'idCategoria': idCategoria,
      'categoria': categoria,
      'imagen': imagen,
      'tipoTransaccion': tipoTransaccion,
    };
  }
}
