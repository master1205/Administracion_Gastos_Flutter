// ============================================================================
// CONSTANTES Y CONFIGURACIÓN GLOBAL
// ============================================================================

const CONFIG = {
  SPREADSHEET_URL: "https://docs.google.com/spreadsheets/d/1cv6XQUkFGrVxkiZ2OXzRAi7AA-JGpLLB-B7piHckgFo/edit#gid=499221240",
  FOLDER_REPORTES_ID: "1K9jwtis-5UMffUmPRlGnQHWlC6yvHDzA",
  PLANTILLA_REPORTE_ID: "1jJpS8FX64u1OCOPpLisRuN5Fh4bcLFzoBwG7CjSMCIA",
  EMAILS_NOTIFICACION: ["mario.francisco.melo@outlook.com", "maytem2908@gmail.com"]
};

// Códigos de respuesta estandarizados
const RESPONSE_CODE = {
  OK: 0,
  NOK: 1
};

// Mensajes de respuesta
const MESSAGES = {
  SUCCESS: "Operación exitosa",
  ERROR_GENERAL: "Error en la operación",
  SALDO_INSUFICIENTE: "Saldo insuficiente",
  SALDO_INSUFICIENTE_ORIGEN: "Saldo insuficiente en cuenta origen",
  TRANSACCION_NO_ENCONTRADA: "Transacción no encontrada",
  CUENTA_NO_ENCONTRADA: "Cuenta no encontrada",
  DATOS_INVALIDOS: "Datos inválidos",
  TRANSACCION_REGISTRADA: "Transacción registrada exitosamente",
  TRANSACCION_ACTUALIZADA: "Transacción actualizada exitosamente",
  TRANSACCION_ELIMINADA: "Transacción eliminada correctamente",
  ACCION_INVALIDA: "Acción no válida"
};

// Índices de columnas para hojas
const COLUMNAS_TRANSACCIONES = {
  ID: 0,
  TIPO: 1,
  MONTO: 2,
  DESCRIPCION: 3,
  FECHA: 4,
  CATEGORIA: 5,
  CUENTA: 6,
  CUENTA_ORIGEN: 7,
  CUENTA_DESTINO: 8
};

const COLUMNAS_CUENTAS = {
  ID: 0,
  NOMBRE: 1,
  SALDO: 2,
  IMAGEN: 3,
  BENEFICIARIO: 4,
  NUMERO_TARJETA: 5
};

const TIPOS_TRANSACCION = {
  GASTOS: 'Gastos',
  PAGOS: 'Pagos',
  INGRESOS: 'Ingresos',
  REEMBOLSOS: 'Reembolsos',
  TRASPASOS: 'Traspasos'
};

// Estilos para tablas
const ESTILOS_TABLA = {
  ENCABEZADO: {
    FONT_SIZE: 11,
    FONT_COLOR: "#ffffff",
    BG_COLOR_CATEGORIAS: "#667eea",
    BG_COLOR_TRANSACCIONES: "#2D3436"
  },
  FILAS: {
    FONT_SIZE: 9,
    BG_COLOR_PAR: "#F8F9FA",
    BG_COLOR_IMPAR: "#FFFFFF"
  },
  PADDING: {
    TOP: 8,
    BOTTOM: 8,
    LEFT: 10,
    RIGHT: 10
  },
  BORDES: {
    COLOR: "#E0E0E0",
    WIDTH: 1
  }
};

// Colores para elementos visuales
const COLORES = {
  MEDALLAS: ['#FF6B6B', '#FFA500', '#FFD700'],
  PRIMARIO: '#667eea',
  SECUNDARIO: '#764ba2',
  EXITO: '#2ecc71',
  ERROR: '#e74c3c',
  ADVERTENCIA: '#f39c12'
};