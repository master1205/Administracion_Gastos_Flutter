import 'package:cloud_firestore/cloud_firestore.dart';

class Meta {
  final String id;
  final String nombre;
  final String descripcion;
  final double montoObjetivo;
  final double montoActual;
  final String fechaInicio; // String para compatibilidad con Sheets
  final String fechaObjetivo;
  final DateTime? fechaInicioTimestamp; // Timestamp real de Firestore
  final DateTime? fechaObjetivoTimestamp;
  final String icono;
  final String color;
  final bool completada;

  // Mejora: usar ID de cuenta en lugar de numeroTarjeta
  final String? cuentaId; // ID de la cuenta asociada
  final String? cuentaNombre; // Nombre denormalizado
  final String? numeroCuenta; // Legacy para compatibilidad con Sheets

  final String? usuarioId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Meta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.montoObjetivo,
    required this.montoActual,
    required this.fechaInicio,
    required this.fechaObjetivo,
    this.fechaInicioTimestamp,
    this.fechaObjetivoTimestamp,
    required this.icono,
    required this.color,
    this.completada = false,
    this.cuentaId,
    this.cuentaNombre,
    this.numeroCuenta,
    this.usuarioId,
    this.createdAt,
    this.updatedAt,
  });

  double get progreso {
    if (montoObjetivo == 0) return 0;
    return (montoActual / montoObjetivo * 100).clamp(0, 100);
  }

  bool get estaProxima => progreso >= 80 && !completada;

  int get diasRestantes {
    try {
      final fecha = fechaObjetivoTimestamp ?? DateTime.parse(fechaObjetivo);
      final diferencia = fecha.difference(DateTime.now()).inDays;
      return diferencia > 0 ? diferencia : 0;
    } catch (e) {
      return 0;
    }
  }

  // Constructor desde JSON (compatibilidad con Sheets)
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
      cuentaId: json['cuentaId']?.toString(),
      cuentaNombre: json['cuentaNombre']?.toString(),
      numeroCuenta: json['numeroCuenta']?.toString(),
      usuarioId: json['usuarioId']?.toString(),
    );
  }

  // Constructor desde Firestore
  factory Meta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extraer timestamps
    final Timestamp? timestampInicio =
        data['fechaInicioTimestamp'] as Timestamp?;
    final Timestamp? timestampObjetivo =
        data['fechaObjetivoTimestamp'] as Timestamp?;

    return Meta(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      montoObjetivo: (data['montoObjetivo'] as num?)?.toDouble() ?? 0.0,
      montoActual: (data['montoActual'] as num?)?.toDouble() ?? 0.0,

      // Fechas: usar string como fallback
      fechaInicio: data['fechaInicio'] ?? '',
      fechaObjetivo: data['fechaObjetivo'] ?? '',
      fechaInicioTimestamp: timestampInicio?.toDate(),
      fechaObjetivoTimestamp: timestampObjetivo?.toDate(),

      icono: data['icono'] ?? 'savings',
      color: data['color'] ?? 'FF4CAF50',
      completada: data['completada'] ?? false,
      cuentaId: data['cuentaId'],
      cuentaNombre: data['cuentaNombre'],
      numeroCuenta: data['numeroCuenta'],
      usuarioId: data['usuarioId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore({bool isNew = true}) {
    // Convertir strings de fecha a timestamps si es posible
    Timestamp? inicioTs;
    Timestamp? objetivoTs;

    try {
      if (fechaInicioTimestamp != null) {
        inicioTs = Timestamp.fromDate(fechaInicioTimestamp!);
      } else if (fechaInicio.isNotEmpty) {
        inicioTs = Timestamp.fromDate(DateTime.parse(fechaInicio));
      }
    } catch (e) {
      // Mantener null si no se puede parsear
    }

    try {
      if (fechaObjetivoTimestamp != null) {
        objetivoTs = Timestamp.fromDate(fechaObjetivoTimestamp!);
      } else if (fechaObjetivo.isNotEmpty) {
        objetivoTs = Timestamp.fromDate(DateTime.parse(fechaObjetivo));
      }
    } catch (e) {
      // Mantener null si no se puede parsear
    }

    final map = {
      'nombre': nombre,
      'descripcion': descripcion,
      'montoObjetivo': montoObjetivo,
      'montoActual': montoActual,
      // Guardar ambos formatos
      'fechaInicio': fechaInicio,
      'fechaObjetivo': fechaObjetivo,
      'fechaInicioTimestamp': inicioTs,
      'fechaObjetivoTimestamp': objetivoTs,
      'icono': icono,
      'color': color,
      'completada': completada,
      'cuentaId': cuentaId,
      'cuentaNombre': cuentaNombre,
      'usuarioId': usuarioId ?? 'default_user',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Preservar numeroCuenta para compatibilidad con Sheets
    if (numeroCuenta != null) {
      map['numeroCuenta'] = numeroCuenta;
    }

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  // Método copyWith
  Meta copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? montoObjetivo,
    double? montoActual,
    String? fechaInicio,
    String? fechaObjetivo,
    DateTime? fechaInicioTimestamp,
    DateTime? fechaObjetivoTimestamp,
    String? icono,
    String? color,
    bool? completada,
    String? cuentaId,
    String? cuentaNombre,
    String? numeroCuenta,
    String? usuarioId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Meta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      montoObjetivo: montoObjetivo ?? this.montoObjetivo,
      montoActual: montoActual ?? this.montoActual,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
      fechaInicioTimestamp: fechaInicioTimestamp ?? this.fechaInicioTimestamp,
      fechaObjetivoTimestamp:
          fechaObjetivoTimestamp ?? this.fechaObjetivoTimestamp,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      completada: completada ?? this.completada,
      cuentaId: cuentaId ?? this.cuentaId,
      cuentaNombre: cuentaNombre ?? this.cuentaNombre,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir a JSON para Sheets (legacy)
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
      'cuentaId': cuentaId,
      'cuentaNombre': cuentaNombre,
      'usuarioId': usuarioId,
    };
  }
}
