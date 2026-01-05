// ============================================================================
// FUNCIONES DE GESTIÓN DE CUENTAS
// ============================================================================

/**
 * Obtiene todas las nuevas cuentas
 */
function getNuevasCuentas() {
  try {
    const sheet = SheetManager.getNuevasCuentas();
    const data = sheet.getDataRange().getValues();
    const cuentasArray = [];

    for (let i = 1; i < data.length; i++) {
      cuentasArray.push({
        idCuenta: data[i][COLUMNAS_CUENTAS.ID],
        nombre: data[i][COLUMNAS_CUENTAS.NOMBRE],
        saldo: parseFloat(data[i][COLUMNAS_CUENTAS.SALDO]) || 0,
        imagen: data[i][COLUMNAS_CUENTAS.IMAGEN] || '',
        beneficiario: data[i][COLUMNAS_CUENTAS.BENEFICIARIO] || '',
        numeroTarjeta: data[i][COLUMNAS_CUENTAS.NUMERO_TARJETA] || ''
      });
    }

    return ResponseBuilder.success(cuentasArray);
    
  } catch (error) {
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Obtiene cuentas con formato original
 */
function getCuentas() {
  try {
    const sheet = SheetManager.getCuentas();
    const data = sheet.getDataRange().getValues();
    const encabezados = data[4];
    const cuentasArray = [];

    for (let i = 5; i < data.length; i++) {
      const cuenta = {};
      for (let j = 0; j < encabezados.length; j++) {
        cuenta[encabezados[j]] = data[i][j];
      }
      cuentasArray.push(cuenta);
    }
    return ResponseBuilder.success(cuentasArray);
    
  } catch (error) {
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Obtiene los saldos consolidados
 */
function getSaldos() {
  try {
    const sheet = SheetManager.getCuentas();
    const datos = sheet.getRange(2, 1, 1, sheet.getLastColumn()).getValues()[0];
    
    const resultado = {
      ingresos: parseFloat(datos[0]) || 0,
      gastos: parseFloat(datos[1]) || 0,
      saldoCuentas: parseFloat(datos[2]) || 0
    };

    return ResponseBuilder.success(resultado);
    
  } catch (error) {
    Logger.error('getSaldos', error);
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Actualizar saldo de una cuenta
 * @param {Object} params - Parámetros { idCuenta, nuevoSaldo }
 * @returns {Object} Respuesta estandarizada
 */
function updateAccountBalance(params) {
  try {
    
    // Validar parámetros
    if (!params.parameter.idCuenta) {
      return ResponseBuilder.error('El ID de cuenta es requerido');
    }
    
    if (params.parameter.nuevoSaldo === undefined || params.parameter.nuevoSaldo === null) {
      return ResponseBuilder.error('El nuevo saldo es requerido');
    }
    
    const idCuenta = parseInt(params.parameter.idCuenta);
    const nuevoSaldo = parseFloat(params.parameter.nuevoSaldo);
    
    if (isNaN(idCuenta)) {
      return ResponseBuilder.error('ID de cuenta inválido');
    }
    
    if (isNaN(nuevoSaldo)) {
      return ResponseBuilder.error('Saldo inválido');
    }
    
    if (nuevoSaldo < 0) {
      return ResponseBuilder.error('El saldo no puede ser negativo');
    }
    
    // Obtener hoja de cuentas
    const sheet = SheetManager.getNuevasCuentas();
    const data = sheet.getDataRange().getValues();
    
    // Buscar la cuenta por ID (columna 0 = idCuenta)
    let filaEncontrada = -1;
    let nombreCuenta = '';
    
    for (let i = 1; i < data.length; i++) {
      if (data[i][0] === idCuenta) {
        filaEncontrada = i + 1; // +1 porque las filas en Sheets empiezan en 1
        nombreCuenta = data[i][1]; // Columna 1 = nombre
        break;
      }
    }
    
    if (filaEncontrada === -1) {
      Logger.warning('updateAccountBalance', 'Cuenta no encontrada', { idCuenta });
      return ResponseBuilder.error('Cuenta no encontrada');
    }
    
    // Actualizar saldo (columna 3 = saldo, índice 2 en array)
    const COLUMNA_SALDO = 3;
    sheet.getRange(filaEncontrada, COLUMNA_SALDO).setValue(nuevoSaldo);
    
    return ResponseBuilder.success({
      message: `Saldo de "${nombreCuenta}" actualizado a $${nuevoSaldo.toFixed(2)}`
    });
    
  } catch (error) {
    Logger.error('updateAccountBalance', error);
    return ResponseBuilder.error(
      'Error al actualizar el saldo: ' + error.message
    );
  }
}

function crearCuenta(params) {
  try {
    const sheet = SheetManager.getNuevasCuentas();
    
    if (!sheet) {
      return ResponseBuilder.error('Hoja Cuentas no encontrada');
    }

    const nombre = params.parameter.nombre;
    const saldoInicial = parseFloat(params.parameter.saldoInicial) || 0;
    let numeroTarjeta = params.parameter.numeroTarjeta || '';

    // Validar campos requeridos
    if (!nombre) {
      return ResponseBuilder.error('El nombre de la cuenta es requerido');
    }

    // Generar nuevo ID (último ID + 1)
    const data = sheet.getDataRange().getValues();
    let nuevoId = 1;
    if (data.length > 1) {
      const ultimaFila = data[data.length - 1];
      nuevoId = parseFloat(ultimaFila[0]) + 1;
    }

    // Si no se proporcionó numeroTarjeta, generar uno basado en timestamp
    if (!numeroTarjeta) {
      numeroTarjeta = 'CT' + nuevoId + '-' + Date.now();
    }

    // Estructura: idCuenta, nombre, saldo, imagen, beneficiario, numeroTarjeta
    sheet.appendRow([
      nuevoId,
      nombre,
      saldoInicial,
      'ahorro', // imagen vacía
      'Mario Etzael Francisco Melo', // beneficiario vacío
      numeroTarjeta
    ]);
    return ResponseBuilder.success(
      { id: nuevoId, numeroCuenta: numeroTarjeta }
    );

  } catch (error) {
    Logger.error('crearCuenta', error);
    return ResponseBuilder.error('Error al crear la cuenta: ' + error.message);
  }
}

/**
 * Eliminar cuenta por número/ID
 */
function eliminarCuenta(params) {
  try {
    const sheet = SheetManager.getNuevasCuentas();
    
    if (!sheet) {
      return ResponseBuilder.error('Hoja Cuentas no encontrada');
    }

    const numeroCuenta = params.parameter.numeroCuenta;

    if (!numeroCuenta) {
      return ResponseBuilder.error('Número de cuenta es requerido');
    }

    // Convertir a número para comparación
    const idNum = parseFloat(numeroCuenta);

    // Buscar la fila
    const data = sheet.getDataRange().getValues();
    for (let i = 1; i < data.length; i++) {
      const idFila = parseFloat(data[i][0]);
      if (idFila === idNum) {
        sheet.deleteRow(i + 1);
        return ResponseBuilder.success({ message: 'Cuenta eliminada correctamente' });
      }
    }

    return ResponseBuilder.error('Cuenta no encontrada');

  } catch (error) {
    Logger.error('eliminarCuenta', error);
    return ResponseBuilder.error('Error al eliminar la cuenta: ' + error.message);
  }
}

/**
 * Módulo de operaciones con saldos
 */
const SaldoManager = {
  /**
   * Crea un índice de cuentas para búsqueda rápida
   */
  crearIndiceCuentas: function(data) {
    const indice = {};
    for (let i = 1; i < data.length; i++) {
      indice[data[i][COLUMNAS_CUENTAS.NOMBRE]] = i;
    }
    return indice;
  },
  
  /**
   * Verifica si hay saldo suficiente en una cuenta
   */
  verificarSaldo: function(sheet, cuenta, monto) {
    try {
      const data = sheet.getDataRange().getValues();
      const indice = this.crearIndiceCuentas(data);

      if (indice[cuenta] !== undefined) {
        const i = indice[cuenta];
        const saldoActual = parseFloat(data[i][COLUMNAS_CUENTAS.SALDO]) || 0;
        return saldoActual >= monto;
      }
      
      return false;
    } catch (error) {
      Logger.error('SaldoManager.verificarSaldo', error);
      return false;
    }
  },
  
  /**
   * Actualiza el saldo de una cuenta
   */
  actualizarSaldo: function(sheet, cuenta, monto, tipoTransaccion) {
    try {
      const data = sheet.getDataRange().getValues();
      const indice = this.crearIndiceCuentas(data);

      if (indice[cuenta] !== undefined) {
        const i = indice[cuenta];
        let saldoActual = parseFloat(data[i][COLUMNAS_CUENTAS.SALDO]) || 0;

        if (tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
            tipoTransaccion === TIPOS_TRANSACCION.PAGOS) {
          saldoActual -= monto;
        } else {
          saldoActual += monto;
        }

        sheet.getRange(i + 1, COLUMNAS_CUENTAS.SALDO + 1).setValue(saldoActual);
      }
    } catch (error) {
      Logger.error('SaldoManager.actualizarSaldo', error);
    }
  },
  
  /**
   * Actualiza saldo usando array de datos
   */
  actualizarSaldoPorNombre: function(cuentasData, cuenta, monto) {
    try {
      for (let j = 1; j < cuentasData.length; j++) {
        if (cuentasData[j][COLUMNAS_CUENTAS.NOMBRE] === cuenta) {
          cuentasData[j][COLUMNAS_CUENTAS.SALDO] = 
            parseFloat(cuentasData[j][COLUMNAS_CUENTAS.SALDO]) + monto;
          break;
        }
      }
    } catch (error) {
      Logger.error('SaldoManager.actualizarSaldoPorNombre', error);
    }
  }
};

// ============================================================================
// FUNCIONES DE CREACIÓN Y ELIMINACIÓN DE CUENTAS
// ============================================================================

/**
 * Crea una nueva cuenta en la hoja Cuentas
 * @param {Object} e - Objeto de petición con parámetros
 * @returns {Object} - Respuesta con el id y numeroCuenta generados
 */
function crearCuenta(e) {
  try {
    const params = e.parameter || e;
    const sheet = SheetManager.getNuevasCuentas();
    
    if (!sheet) {
      return ResponseBuilder.error('Hoja Cuentas no encontrada');
    }
    
    // Generar ID único
    const data = sheet.getDataRange().getValues();
    let maxId = 0;
    for (let i = 1; i < data.length; i++) {
      const currentId = parseInt(data[i][COLUMNAS_CUENTAS.ID]) || 0;
      if (currentId > maxId) maxId = currentId;
    }
    const nuevoId = maxId + 1;
    
    // Generar numeroTarjeta único (8 dígitos aleatorios)
    const numeroTarjeta = Math.floor(10000000 + Math.random() * 90000000).toString();
    
    // Preparar fila: [idCuenta, nombre, saldo, imagen, beneficiario, numeroTarjeta]
    const nuevaFila = [
      nuevoId,
      params.nombre || '',
      parseFloat(params.saldo) || 0,
      params.imagen || '',
      params.beneficiario || '',
      numeroTarjeta
    ];
    
    // Agregar la nueva fila
    sheet.appendRow(nuevaFila);
    
    return ResponseBuilder.success({
      id: nuevoId,
      numeroCuenta: numeroTarjeta
    });
    
  } catch (error) {
    Logger.error('crearCuenta', error);
    return ResponseBuilder.error('Error al crear cuenta: ' + error.message);
  }
}

/**
 * Elimina una cuenta por su numeroTarjeta
 * @param {Object} params - Parámetros de la petición
 * @returns {Object} - Respuesta de éxito o error
 */
function eliminarCuenta(params) {
  try {
    const numeroCuenta = params.parameter ? params.parameter.numeroCuenta : params.numeroCuenta;
    const esLlamadaAPI = !!params.parameter; // True si viene desde doPost
    
    if (!numeroCuenta) {
      const error = { codE: RESPONSE_CODE.NOK, msgE: 'numeroCuenta es requerido' };
      return esLlamadaAPI ? ResponseBuilder.error(error.msgE) : error;
    }
    
    const sheet = SheetManager.getNuevasCuentas();
    
    if (!sheet) {
      const error = { codE: RESPONSE_CODE.NOK, msgE: 'Hoja Cuentas no encontrada' };
      return esLlamadaAPI ? ResponseBuilder.error(error.msgE) : error;
    }
    
    const data = sheet.getDataRange().getValues();
    let filaEliminar = -1;
    
    // Buscar la fila con ese numeroTarjeta
    for (let i = 1; i < data.length; i++) {
      const numeroTarjetaCuenta = data[i][COLUMNAS_CUENTAS.NUMERO_TARJETA];
      
      if (numeroTarjetaCuenta && numeroTarjetaCuenta.toString() === numeroCuenta.toString()) {
        filaEliminar = i + 1;
        break;
      }
    }
    
    if (filaEliminar === -1) {
      const error = { codE: RESPONSE_CODE.NOK, msgE: 'Cuenta no encontrada' };
      return esLlamadaAPI ? ResponseBuilder.error(error.msgE) : error;
    }
    
    // Eliminar la fila
    sheet.deleteRow(filaEliminar);
    
    const success = { 
      codE: RESPONSE_CODE.OK, 
      msgE: MESSAGES.SUCCESS, 
      data: { message: 'Cuenta eliminada correctamente' } 
    };
    return esLlamadaAPI ? ResponseBuilder.success(success.data) : success;
    
  } catch (error) {
    Logger.error('eliminarCuenta', error);
    return ResponseBuilder.error('Error al eliminar cuenta: ' + error.message);
  }
}