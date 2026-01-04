/// Clase para manejar la respuesta estándar de la API
class ApiResponse<T> {
  final int codE; // 0 = OK, 1 = NOK
  final String msgE; // Mensaje de la operación
  final T? data; // Datos opcionales

  ApiResponse({required this.codE, required this.msgE, this.data});

  /// Indica si la operación fue exitosa
  bool get isSuccess => codE == 0;

  /// Indica si la operación falló
  bool get isError => codE == 1;

  /// Factory para crear una instancia desde JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse<T>(
      codE: json['codE'] as int,
      msgE: json['msgE'] as String,
      data:
          json.containsKey('data') && json['data'] != null && dataParser != null
              ? dataParser(json['data'])
              : null,
    );
  }

  /// Convierte la respuesta a JSON
  Map<String, dynamic> toJson() {
    return {'codE': codE, 'msgE': msgE, if (data != null) 'data': data};
  }
}

/// Excepción personalizada para errores de la API
class ApiException implements Exception {
  final String message;
  final int? errorCode;

  ApiException(this.message, {this.errorCode});

  @override
  String toString() => message;
}
