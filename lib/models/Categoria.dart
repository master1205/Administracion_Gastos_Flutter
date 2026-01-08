class Categoria {
  final String? id; // ID de Firebase
  final int? idCategoria; // Mantener por compatibilidad legacy
  final String categoria;
  final String imagen;
  final String tipoTransaccion;

  Categoria({
    this.id,
    this.idCategoria,
    required this.categoria,
    required this.imagen,
    required this.tipoTransaccion,
  });

  // Método para crear un objeto Category a partir de un JSON
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      idCategoria: json['idCategoria'],
      categoria: json['categoria'] ?? '',
      imagen: json['imagen'] ?? 'category',
      tipoTransaccion: json['tipoTransaccion'] ?? 'Gasto',
    );
  }

  // Método para convertir un objeto Category a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idCategoria != null) 'idCategoria': idCategoria,
      'categoria': categoria,
      'imagen': imagen,
      'tipoTransaccion': tipoTransaccion,
    };
  }
}
