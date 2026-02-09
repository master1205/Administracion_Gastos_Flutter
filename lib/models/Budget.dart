import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String nombre;
  final double montoLimite;
  final double montoGastado; // Calculado en tiempo real
  final String periodo; // 'semanal' | 'mensual'
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final List<String> categorias; // [] = todas las categorías
  final bool esRecurrente;
  final bool alertaActiva;
  final double porcentajeAlerta; // 50-95, default 80
  final int? colorAsignado; // Color personalizado
  final String usuarioId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? presupuestoOriginalId; // Para presupuestos históricos

  Budget({
    required this.id,
    required this.nombre,
    required this.montoLimite,
    this.montoGastado = 0.0,
    required this.periodo,
    required this.fechaInicio,
    required this.fechaFin,
    this.categorias = const [],
    this.esRecurrente = true,
    this.alertaActiva = true,
    this.porcentajeAlerta = 80.0,
    this.colorAsignado,
    required this.usuarioId,
    this.createdAt,
    this.updatedAt,
    this.presupuestoOriginalId,
  });

  /// Porcentaje de progreso (0-100+)
  double get progreso {
    if (montoLimite == 0) return 0;
    return (montoGastado / montoLimite * 100);
  }

  /// Monto restante disponible
  double get montoRestante {
    final restante = montoLimite - montoGastado;
    return restante > 0 ? restante : 0;
  }

  /// Indica si está en zona de alerta
  bool get enAlerta => progreso >= porcentajeAlerta && progreso < 100;

  /// Indica si se excedió el límite
  bool get excedido => montoGastado > montoLimite;

  /// Indica si está en rango seguro
  bool get seguro => progreso < porcentajeAlerta;

  /// Estado del presupuesto como string
  String get estado {
    if (excedido) return 'excedido';
    if (enAlerta) return 'alerta';
    return 'seguro';
  }

  /// Color según el estado (para UI)
  int get colorEstado {
    // Los colores de advertencia tienen prioridad sobre el color asignado
    if (excedido) return 0xFFD32F2F; // Rojo oscuro
    if (progreso >= 90) return 0xFFE53935; // Rojo
    if (progreso >= porcentajeAlerta) return 0xFFFFA726; // Amarillo

    if (colorAsignado != null) return colorAsignado!;
    return 0xFF66BB6A; // Verde
  }

  /// Verifica si el presupuesto está activo (dentro del período)
  bool get estaActivo {
    final ahora = DateTime.now();
    return ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin);
  }

  /// Días restantes del período
  int get diasRestantes {
    final diferencia = fechaFin.difference(DateTime.now()).inDays;
    return diferencia > 0 ? diferencia : 0;
  }

  /// Verifica si aplica a todas las categorías
  bool get aplicaTodasCategorias => categorias.isEmpty;

  /// Constructor desde Firestore
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Budget(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      montoLimite: (data['montoLimite'] as num?)?.toDouble() ?? 0.0,
      montoGastado: (data['montoGastado'] as num?)?.toDouble() ?? 0.0,
      periodo: data['periodo'] ?? 'mensual',
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (data['fechaFin'] as Timestamp).toDate(),
      categorias: List<String>.from(data['categorias'] ?? []),
      esRecurrente: data['esRecurrente'] ?? true,
      alertaActiva: data['alertaActiva'] ?? true,
      porcentajeAlerta: (data['porcentajeAlerta'] as num?)?.toDouble() ?? 80.0,
      colorAsignado: data['colorAsignado'] as int?,
      usuarioId: data['usuarioId'] ?? 'default_user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      presupuestoOriginalId: data['presupuestoOriginalId'] as String?,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toFirestore({bool isNew = false}) {
    final data = {
      'nombre': nombre,
      'montoLimite': montoLimite,
      'montoGastado': montoGastado,
      'periodo': periodo,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'categorias': categorias,
      'esRecurrente': esRecurrente,
      'alertaActiva': alertaActiva,
      'porcentajeAlerta': porcentajeAlerta,
      'colorAsignado': colorAsignado,
      'usuarioId': usuarioId,
      'presupuestoOriginalId': presupuestoOriginalId,
    };

    if (isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
    } else {
      data['updatedAt'] = FieldValue.serverTimestamp();
    }

    return data;
  }

  /// Crear copia con cambios
  Budget copyWith({
    String? id,
    String? nombre,
    double? montoLimite,
    double? montoGastado,
    String? periodo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    List<String>? categorias,
    bool? esRecurrente,
    bool? alertaActiva,
    double? porcentajeAlerta,
    int? colorAsignado,
    String? usuarioId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? presupuestoOriginalId,
  }) {
    return Budget(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      montoLimite: montoLimite ?? this.montoLimite,
      montoGastado: montoGastado ?? this.montoGastado,
      periodo: periodo ?? this.periodo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      categorias: categorias ?? this.categorias,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      alertaActiva: alertaActiva ?? this.alertaActiva,
      porcentajeAlerta: porcentajeAlerta ?? this.porcentajeAlerta,
      colorAsignado: colorAsignado ?? this.colorAsignado,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      presupuestoOriginalId:
          presupuestoOriginalId ?? this.presupuestoOriginalId,
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, nombre: $nombre, $montoGastado/$montoLimite, periodo: $periodo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
