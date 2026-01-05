class Meta {
  final String id;
  final String nombre;
  final String descripcion;
  final double montoObjetivo;
  final double montoActual;
  final String fechaInicio;
  final String fechaObjetivo;
  final String icono;
  final String color;
  final bool completada;
  final String? numeroCuenta; // Número de cuenta asociada

  Meta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.montoObjetivo,
    required this.montoActual,
    required this.fechaInicio,
    required this.fechaObjetivo,
    required this.icono,
    required this.color,
    this.completada = false,
    this.numeroCuenta,
  });

  double get progreso {
    if (montoObjetivo == 0) return 0;
    return (montoActual / montoObjetivo * 100).clamp(0, 100);
  }

  bool get estaProxima => progreso >= 80 && !completada;

  int get diasRestantes {
    try {
      final fecha = DateTime.parse(fechaObjetivo);
      final diferencia = fecha.difference(DateTime.now()).inDays;
      return diferencia > 0 ? diferencia : 0;
    } catch (e) {
      return 0;
    }
  }

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      montoObjetivo:
          double.tryParse(json['montoObjetivo']?.toString() ?? '0') ?? 0,
      montoActual: double.tryParse(json['montoActual']?.toString() ?? '0') ?? 0,
      fechaInicio: json['fechaInicio']?.toString() ?? '',
      fechaObjetivo: json['fechaObjetivo']?.toString() ?? '',
      icono: json['icono']?.toString() ?? 'savings',
      color: json['color']?.toString() ?? 'FF4CAF50',
      completada: json['completada'] == true || json['completada'] == 'true',
      numeroCuenta: json['numeroCuenta']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'montoObjetivo': montoObjetivo,
      'montoActual': montoActual,
      'fechaInicio': fechaInicio,
      'fechaObjetivo': fechaObjetivo,
      'icono': icono,
      'color': color,
      'completada': completada,
      'numeroCuenta': numeroCuenta,
    };
  }

  Meta copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? montoObjetivo,
    double? montoActual,
    String? fechaInicio,
    String? fechaObjetivo,
    String? icono,
    String? color,
    bool? completada,
    String? numeroCuenta,
  }) {
    return Meta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      montoObjetivo: montoObjetivo ?? this.montoObjetivo,
      montoActual: montoActual ?? this.montoActual,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      completada: completada ?? this.completada,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
    );
  }
}
