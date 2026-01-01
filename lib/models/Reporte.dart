class Reporte {
  final String name;
  final String file;
  final String fechaCorte;

  Reporte({required this.name, required this.file, required this.fechaCorte});

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      name: json['name'],
      file: json['file'],
      fechaCorte: json['fechaCorte'],
    );
  }
}