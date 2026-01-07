function getMetas(params) {
  try {
    // Usar caché si está disponible
    const data = CachedSheetManager.getMetas();
    
    if (!data || data.length === 0) {
      Logger.error('getMetas', 'No se pudieron cargar las metas');
      return ResponseBuilder.error('No se pudieron cargar las metas');
    }
    
    if (data.length <= 1) {
      return ResponseBuilder.success([]);
    }

    const fechaActual = new Date().toISOString();
    const metas = [];
    
    for (let i = 1; i < data.length; i++) {
      const row = data[i];
      
      // Validar que la fila tiene datos
      if (!row[0]) continue;

      // Función auxiliar para formatear fechas
      const formatearFecha = (fecha) => {
        if (!fecha) return fechaActual;
        try {
          return new Date(fecha).toISOString();
        } catch (e) {
          return fechaActual;
        }
      };

      metas.push({
        id: row[0].toString(),
        nombre: row[1] || '',
        descripcion: row[2] || '',
        montoObjetivo: parseFloat(row[3]) || 0,
        montoActual: parseFloat(row[4]) || 0,
        fechaInicio: formatearFecha(row[5]),
        fechaObjetivo: formatearFecha(row[6]),
        icono: row[7] || 'savings',
        color: row[8] || '4CAF50',
        completada: row[9] === true || row[9] === 'true',
        numeroCuenta: row[11] ? row[11].toString() : ''
      });
    }

    return ResponseBuilder.success(metas);

  } catch (error) {
    return ResponseBuilder.error('Error al obtener las metas: ' + error.message);
  }
}

/**
 * Guardar o actualizar meta
 */
function saveMeta(params) {
  try {
    const sheet = SheetManager.getMetas();
    
    if (!sheet) {
      return ResponseBuilder.error('Hoja Metas no encontrada');
    }

    const data = sheet.getDataRange().getValues();
    
    // Convertir id a número para comparación
    const id = params.parameter.id ? parseFloat(params.parameter.id) : Date.now();
    const nombre = params.parameter.nombre;
    const descripcion = params.parameter.descripcion || '';
    const montoObjetivo = parseFloat(params.parameter.montoObjetivo) || 0;
    const montoActual = parseFloat(params.parameter.montoActual) || 0;
    const fechaInicio = params.parameter.fechaInicio || new Date().toISOString();
    const fechaObjetivo = params.parameter.fechaObjetivo;
    const icono = params.parameter.icono || 'savings';
    const color = params.parameter.color || '4CAF50';
    const completada = params.parameter.completada === 'true';
    const numeroCuenta = params.parameter.numeroCuenta || '';

    // Validar campos requeridos
    if (!nombre || !fechaObjetivo || montoObjetivo <= 0) {
      return ResponseBuilder.error('Faltan campos requeridos o son inválidos');
    }

    // Buscar si existe
    let filaExistente = -1;
    let numeroCuentaExistente = '';
    
    for (let i = 1; i < data.length; i++) {
      if (parseFloat(data[i][0]) === id) {
        filaExistente = i + 1;
        numeroCuentaExistente = data[i][11] ? data[i][11].toString() : ''; // Preservar numeroCuenta existente
        break;
      }
    }

    // Si es actualización y no viene numeroCuenta, usar el existente
    const numeroCuentaFinal = numeroCuenta || numeroCuentaExistente;

    const ahora = new Date().toISOString();

    if (filaExistente > 0) {
      // Actualizar
      sheet.getRange(filaExistente, 1, 1, 12).setValues([[
        id,
        nombre,
        descripcion,
        montoObjetivo,
        montoActual,
        fechaInicio,
        fechaObjetivo,
        icono,
        color,
        completada,
        ahora,
        numeroCuentaFinal
      ]]);

      Logger.info('saveMeta', 'Meta actualizada', { id, nombre });
      
      // Invalidar caché después de actualizar
      CachedSheetManager.invalidateMetas();
      
      return ResponseBuilder.success({ id: id });
    } else {
      // Crear nueva
      sheet.appendRow([
        id,
        nombre,
        descripcion,
        montoObjetivo,
        montoActual,
        fechaInicio,
        fechaObjetivo,
        icono,
        color,
        completada,
        ahora,
        numeroCuenta
      ]);

      Logger.info('saveMeta', 'Meta creada', { id, nombre });
      
      // Invalidar caché después de crear
      CachedSheetManager.invalidateMetas();
      
      return ResponseBuilder.success({ id: id });
    }

  } catch (error) {
    Logger.error('saveMeta', error);
    return ResponseBuilder.error('Error al guardar la meta: ' + error.message);
  }
}

