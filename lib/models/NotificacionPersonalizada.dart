class NotificacionPersonalizada {
  final String id;
  final String titulo;
  final String mensaje;
  final String hora; // Formato HH:mm
  final List<int> diasSemana; // 1=Lunes, 7=Domingo
  final bool activa;
  final String icono;
  final String color;

  NotificacionPersonalizada({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.hora,
    required this.diasSemana,
    required this.activa,
    this.icono = 'notifications',
    this.color = 'FF4CAF50',
  });

  // Obtener hora en formato de 24 horas
  int get horaInt => int.parse(hora.split(':')[0]);
  int get minutoInt => int.parse(hora.split(':')[1]);

  // Verificar si se ejecuta hoy
  bool get seEjecutaHoy {
    final hoy = DateTime.now().weekday;
    return diasSemana.contains(hoy);
  }

  // Obtener texto descriptivo de días
  String get diasTexto {
    if (diasSemana.length == 7) return 'Todos los días';
    if (diasSemana.length == 5 &&
        diasSemana.contains(1) &&
        diasSemana.contains(2) &&
        diasSemana.contains(3) &&
        diasSemana.contains(4) &&
        diasSemana.contains(5)) {
      return 'Entre semana';
    }
    if (diasSemana.length == 2 &&
        diasSemana.contains(6) &&
        diasSemana.contains(7)) {
      return 'Fines de semana';
    }

    const nombresDias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return diasSemana.map((d) => nombresDias[d - 1]).join(', ');
  }

  factory NotificacionPersonalizada.fromJson(Map<String, dynamic> json) {
    // Conversión segura de diasSemana
    List<int> parseDiasSemana(dynamic value) {
      if (value == null) return [1, 2, 3, 4, 5, 6, 7];
      if (value is List) {
        return value.map((e) {
          if (e is int) return e;
          if (e is String) return int.tryParse(e) ?? 1;
          return 1;
        }).toList();
      }
      if (value is String) {
        return value
            .split(',')
            .map((e) => int.tryParse(e.trim()) ?? 1)
            .toList();
      }
      return [1, 2, 3, 4, 5, 6, 7];
    }

    // Conversión segura de hora (puede venir como ISO timestamp o HH:mm)
    String parseHora(dynamic value) {
      if (value == null) return '10:00';
      String horaStr = value.toString();

      // Si contiene 'T' es un timestamp ISO, extraer solo HH:mm
      if (horaStr.contains('T')) {
        try {
          DateTime dt = DateTime.parse(horaStr);
          return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          return '10:00';
        }
      }

      // Si ya está en formato HH:mm, retornar tal cual
      if (horaStr.contains(':') && horaStr.length <= 5) {
        return horaStr;
      }

      return '10:00';
    }

    return NotificacionPersonalizada(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      hora: parseHora(json['hora']),
      diasSemana: parseDiasSemana(json['diasSemana']),
      activa: json['activa'] == true || json['activa'] == 'true',
      icono: json['icono']?.toString() ?? 'notifications',
      color: json['color']?.toString() ?? 'FF4CAF50',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'hora': hora,
      'diasSemana': diasSemana,
      'activa': activa,
      'icono': icono,
      'color': color,
    };
  }

  NotificacionPersonalizada copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    String? hora,
    List<int>? diasSemana,
    bool? activa,
    String? icono,
    String? color,
  }) {
    return NotificacionPersonalizada(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      hora: hora ?? this.hora,
      diasSemana: diasSemana ?? this.diasSemana,
      activa: activa ?? this.activa,
      icono: icono ?? this.icono,
      color: color ?? this.color,
    );
  }
}
