# Implementación de Nueva Estructura JSON para Respuestas API

## 📋 Resumen de Cambios

Se ha implementado una nueva estructura estandarizada para todas las respuestas del API de Google Apps Script, mejorando el manejo de errores y la consistencia en toda la aplicación.

## 🆕 Nueva Estructura de Respuesta

Todas las respuestas del API ahora siguen este formato:

```json
{
  "codE": 0,              // 0 = Operación exitosa (OK), 1 = Error (NOK)
  "msgE": "Mensaje",      // Mensaje descriptivo de la operación
  "data": { ... }         // Datos opcionales (solo cuando hay información que devolver)
}
```

## 📁 Archivos Creados

### 1. `lib/models/api_response.dart`
**Nueva clase para manejar respuestas estandarizadas:**

```dart
class ApiResponse<T> {
  final int codE;        // Código de respuesta
  final String msgE;     // Mensaje
  final T? data;         // Datos opcionales

  bool get isSuccess => codE == 0;
  bool get isError => codE == 1;
  
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  );
}

class ApiException implements Exception {
  final String message;
  final int? errorCode;
  
  ApiException(this.message, {this.errorCode});
}
```

## 🔄 Archivos Modificados

### 1. `lib/api_service.dart` (Refactorización Completa)

#### Nuevos Métodos Auxiliares:

```dart
T _handleApiResponse<T>(
  String responseBody,
  T Function(dynamic) dataParser,
)

ApiResponse<void> _handleApiResponseMessage(String responseBody)
```

#### Métodos GET Actualizados:
Todos los métodos GET ahora:
1. ✅ Verifican `codE` para determinar éxito/error
2. ✅ Extraen datos del campo `data`
3. ✅ Lanzan `ApiException` con el mensaje de error (`msgE`)
4. ✅ Manejan errores de servidor (statusCode != 200)

**Métodos actualizados:**
- `fetchSaldos()` → Retorna `Map<String, dynamic>`
- `fetchGastosPorCategoria()` → Retorna `Map<String, double>`
- `fetchTransaccionesCategorizadas()` → Retorna `Map<String, double>`
- `fetchReportes()` → Retorna `List<Reporte>`
- `fetchTransactions()` → Retorna `List<Transaction>`
- `fetchCategories()` → Retorna `List<Categoria>`
- `fetchAccounts()` → Retorna `List<Account>`
- `fetchCuentas()` → Retorna `List<Account>`

#### Métodos POST Actualizados:
Los métodos POST ahora:
1. ✅ Retornan `ApiResponse<void>` con el mensaje de la operación
2. ✅ Manejan redirecciones 302 correctamente
3. ✅ Lanzan `ApiException` en caso de error

**Métodos actualizados:**
- `registerTransaction()` → Retorna `Future<ApiResponse<void>>`
- `eliminarFilaPorIdTransaccion()` → Retorna `Future<ApiResponse<void>>`

### 2. `lib/dynamic_form_screen.dart`

**Cambio en `_registerTransaction()`:**

```dart
// ❌ ANTES:
String mensaje = await ApiService().registerTransaction(transactionData);

// ✅ AHORA:
String mensaje = await ApiService()
    .registerTransaction(transactionData)
    .then((response) => response.msgE);
```

### 3. `lib/transacciones_screen.dart`

**Cambio en `_deleteTransaction()`:**

```dart
// ❌ ANTES:
await _apiService.eliminarFilaPorIdTransaccion(id);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Transacción eliminada exitosamente')),
);

// ✅ AHORA:
final response = await _apiService.eliminarFilaPorIdTransaccion(id);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(response.msgE)),  // Usa el mensaje del servidor
);
```

## 🎯 Beneficios de los Cambios

### 1. **Manejo Consistente de Errores**
- Todos los errores ahora se manejan de forma uniforme
- Mensajes de error descriptivos desde el servidor
- Códigos de error estandarizados

### 2. **Mejor Experiencia de Usuario**
- Mensajes claros y descriptivos
- Feedback inmediato de operaciones
- Manejo apropiado de errores de red

### 3. **Código Más Mantenible**
- Eliminación de duplicación de código
- Métodos auxiliares reutilizables
- Tipado fuerte con genéricos

### 4. **Validación en Backend**
El backend ahora valida:
- ✅ Saldo insuficiente en traspasos
- ✅ Datos inválidos o faltantes
- ✅ Errores de formato
- ✅ Errores de servidor

## 🧪 Cómo Probar

### Probar Operación Exitosa:
1. Registrar una transacción válida
2. Verificar que se muestre el mensaje de éxito
3. Verificar que los datos se actualicen correctamente

### Probar Manejo de Errores:
1. Intentar un traspaso con saldo insuficiente
2. Verificar que se muestre el mensaje de error apropiado
3. Intentar eliminar una transacción inexistente
4. Verificar que se maneje el error correctamente

## 📝 Ejemplos de Respuestas

### Éxito con Datos:
```json
{
  "codE": 0,
  "msgE": "Transacciones obtenidas exitosamente",
  "data": [
    {
      "idTransaccion": "T001",
      "monto": 1500,
      "descripcion": "Compra de supermercado",
      ...
    }
  ]
}
```

### Éxito sin Datos:
```json
{
  "codE": 0,
  "msgE": "Transacción registrada exitosamente"
}
```

### Error:
```json
{
  "codE": 1,
  "msgE": "Saldo insuficiente en la cuenta de origen"
}
```

## 🔧 Migración para Futuros Endpoints

Si necesitas agregar un nuevo endpoint, sigue este patrón:

```dart
Future<TipoRetorno> nombreMetodo() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl=accion'));

    if (response.statusCode == 200) {
      return _handleApiResponse<TipoRetorno>(
        response.body,
        (data) => /* Parsear data aquí */,
      );
    } else {
      throw ApiException('Error de servidor: ${response.statusCode}');
    }
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException('Error al realizar operación: $e');
  }
}
```

## 📦 Archivo de Respaldo

Se creó un respaldo del archivo original: `api_service.dart.backup`

Si necesitas revertir los cambios, puedes recuperar el archivo original desde este respaldo.

## ✅ Checklist de Implementación

- [x] Crear clase `ApiResponse<T>`
- [x] Crear clase `ApiException`
- [x] Actualizar métodos auxiliares en `ApiService`
- [x] Actualizar todos los métodos GET
- [x] Actualizar todos los métodos POST
- [x] Actualizar `dynamic_form_screen.dart`
- [x] Actualizar `transacciones_screen.dart`
- [x] Formatear código con `dart format`
- [x] Verificar que no hay errores de compilación

## 🚀 Próximos Pasos

1. Probar todas las funcionalidades de la app
2. Verificar que los mensajes de error sean claros
3. Agregar más validaciones en el backend si es necesario
4. Considerar agregar logging para debugging

---

**Fecha de Implementación:** ${DateTime.now().toString().split(' ')[0]}  
**Desarrollador:** GitHub Copilot  
**Versión:** 1.0.0