/**
 * Eliminar meta
 */
function deleteMeta(params) {
  try {
    const sheet = SheetManager.getMetas();
    
    if (!sheet) {
      return ResponseBuilder.error('Hoja Metas no encontrada');
    }

    const data = sheet.getDataRange().getValues();
    const id = params.parameter.id;

    if (!id) {
      return ResponseBuilder.error('ID de meta es requerido');
    }

    // Convertir id a número para comparación
    const idNum = parseFloat(id);

    // Buscar la fila
    for (let i = 1; i < data.length; i++) {
      const idFila = parseFloat(data[i][0]);
      if (idFila === idNum) {
        // Obtener numeroCuenta antes de eliminar la meta
        const numeroCuenta = data[i][11] ? data[i][11].toString() : '';
        
        // Eliminar la cuenta asociada si existe
        if (numeroCuenta) {
          try {
            Logger.info('deleteMeta', 'Intentando eliminar cuenta', { numeroCuenta });
            const resultadoCuenta = eliminarCuenta({ numeroCuenta: numeroCuenta });
            Logger.info('deleteMeta', 'Respuesta eliminarCuenta', { resultado: resultadoCuenta });
            
            if (resultadoCuenta && resultadoCuenta.codE === RESPONSE_CODE.OK) {
              Logger.info('deleteMeta', 'Cuenta asociada eliminada exitosamente', { numeroCuenta });
            } else {
              Logger.warning('deleteMeta', 'No se pudo eliminar cuenta', { 
                numeroCuenta, 
                resultado: resultadoCuenta,
                codE: resultadoCuenta ? resultadoCuenta.codE : 'sin codE'
              });
            }
          } catch (error) {
            Logger.error('deleteMeta', 'Error al eliminar cuenta asociada: ' + error.toString(), { 
              numeroCuenta, 
              error: error.message,
              stack: error.stack 
            });
            // Continuar eliminando la meta aunque falle la cuenta
          }
        } else {
          Logger.info('deleteMeta', 'Meta no tiene numeroCuenta asociado');
        }
        
        // Eliminar la meta
        sheet.deleteRow(i + 1);
        Logger.info('deleteMeta', 'Meta eliminada', { id: idNum });
        
        // Invalidar caché después de eliminar
        CachedSheetManager.invalidateMetas();
        CachedSheetManager.invalidateCuentas();
        
        return ResponseBuilder.success({ message: 'Meta eliminada correctamente' });
      }
    }

    return ResponseBuilder.error('Meta no encontrada');

  } catch (error) {
    Logger.error('deleteMeta', error);
    return ResponseBuilder.error('Error al eliminar la meta: ' + error.message);
  }
}

/**
 * Actualizar progreso de meta (abonar)
 */
function updateMetaProgress(params) {
  try {
    const sheet = SheetManager.getMetas();
    
    if (!sheet) {
      return ResponseBuilder.error('Hoja Metas no encontrada');
    }

    const data = sheet.getDataRange().getValues();
    const id = params.parameter.id;
    const montoActual = parseFloat(params.parameter.montoActual);

    if (!id || isNaN(montoActual)) {
      return ResponseBuilder.error('ID y monto actual son requeridos');
    }

    // Convertir id a número para comparación
    const idNum = parseFloat(id);

    // Buscar la fila
    for (let i = 1; i < data.length; i++) {
      const idFila = parseFloat(data[i][0]);
      if (idFila === idNum) {
        const montoObjetivo = parseFloat(data[i][3]);
        const completada = montoActual >= montoObjetivo;

        // Actualizar monto actual (columna E) y completada (columna J)
        sheet.getRange(i + 1, 5).setValue(montoActual);
        sheet.getRange(i + 1, 10).setValue(completada);
        sheet.getRange(i + 1, 11).setValue(new Date().toISOString());

        Logger.info('updateMetaProgress', 'Progreso actualizado', {
          id: idNum,
          montoActual,
          completada
        });

        return ResponseBuilder.success({
          completada: completada,
          mensaje: completada ? '¡Meta completada!' : 'Progreso actualizado correctamente'
        });
      }
    }

    return ResponseBuilder.error('Meta no encontrada');

  } catch (error) {
    Logger.error('updateMetaProgress', error);
    return ResponseBuilder.error('Error al actualizar el progreso: ' + error.message);
  }
}

