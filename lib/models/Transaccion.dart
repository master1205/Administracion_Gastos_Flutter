import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String idTransaccion;
  final String categoria;
  final String descripcion;
  final double monto;
  final String fecha; // Formato YYYY-MM-DD para compatibilidad
  final DateTime? fechaTimestamp; // Timestamp real de Firestore
  final String mes; // YYYY-MM para queries eficientes
  final String tipoTransaccion; // gasto, ingreso, traspaso

  // Denormalización estratégica: guardamos IDs Y nombres
  final String? cuentaId; // Para gastos/ingresos
  final String? cuentaNombre; // Nombre denormalizado
  final String? cuentaOrigenId; // Para traspasos
  final String? cuentaOrigenNombre;
  final String? cuentaDestinoId; // Para traspasos
  final String? cuentaDestinoNombre;

  // Para compatibilidad con Sheets legacy
  final String cuenta;
  final String cuentaOrigen;
  final String cuentaDestino;

  // Campos de sync
  final bool sincronizado;
  final DateTime? sincronizadoAt;
  final String? usuarioId;
  final DateTime? createdAt;

  Transaction({
    required this.idTransaccion,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    this.fechaTimestamp,
    String? mes,
    required this.tipoTransaccion,
    this.cuentaId,
    this.cuentaNombre,
    this.cuentaOrigenId,
    this.cuentaOrigenNombre,
    this.cuentaDestinoId,
    this.cuentaDestinoNombre,
    this.cuenta = '',
    this.cuentaOrigen = '',
    this.cuentaDestino = '',
    this.sincronizado = false,
    this.sincronizadoAt,
    this.usuarioId,
    this.createdAt,
  }) : mes = mes ?? _extractMes(fecha);

  // Helper para extraer mes de fecha
  static String _extractMes(String fecha) {
    try {
      final parts = fecha.split('-');
      if (parts.length >= 2) {
        return '${parts[0]}-${parts[1]}'; // YYYY-MM
      }
      return DateTime.now().toString().substring(0, 7);
    } catch (e) {
      return DateTime.now().toString().substring(0, 7);
    }
  }

  // Factory constructor desde JSON (Sheets legacy)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      idTransaccion: json['idTransaccion'] ?? '',
      categoria: json['categoria'] ?? '',
      descripcion: json['descripcion'] ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      fecha: json['fecha'] ?? '',
      tipoTransaccion: json['tipoTransaccion'] ?? '',
      cuenta: json['cuenta'] ?? '',
      cuentaOrigen: json['cuentaOrigen'] ?? '',
      cuentaDestino: json['cuentaDestino'] ?? '',
    );
  }

  // Factory constructor desde Firestore
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // La fecha puede venir como Timestamp o como String
    final fechaData = data['fecha'];
    final Timestamp? fechaTs =
        fechaData is Timestamp
            ? fechaData
            : data['fechaTimestamp'] as Timestamp?;
    final String fechaStr =
        fechaData is String
            ? fechaData
            : (fechaTs?.toDate().toString().substring(0, 10) ?? '');

    final Timestamp? sincronizadoTimestamp =
        data['sincronizadoAt'] as Timestamp?;
    final Timestamp? createdTimestamp = data['createdAt'] as Timestamp?;

    return Transaction(
      idTransaccion: doc.id,
      categoria: data['categoria'] ?? '',
      descripcion: data['descripcion'] ?? '',
      monto: (data['monto'] as num?)?.toDouble() ?? 0.0,
      fecha: fechaStr,
      fechaTimestamp: fechaTs?.toDate(),
      mes: data['mes'] ?? '',
      tipoTransaccion:
          data['tipo'] ??
          data['tipoTransaccion'] ??
          '', // Soporte para ambos nombres
      cuentaId: data['cuentaId'],
      cuentaNombre: data['cuentaNombre'] ?? data['cuenta'],
      cuentaOrigenId: data['cuentaOrigenId'],
      cuentaOrigenNombre: data['cuentaOrigenNombre'] ?? data['cuentaOrigen'],
      cuentaDestinoId: data['cuentaDestinoId'],
      cuentaDestinoNombre: data['cuentaDestinoNombre'] ?? data['cuentaDestino'],
      cuenta: data['cuentaNombre'] ?? data['cuenta'] ?? '',
      cuentaOrigen: data['cuentaOrigenNombre'] ?? data['cuentaOrigen'] ?? '',
      cuentaDestino: data['cuentaDestinoNombre'] ?? data['cuentaDestino'] ?? '',
      sincronizado: data['sincronizado'] ?? false,
      sincronizadoAt: sincronizadoTimestamp?.toDate(),
      usuarioId: data['usuarioId'],
      createdAt: createdTimestamp?.toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore({bool isNew = true}) {
    Timestamp? fechaTs;
    try {
      if (fechaTimestamp != null) {
        fechaTs = Timestamp.fromDate(fechaTimestamp!);
      } else {
        fechaTs = Timestamp.fromDate(DateTime.parse(fecha));
      }
    } catch (e) {
      fechaTs = Timestamp.now();
    }

    final map = {
      'categoria': categoria,
      'descripcion': descripcion,
      'monto': monto,
      'fecha': fecha,
      'fechaTimestamp': fechaTs,
      'mes': mes,
      'tipoTransaccion': tipoTransaccion,
      'cuentaId': cuentaId,
      'cuentaNombre': cuentaNombre,
      'cuentaOrigenId': cuentaOrigenId,
      'cuentaOrigenNombre': cuentaOrigenNombre,
      'cuentaDestinoId': cuentaDestinoId,
      'cuentaDestinoNombre': cuentaDestinoNombre,
      // Legacy fields
      'cuenta': cuenta,
      'cuentaOrigen': cuentaOrigen,
      'cuentaDestino': cuentaDestino,
      'sincronizado': sincronizado,
      'usuarioId': usuarioId ?? 'default_user',
    };

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  // Helper para obtener el nombre de la cuenta a mostrar
  String getCuentaDisplay() {
    if (tipoTransaccion == 'traspaso') {
      return '${cuentaOrigenNombre ?? cuentaOrigen} → ${cuentaDestinoNombre ?? cuentaDestino}';
    }
    return cuentaNombre ?? cuenta;
  }

  // Helpers de tipo
  bool get esGasto => tipoTransaccion == 'gasto' || tipoTransaccion == 'Gastos';
  bool get esIngreso =>
      tipoTransaccion == 'ingreso' || tipoTransaccion == 'Ingresos';
  bool get esTraspaso =>
      tipoTransaccion == 'traspaso' || tipoTransaccion == 'Traspasos';
}
