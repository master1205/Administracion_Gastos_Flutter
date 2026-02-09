import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  final String id; // Firestore document ID
  final int? idCuenta; // Legacy ID para compatibilidad con Sheets
  final String nombre;
  final double saldo;
  final double saldoRetenido; // Dinero apartado/retenido
  final String?
  tipo; // efectivo, tarjeta_debito, tarjeta_credito, banco, ahorro
  final String? imagen;
  final String? beneficiario;
  final String? numeroTarjeta;
  final bool activa; // Para soft delete
  final String? usuarioId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Saldo real disponible (saldo - retenido)
  double get saldoDisponible => saldo - saldoRetenido;

  Account({
    required this.id,
    this.idCuenta,
    required this.nombre,
    required this.saldo,
    this.saldoRetenido = 0,
    this.tipo,
    this.imagen,
    this.beneficiario,
    this.numeroTarjeta,
    this.activa = true,
    this.usuarioId,
    this.createdAt,
    this.updatedAt,
  });

  // Constructor desde JSON para compatibilidad con Google Sheets API
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id']?.toString() ?? '',
      idCuenta:
          json['idCuenta'] != null
              ? int.tryParse(json['idCuenta'].toString())
              : null,
      nombre: json['nombre'] ?? '',
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      saldoRetenido: (json['saldoRetenido'] as num?)?.toDouble() ?? 0.0,
      tipo: json['tipo'],
      imagen: json['imagen'],
      beneficiario: json['beneficiario'],
      numeroTarjeta: json['numeroTarjeta'],
      activa:
          json['activa'] != null
              ? json['activa'] == true || json['activa'] == 'true'
              : true,
      usuarioId: json['usuarioId'],
    );
  }

  // Constructor desde Firestore DocumentSnapshot
  factory Account.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final Timestamp? createdTimestamp = data['createdAt'] as Timestamp?;
    final Timestamp? updatedTimestamp = data['updatedAt'] as Timestamp?;

    return Account(
      id: doc.id,
      idCuenta: data['idCuenta'] as int?,
      nombre: data['nombre'] ?? '',
      saldo: (data['saldo'] as num?)?.toDouble() ?? 0.0,
      saldoRetenido: (data['saldoRetenido'] as num?)?.toDouble() ?? 0.0,
      tipo: data['tipo'],
      imagen: data['imagen'],
      beneficiario: data['beneficiario'],
      numeroTarjeta: data['numeroTarjeta'],
      activa: data['activa'] ?? true,
      usuarioId: data['usuarioId'],
      createdAt: createdTimestamp?.toDate(),
      updatedAt: updatedTimestamp?.toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore({bool isNew = true}) {
    final map = {
      'nombre': nombre,
      'saldo': saldo,
      'saldoRetenido': saldoRetenido,
      'tipo': tipo ?? 'efectivo',
      'imagen': imagen,
      'beneficiario': beneficiario,
      'numeroTarjeta': numeroTarjeta,
      'activa': activa,
      'usuarioId': usuarioId ?? 'default_user',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
      if (idCuenta != null) {
        map['idCuenta'] = idCuenta;
      }
    }

    return map;
  }

  // Método para crear copia con cambios
  Account copyWith({
    String? id,
    int? idCuenta,
    String? nombre,
    double? saldo,
    double? saldoRetenido,
    String? tipo,
    String? imagen,
    String? beneficiario,
    String? numeroTarjeta,
    bool? activa,
    String? usuarioId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      idCuenta: idCuenta ?? this.idCuenta,
      nombre: nombre ?? this.nombre,
      saldo: saldo ?? this.saldo,
      saldoRetenido: saldoRetenido ?? this.saldoRetenido,
      tipo: tipo ?? this.tipo,
      imagen: imagen ?? this.imagen,
      beneficiario: beneficiario ?? this.beneficiario,
      numeroTarjeta: numeroTarjeta ?? this.numeroTarjeta,
      activa: activa ?? this.activa,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir a JSON para Google Sheets (legacy)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idCuenta': idCuenta,
      'nombre': nombre,
      'saldo': saldo,
      'saldoRetenido': saldoRetenido,
      'tipo': tipo,
      'imagen': imagen,
      'beneficiario': beneficiario,
      'numeroTarjeta': numeroTarjeta,
      'activa': activa,
      'usuarioId': usuarioId,
    };
  }
}
