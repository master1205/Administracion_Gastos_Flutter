// ============================================================================
// FUNCIONES DE GESTIÓN DE TRANSACCIONES
// ============================================================================

/**
 * Busca el numeroTarjeta de una cuenta por su nombre y sincroniza su meta si existe
 */
function syncMetaPorNombreCuenta(nombreCuenta) {
  if (!nombreCuenta) return;
  
  try {
    const sheet = SheetManager.getNuevasCuentas();
    const data = sheet.getDataRange().getValues();
    
    // Buscar la cuenta por nombre (columna B)
    for (let i = 1; i < data.length; i++) {
      const nombre = data[i][1]; // Columna B: nombre
      
      if (nombre === nombreCuenta) {
        const numeroTarjeta = data[i][5]; // Columna F: numeroTarjeta
        if (numeroTarjeta) {
          syncMetaSiEsNecesario(numeroTarjeta.toString());
        }
        break;
      }
    }
  } catch (error) {
    Logger.error('syncMetaPorNombreCuenta', error);
  }
}

/**
 * Obtiene todas las transacciones
 */
function getTransacciones() {
  try {
    const sheet = SheetManager.getNuevasTransacciones();
    const data = sheet.getDataRange().getValues();
    const encabezados = data[0];
    const transaccionesArray = [];

    for (let i = 1; i < data.length; i++) {
      const transaccion = {};
      for (let j = 0; j < encabezados.length; j++) {
        transaccion[encabezados[j]] = data[i][j];
      }
      transaccionesArray.push(transaccion);
    }

    return ResponseBuilder.success(transaccionesArray);
    
  } catch (error) {
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Carga nuevas transacciones (endpoint principal)
 */
function cargarTransacciones(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    
    // Validar datos
    const validacion = Validaciones.validarDatosTransaccion(data);
    if (!validacion.valido) {
      return ResponseBuilder.error(validacion.error);
    }

    const resultado = TransaccionManager.registrar(
      data.idTransaccion || '',
      data.tipoTransaccion,
      parseFloat(data.monto),
      data.descripcion,
      data.fecha,
      data.categoria || '',
      data.cuenta || '',
      data.cuentaOrigen || '',
      data.cuentaDestino || ''
    );

    Logger.transaccion('cargarTransacciones', resultado.data?.idTransaccion || 'N/A', resultado);
    return ContentService.createTextOutput(JSON.stringify(resultado))
      .setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    Logger.error('cargarTransacciones', error);
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Agrega una transacción simple (legacy)
 */
function addTransaccion(e) {
  try {
    const campo = e.parameter;
    
    const validacion = Validaciones.validarTransaccionSimple(campo);
    if (!validacion.valido) {
      return ResponseBuilder.error(validacion.error);
    }

    const id = FormatoUtil.generarId();
    const sheet = SheetManager.getTransacciones();
    
    sheet.appendRow([
      id,
      campo.categoria,
      campo.descripcion,
      parseFloat(campo.monto),
      campo.fecha,
      campo.tipoTransaccion
    ]);

    Logger.transaccion('addTransaccion', id, campo);
    return ResponseBuilder.success({ idTransaccion: id });
    
  } catch (error) {
    Logger.error('addTransaccion', error);
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Elimina una transacción
 */
function eliminarTransaccion(e) {
  try {
    const campo = e.parameter;
    
    const validacion = Validaciones.validarIdTransaccion(campo.idTransaccion);
    if (!validacion.valido) {
      return ResponseBuilder.error(validacion.error);
    }

    const resultado = TransaccionManager.eliminar(campo.idTransaccion);
    
    if (resultado.exito) {
      Logger.transaccion('eliminarTransaccion', campo.idTransaccion, 'Eliminada');
      return ResponseBuilder.custom(RESPONSE_CODE.OK, MESSAGES.TRANSACCION_ELIMINADA);
    } else {
      return ResponseBuilder.error(resultado.error);
    }
    
  } catch (error) {
    Logger.error('eliminarTransaccion', error);
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Módulo de gestión de transacciones
 */
const TransaccionManager = {
  /**
   * Registra o actualiza una transacción
   */
  registrar: function(idTransaccion, tipoTransaccion, monto, descripcion, fecha, 
                      categoria, cuenta, cuentaOrigen, cuentaDestino) {
    try {
      // Validar monto
      const validacionMonto = Validaciones.validarMonto(monto);
      if (!validacionMonto.valido) {
        return { codE: RESPONSE_CODE.NOK, msgE: validacionMonto.error };
      }

      // Si hay ID, actualizar
      if (idTransaccion) {
        return this.actualizar(idTransaccion, tipoTransaccion, monto, descripcion, 
                              fecha, categoria, cuenta, cuentaOrigen, cuentaDestino);
      }

      // Crear nueva transacción
      return this.crear(tipoTransaccion, monto, descripcion, fecha, categoria, 
                       cuenta, cuentaOrigen, cuentaDestino);
      
    } catch (error) {
      Logger.error('TransaccionManager.registrar', error);
      return { codE: RESPONSE_CODE.NOK, msgE: MESSAGES.ERROR_GENERAL + ": " + error.message };
    }
  },
  
  /**
   * Crea una nueva transacción
   */
  crear: function(tipoTransaccion, monto, descripcion, fecha, categoria, 
                  cuenta, cuentaOrigen, cuentaDestino) {
    try {
      // Validaciones específicas
      const validacionCuenta = Validaciones.validarCuentaParaGasto(tipoTransaccion, cuenta);
      if (!validacionCuenta.valido) {
        return { codE: RESPONSE_CODE.NOK, msgE: validacionCuenta.error };
      }

      const validacionTraspaso = Validaciones.validarCuentasParaTraspaso(
        tipoTransaccion, cuentaOrigen, cuentaDestino
      );
      if (!validacionTraspaso.valido) {
        return { codE: RESPONSE_CODE.NOK, msgE: validacionTraspaso.error };
      }

      const sheet = SheetManager.getNuevasCuentas();

      // Verificar saldo para gastos
      if (tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
          tipoTransaccion === TIPOS_TRANSACCION.PAGOS) {
        if (!SaldoManager.verificarSaldo(sheet, cuenta, monto)) {
          return { codE: RESPONSE_CODE.NOK, msgE: MESSAGES.SALDO_INSUFICIENTE };
        }
      }

      // Verificar saldo para traspasos
      if (tipoTransaccion === TIPOS_TRANSACCION.TRASPASOS) {
        if (!SaldoManager.verificarSaldo(sheet, cuentaOrigen, monto)) {
          return { codE: RESPONSE_CODE.NOK, msgE: MESSAGES.SALDO_INSUFICIENTE_ORIGEN };
        }
      }

      // Actualizar saldos
      if (tipoTransaccion === TIPOS_TRANSACCION.TRASPASOS) {
        SaldoManager.actualizarSaldo(sheet, cuentaOrigen, monto, TIPOS_TRANSACCION.GASTOS);
        SaldoManager.actualizarSaldo(sheet, cuentaDestino, monto, TIPOS_TRANSACCION.INGRESOS);
        
        // Sincronizar metas si existen (optimizado: una sola lectura de datos)
        const dataCuentas = sheet.getDataRange().getValues();
        this._syncMetasOptimizado(dataCuentas, cuentaOrigen);
        this._syncMetasOptimizado(dataCuentas, cuentaDestino);
        
      } else {
        SaldoManager.actualizarSaldo(sheet, cuenta, monto, tipoTransaccion);
        
        // Sincronizar meta si existe (optimizado)
        const dataCuentas = sheet.getDataRange().getValues();
        this._syncMetasOptimizado(dataCuentas, cuenta);
      }

      // Generar ID y registrar
      const idTransaccion = FormatoUtil.generarId();
      const sheetTransacciones = SheetManager.getNuevasTransacciones();
      
      sheetTransacciones.appendRow([
        idTransaccion,
        tipoTransaccion,
        monto,
        descripcion,
        fecha,
        categoria,
        cuenta,
        cuentaOrigen,
        cuentaDestino
      ]);

      Logger.transaccion('TransaccionManager.crear', idTransaccion, {
        tipo: tipoTransaccion,
        monto: monto
      });

      return { 
        codE: RESPONSE_CODE.OK, 
        msgE: MESSAGES.TRANSACCION_REGISTRADA,
        data: { idTransaccion: idTransaccion }
      };
      
    } catch (error) {
      Logger.error('TransaccionManager.crear', error);
      return { codE: RESPONSE_CODE.NOK, msgE: MESSAGES.ERROR_GENERAL + ": " + error.message };
    }
  },
  
  /**
   * Actualiza una transacción existente
   */
  actualizar: function(idTransaccion, tipoTransaccion, monto, descripcion, fecha, 
                      categoria, cuenta, cuentaOrigen, cuentaDestino) {
    try {
      const sheet = SheetManager.getNuevasTransacciones();
      const data = sheet.getDataRange().getValues();
      const cuentasSheet = SheetManager.getNuevasCuentas();

      for (let i = 1; i < data.length; i++) {
        if (data[i][COLUMNAS_TRANSACCIONES.ID] == idTransaccion) {
          // Guardar datos antiguos
          const oldData = {
            tipo: data[i][COLUMNAS_TRANSACCIONES.TIPO],
            monto: parseFloat(data[i][COLUMNAS_TRANSACCIONES.MONTO]),
            cuenta: data[i][COLUMNAS_TRANSACCIONES.CUENTA],
            cuentaOrigen: data[i][COLUMNAS_TRANSACCIONES.CUENTA_ORIGEN],
            cuentaDestino: data[i][COLUMNAS_TRANSACCIONES.CUENTA_DESTINO]
          };

          // Revertir saldos antiguos
          this._revertirSaldos(cuentasSheet, oldData);

          // Validar nuevos saldos
          const validacion = this._validarNuevosSaldos(
            cuentasSheet, tipoTransaccion, cuenta, cuentaOrigen, monto
          );
          
          if (!validacion.valido) {
            // Restaurar saldos si falla
            this._aplicarSaldos(cuentasSheet, oldData);
            return { codE: RESPONSE_CODE.NOK, msgE: validacion.error };
          }

          // Aplicar nuevos saldos
          this._aplicarNuevosSaldos(cuentasSheet, {
            tipo: tipoTransaccion,
            monto: monto,
            cuenta: cuenta,
            cuentaOrigen: cuentaOrigen,
            cuentaDestino: cuentaDestino
          });

          // Sincronizar metas después de aplicar nuevos saldos (optimizado)
          const dataCuentas = cuentasSheet.getDataRange().getValues();
          if (tipoTransaccion === TIPOS_TRANSACCION.TRASPASOS) {
            this._syncMetasOptimizado(dataCuentas, cuentaOrigen);
            this._syncMetasOptimizado(dataCuentas, cuentaDestino);
          } else {
            this._syncMetasOptimizado(dataCuentas, cuenta);
          }

          // Actualizar fila
          sheet.getRange(i + 1, COLUMNAS_TRANSACCIONES.TIPO + 1, 1, 8).setValues([[
            tipoTransaccion,
            monto,
            descripcion,
            fecha,
            categoria,
            cuenta,
            cuentaOrigen,
            cuentaDestino
          ]]);

          Logger.transaccion('TransaccionManager.actualizar', idTransaccion, {
            tipo: tipoTransaccion,
            monto: monto
          });

          return { 
            codE: RESPONSE_CODE.OK, 
            msgE: MESSAGES.TRANSACCION_ACTUALIZADA,
            data: { idTransaccion: idTransaccion }
          };
        }
      }
      
      return { codE: RESPONSE_CODE.NOK, msgE: MESSAGES.TRANSACCION_NO_ENCONTRADA };
      
    } catch (error) {
      Logger.error('TransaccionManager.actualizar', error);
      return { codE: RESPONSE_CODE.NOK, msgE: MESSAGES.ERROR_GENERAL + ": " + error.message };
    }
  },
  
  /**
   * Elimina una transacción
   */
  eliminar: function(idTransaccion) {
    try {
      const sheet = SheetManager.getNuevasTransacciones();
      const data = sheet.getDataRange().getValues();
      const cuentasData = SheetManager.getNuevasCuentas().getDataRange().getValues();

      for (let i = data.length - 1; i >= 1; i--) {
        if (data[i][COLUMNAS_TRANSACCIONES.ID] === idTransaccion) {
          const tipoTransaccion = data[i][COLUMNAS_TRANSACCIONES.TIPO];
          const monto = parseFloat(data[i][COLUMNAS_TRANSACCIONES.MONTO]);
          const cuenta = data[i][COLUMNAS_TRANSACCIONES.CUENTA];
          const cuentaOrigen = data[i][COLUMNAS_TRANSACCIONES.CUENTA_ORIGEN];
          const cuentaDestino = data[i][COLUMNAS_TRANSACCIONES.CUENTA_DESTINO];

          // Revertir cambios en saldos
          if (tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
              tipoTransaccion === TIPOS_TRANSACCION.PAGOS) {
            SaldoManager.actualizarSaldoPorNombre(cuentasData, cuenta, monto);
            syncMetaPorNombreCuenta(cuenta);
            
          } else if (tipoTransaccion === TIPOS_TRANSACCION.INGRESOS || 
                     tipoTransaccion === TIPOS_TRANSACCION.REEMBOLSOS) {
            SaldoManager.actualizarSaldoPorNombre(cuentasData, cuenta, -monto);
            syncMetaPorNombreCuenta(cuenta);
            
          } else if (tipoTransaccion === TIPOS_TRANSACCION.TRASPASOS) {
            SaldoManager.actualizarSaldoPorNombre(cuentasData, cuentaOrigen, monto);
            SaldoManager.actualizarSaldoPorNombre(cuentasData, cuentaDestino, -monto);
            syncMetaPorNombreCuenta(cuentaOrigen);
            syncMetaPorNombreCuenta(cuentaDestino);
          }

          // Guardar cambios
          SheetManager.getNuevasCuentas().getRange(
            1, 1, cuentasData.length, cuentasData[0].length
          ).setValues(cuentasData);

          // Eliminar fila
          sheet.deleteRow(i + 1);
          
          return { exito: true };
        }
      }

      return { exito: false, error: MESSAGES.TRANSACCION_NO_ENCONTRADA };
      
    } catch (error) {
      Logger.error('TransaccionManager.eliminar', error);
      return { exito: false, error: MESSAGES.ERROR_GENERAL + ": " + error.message };
    }
  },
  
  // Métodos privados auxiliares
  _revertirSaldos: function(sheet, oldData) {
    if (oldData.tipo === TIPOS_TRANSACCION.TRASPASOS) {
      SaldoManager.actualizarSaldo(sheet, oldData.cuentaOrigen, oldData.monto, TIPOS_TRANSACCION.INGRESOS);
      SaldoManager.actualizarSaldo(sheet, oldData.cuentaDestino, oldData.monto, TIPOS_TRANSACCION.GASTOS);
    } else {
      const tipoReversion = (oldData.tipo === TIPOS_TRANSACCION.GASTOS || 
                            oldData.tipo === TIPOS_TRANSACCION.PAGOS) 
                            ? TIPOS_TRANSACCION.INGRESOS 
                            : TIPOS_TRANSACCION.GASTOS;
      SaldoManager.actualizarSaldo(sheet, oldData.cuenta, oldData.monto, tipoReversion);
    }
  },
  
  _aplicarSaldos: function(sheet, data) {
    if (data.tipo === TIPOS_TRANSACCION.TRASPASOS) {
      SaldoManager.actualizarSaldo(sheet, data.cuentaOrigen, data.monto, TIPOS_TRANSACCION.GASTOS);
      SaldoManager.actualizarSaldo(sheet, data.cuentaDestino, data.monto, TIPOS_TRANSACCION.INGRESOS);
    } else {
      SaldoManager.actualizarSaldo(sheet, data.cuenta, data.monto, data.tipo);
    }
  },
  
  _validarNuevosSaldos: function(sheet, tipoTransaccion, cuenta, cuentaOrigen, monto) {
    if (tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
        tipoTransaccion === TIPOS_TRANSACCION.PAGOS) {
      if (!SaldoManager.verificarSaldo(sheet, cuenta, monto)) {
        return { valido: false, error: MESSAGES.SALDO_INSUFICIENTE };
      }
    }

    if (tipoTransaccion === TIPOS_TRANSACCION.TRASPASOS) {
      if (!SaldoManager.verificarSaldo(sheet, cuentaOrigen, monto)) {
        return { valido: false, error: MESSAGES.SALDO_INSUFICIENTE_ORIGEN };
      }
    }

    return { valido: true };
  },
  
  _aplicarNuevosSaldos: function(sheet, newData) {
    if (newData.tipo === TIPOS_TRANSACCION.TRASPASOS) {
      SaldoManager.actualizarSaldo(sheet, newData.cuentaOrigen, newData.monto, TIPOS_TRANSACCION.GASTOS);
      SaldoManager.actualizarSaldo(sheet, newData.cuentaDestino, newData.monto, TIPOS_TRANSACCION.INGRESOS);
    } else {
      SaldoManager.actualizarSaldo(sheet, newData.cuenta, newData.monto, newData.tipo);
    }
  },
  
  /**
   * Sincroniza meta usando datos ya cargados (optimización)
   */
  _syncMetasOptimizado: function(dataCuentas, nombreCuenta) {
    if (!nombreCuenta || !dataCuentas) return;
    
    try {
      // Buscar la cuenta por nombre (columna B) en los datos ya cargados
      for (let i = 1; i < dataCuentas.length; i++) {
        const nombre = dataCuentas[i][1]; // Columna B: nombre
        
        if (nombre === nombreCuenta) {
          const numeroTarjeta = dataCuentas[i][5]; // Columna F: numeroTarjeta
          if (numeroTarjeta) {
            syncMetaSiEsNecesario(numeroTarjeta.toString());
          }
          break;
        }
      }
    } catch (error) {
      Logger.error('TransaccionManager._syncMetasOptimizado', error);
    }
  }
};