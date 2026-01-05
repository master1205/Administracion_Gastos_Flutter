// ============================================================================
// UTILIDADES Y FUNCIONES AUXILIARES
// ============================================================================

/**
 * Logger estructurado
 */
const Logger = {
  info: function (operacion, mensaje, datos) {
    console.log('[INFO] ' + operacion + ': ' + mensaje, datos || '');
  },

  error: function (operacion, error) {
    console.error('[ERROR] ' + operacion + ': ' + error.message, error.stack || '');
  },

  transaccion: function (tipo, id, datos) {
    console.log('[TRANSACCION] ' + tipo + ' - ID: ' + id, JSON.stringify(datos || {}));
  },

  warning: function (operacion, mensaje) {
    console.warn('[WARNING] ' + operacion + ': ' + mensaje);
  }
};

/**
 * Constructor de respuestas JSON
 */
const ResponseBuilder = {
  success: function (data) {
    const response = {
      codE: RESPONSE_CODE.OK,
      msgE: MESSAGES.SUCCESS,
      data: data
    };

    Logger.info('ResponseBuilder', 'Success response', response);

    return ContentService.createTextOutput(JSON.stringify(response))
      .setMimeType(ContentService.MimeType.JSON);
  },

  error: function (mensaje) {
    const response = {
      codE: RESPONSE_CODE.NOK,
      msgE: mensaje
    };

    Logger.warning('ResponseBuilder', 'Error response: ' + mensaje);

    return ContentService.createTextOutput(JSON.stringify(response))
      .setMimeType(ContentService.MimeType.JSON);
  },

  custom: function (codE, msgE, data) {
    const response = {
      codE: codE,
      msgE: msgE
    };

    if (data !== undefined) {
      response.data = data;
    }

    return ContentService.createTextOutput(JSON.stringify(response))
      .setMimeType(ContentService.MimeType.JSON);
  }
};

/**
 * Utilidades de formato
 */
const FormatoUtil = {
  currency: function (valor) {
    const valorNumerico = parseFloat(valor) || 0;
    return '$ ' + valorNumerico.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  },

  fechaActual: function () {
    return Utilities.formatDate(new Date(), "America/Mexico_City", "yyyy-MM-dd");
  },

  mesAnterior: function () {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    const fecha = new Date();
    fecha.setMonth(fecha.getMonth() - 1);

    return meses[fecha.getMonth()] + ' ' + fecha.getFullYear();
  },

  diaEnLetra: function (fechaString) {
    try {
      const partesFecha = fechaString.toString().split('-');
      if (partesFecha.length !== 3) return fechaString;

      const fecha = new Date(partesFecha[0], partesFecha[1] - 1, partesFecha[2]);
      const diasEnEspanol = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

      return diasEnEspanol[fecha.getDay()] + ", " + partesFecha[2];
    } catch (error) {
      Logger.error('FormatoUtil.diaEnLetra', error);
      return fechaString;
    }
  },

  generarId: function () {
    const caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let id = '';

    for (let i = 0; i < 8; i++) {
      id += caracteres.charAt(Math.floor(Math.random() * caracteres.length));
    }

    return id;
  },

  barraVisual: function (porcentaje, total) {
    total = total || 20;
    const filled = Math.round((porcentaje / 100) * total);
    const empty = total - filled;

    let barra = '';
    for (let i = 0; i < filled; i++) {
      barra += '█';
    }
    for (let i = 0; i < empty; i++) {
      barra += '░';
    }

    return barra;
  }
};

/**
 * Gestor de hojas con lazy loading
 */
const SheetManager = (function () {
  let _hoja = null;
  let _transacciones = null;
  let _nuevasTransacciones = null;
  let _categorias = null;
  let _cuentas = null;
  let _nuevasCuentas = null;
  let _metas = null;

  return {
    getHoja: function () {
      if (!_hoja) {
        _hoja = SpreadsheetApp.openByUrl(CONFIG.SPREADSHEET_URL);
      }
      return _hoja;
    },

    getTransacciones: function () {
      if (!_transacciones) {
        _transacciones = this.getHoja().getSheetByName("Transacciones");
      }
      return _transacciones;
    },

    getNuevasTransacciones: function () {
      if (!_nuevasTransacciones) {
        _nuevasTransacciones = this.getHoja().getSheetByName("Nuevas Transacciones");
      }
      return _nuevasTransacciones;
    },

    getCategorias: function () {
      if (!_categorias) {
        _categorias = this.getHoja().getSheetByName("Categorias");
      }
      return _categorias;
    },

    getCuentas: function () {
      if (!_cuentas) {
        _cuentas = this.getHoja().getSheetByName("Cuentas");
      }
      return _cuentas;
    },

    getNuevasCuentas: function () {
      if (!_nuevasCuentas) {
        _nuevasCuentas = this.getHoja().getSheetByName("Nuevas Cuentas");
      }
      return _nuevasCuentas;
    },

    reset: function () {
      _hoja = null;
      _transacciones = null;
      _nuevasTransacciones = null;
      _categorias = null;
      _cuentas = null;
      _nuevasCuentas = null;
    },

    getNotificaciones: function () {
      let sheet = this.getHoja().getSheetByName('Notificaciones');

      if (!sheet) {
        sheet = this.getHoja().insertSheet('Notificaciones');
        sheet.appendRow([
          'id', 'titulo', 'mensaje', 'hora', 'diasSemana',
          'icono', 'color', 'activa', 'fechaCreacion', 'dispositivo'
        ]);

        // Formatear encabezados
        const headerRange = sheet.getRange(1, 1, 1, 10);
        headerRange.setBackground('#4285F4');
        headerRange.setFontColor('#FFFFFF');
        headerRange.setFontWeight('bold');
        sheet.setFrozenRows(1);
      }

      return sheet;
    },

    getMetas: function () {
      if (!_metas) {
        _metas = this.getHoja().getSheetByName("Metas");
      }
      return _metas;
    }

  };
})();