import 'package:cloud_firestore/cloud_firestore.dart';

class Abono {
  final String id;
  final double monto;
  final int numeroAbono;
  final DateTime fechaAbono;
  final String? nota;

  Abono({
    required this.id,
    required this.monto,
    required this.numeroAbono,
    required this.fechaAbono,
    this.nota,
  });

  factory Abono.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Abono(
      id: doc.id,
      monto: (data['monto'] as num?)?.toDouble() ?? 0,
      numeroAbono: (data['numeroAbono'] as int?) ?? 0,
      fechaAbono:
          (data['fechaAbono'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nota: data['nota'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'monto': monto,
      'numeroAbono': numeroAbono,
      'fechaAbono': Timestamp.fromDate(fechaAbono),
      'nota': nota,
    };
  }
}

class Apartado {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono;
  final String color;
  final double montoTotal;
  final double montoApartado;
  final int numeroPagos;
  final int pagosRealizados;
  final DateTime fechaLimite;
  final DateTime? fechaProximoPago;
  final String frecuencia; // 'semanal', 'quincenal', 'mensual'
  final String estado; // 'activo', 'completado', 'pagado', 'vencido'

  // Datos de la transacción final (se recolectan al crear)
  final String categoria;
  final String? cuentaId;
  final String? cuentaNombre;
  final bool esRecurrente;

  final String usuarioId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Apartado({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.icono,
    required this.color,
    required this.montoTotal,
    this.montoApartado = 0,
    required this.numeroPagos,
    this.pagosRealizados = 0,
    required this.fechaLimite,
    this.fechaProximoPago,
    required this.frecuencia,
    this.estado = 'activo',
    required this.categoria,
    this.cuentaId,
    this.cuentaNombre,
    this.esRecurrente = false,
    this.usuarioId = 'default_user',
    this.createdAt,
    this.updatedAt,
  });

  /// Monto por abono (redistribuido si hay atrasos)
  double get montoPorPago {
    final restante = montoTotal - montoApartado;
    final pagosFaltantes = numeroPagos - pagosRealizados;
    if (pagosFaltantes <= 0) return 0;
    return restante / pagosFaltantes;
  }

  /// Progreso (0-100)
  double get progreso {
    if (montoTotal == 0) return 0;
    return (montoApartado / montoTotal * 100).clamp(0, 100);
  }

  /// Monto restante
  double get montoRestante {
    final r = montoTotal - montoApartado;
    return r > 0 ? r : 0;
  }

  /// Si ya se completó el monto
  bool get estaCompleto => montoApartado >= montoTotal;

  /// Si ya venció
  bool get estaVencido =>
      !estaCompleto &&
      estado == 'activo' &&
      DateTime.now().isAfter(fechaLimite);

  /// Días restantes
  int get diasRestantes {
    final diff = fechaLimite.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Pagos restantes
  int get pagosRestantes {
    final r = numeroPagos - pagosRealizados;
    return r > 0 ? r : 0;
  }

  factory Apartado.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Apartado(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      icono: data['icono'] ?? 'savings',
      color: data['color'] ?? 'FF4CAF50',
      montoTotal: (data['montoTotal'] as num?)?.toDouble() ?? 0,
      montoApartado: (data['montoApartado'] as num?)?.toDouble() ?? 0,
      numeroPagos: (data['numeroPagos'] as int?) ?? 1,
      pagosRealizados: (data['pagosRealizados'] as int?) ?? 0,
      fechaLimite:
          (data['fechaLimite'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaProximoPago: (data['fechaProximoPago'] as Timestamp?)?.toDate(),
      frecuencia: data['frecuencia'] ?? 'semanal',
      estado: data['estado'] ?? 'activo',
      categoria: data['categoria'] ?? '',
      cuentaId: data['cuentaId'] as String?,
      cuentaNombre: data['cuentaNombre'] as String?,
      esRecurrente: data['esRecurrente'] ?? false,
      usuarioId: data['usuarioId'] ?? 'default_user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = true}) {
    final map = <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'color': color,
      'montoTotal': montoTotal,
      'montoApartado': montoApartado,
      'numeroPagos': numeroPagos,
      'pagosRealizados': pagosRealizados,
      'fechaLimite': Timestamp.fromDate(fechaLimite),
      'fechaProximoPago':
          fechaProximoPago != null
              ? Timestamp.fromDate(fechaProximoPago!)
              : null,
      'frecuencia': frecuencia,
      'estado': estado,
      'categoria': categoria,
      'cuentaId': cuentaId,
      'cuentaNombre': cuentaNombre,
      'esRecurrente': esRecurrente,
      'usuarioId': usuarioId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  Apartado copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? icono,
    String? color,
    double? montoTotal,
    double? montoApartado,
    int? numeroPagos,
    int? pagosRealizados,
    DateTime? fechaLimite,
    DateTime? fechaProximoPago,
    String? frecuencia,
    String? estado,
    String? categoria,
    String? cuentaId,
    String? cuentaNombre,
    bool? esRecurrente,
    String? usuarioId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Apartado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      montoTotal: montoTotal ?? this.montoTotal,
      montoApartado: montoApartado ?? this.montoApartado,
      numeroPagos: numeroPagos ?? this.numeroPagos,
      pagosRealizados: pagosRealizados ?? this.pagosRealizados,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      fechaProximoPago: fechaProximoPago ?? this.fechaProximoPago,
      frecuencia: frecuencia ?? this.frecuencia,
      estado: estado ?? this.estado,
      categoria: categoria ?? this.categoria,
      cuentaId: cuentaId ?? this.cuentaId,
      cuentaNombre: cuentaNombre ?? this.cuentaNombre,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