/**
 * Sincroniza el MontoActual de una meta con el saldo de su cuenta asociada
 * @param {string} numeroCuenta - El numeroTarjeta de la cuenta
 */
function syncMetaSiEsNecesario(numeroCuenta) {
  if (!numeroCuenta) return;
  
  try {
    const sheetMetas = SheetManager.getMetas();
    const sheetCuentas = SheetManager.getNuevasCuentas();
    
    if (!sheetMetas || !sheetCuentas) {
      return;
    }

    const metasData = sheetMetas.getDataRange().getValues();
    const cuentasData = sheetCuentas.getDataRange().getValues();
    
    // Buscar meta con ese numeroCuenta
    let metaEncontrada = null;
    let filaMeta = -1;
    
    for (let i = 1; i < metasData.length; i++) {
      const numeroCuentaMeta = metasData[i][11]; // Columna L (índice 11): NumeroCuenta
      
      if (numeroCuentaMeta && numeroCuentaMeta.toString() === numeroCuenta.toString()) {
        metaEncontrada = {
          id: metasData[i][0],
          nombre: metasData[i][1],
          montoObjetivo: parseFloat(metasData[i][3]) || 0,
          montoActual: parseFloat(metasData[i][4]) || 0
        };
        filaMeta = i + 1; // +1 porque las filas en Sheets empiezan en 1
        break;
      }
    }
    
    // Si no hay meta asociada, no hacer nada
    if (!metaEncontrada) {
      Logger.info('syncMetaSiEsNecesario', 'No hay meta asociada', { numeroCuenta });
      return;
    }
    
    // Buscar la cuenta por numeroTarjeta (columna F, índice 5)
    let saldoCuenta = 0;
    let cuentaEncontrada = false;
    
    for (let i = 1; i < cuentasData.length; i++) {
      const numeroTarjetaCuenta = cuentasData[i][COLUMNAS_CUENTAS.NUMERO_TARJETA]; // Columna F
      
      if (numeroTarjetaCuenta && numeroTarjetaCuenta.toString() === numeroCuenta.toString()) {
        saldoCuenta = parseFloat(cuentasData[i][COLUMNAS_CUENTAS.SALDO]) || 0; // Columna C
        cuentaEncontrada = true;
        break;
      }
    }
    
    if (!cuentaEncontrada) {
      Logger.warning('syncMetaSiEsNecesario', 'Cuenta no encontrada', { numeroCuenta });
      return;
    }
    
    // Actualizar MontoActual de la meta con el saldo de la cuenta
    const montoObjetivo = metaEncontrada.montoObjetivo;
    const completada = saldoCuenta >= montoObjetivo;
    
    // Actualizar columnas:
    // E (5): MontoActual
    // J (10): Completada  
    // K (11): FechaActualizacion
    sheetMetas.getRange(filaMeta, 5).setValue(saldoCuenta); // Columna E
    sheetMetas.getRange(filaMeta, 10).setValue(completada); // Columna J
    sheetMetas.getRange(filaMeta, 11).setValue(new Date().toISOString()); // Columna K
    
    Logger.info('syncMetaSiEsNecesario', 'Meta sincronizada', {
      id: metaEncontrada.id,
      nombre: metaEncontrada.nombre,
      numeroCuenta: numeroCuenta,
      saldoAnterior: metaEncontrada.montoActual,
      saldoNuevo: saldoCuenta,
      completada: completada
    });
    
  } catch (error) {
    Logger.error('syncMetaSiEsNecesario', error);
  }
}