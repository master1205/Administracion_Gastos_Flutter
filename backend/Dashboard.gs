// ============================================================================
// ENDPOINT UNIFICADO DE DASHBOARD
// ============================================================================

/**
 * Obtiene todos los datos del dashboard en una sola llamada
 * Optimiza el rendimiento al reducir múltiples llamadas HTTP a una sola
 */
function getDashboardData(e) {
  try {
    Logger.info('getDashboardData', 'Iniciando carga unificada');
    
    // Cargar datos con caché (una sola lectura de cada hoja)
    const cuentasData = CachedSheetManager.getCuentas();
    const metasData = CachedSheetManager.getMetas();
    const transaccionesData = CachedSheetManager.getTransacciones();
    
    // Procesar cuentas
    const cuentas = procesarCuentas(cuentasData);
    
    // Procesar metas
    const metas = procesarMetas(metasData);
    
    // Calcular gastos por categoría
    const gastosPorCategoria = calcularGastosPorCategoria(transaccionesData);
    
    // Calcular saldos consolidados
    const saldosConsolidados = calcularSaldosConsolidados(cuentasData, transaccionesData);
    
    const resultado = {
      cuentas: cuentas,
      metas: metas,
      gastosPorCategoria: gastosPorCategoria,
      saldos: saldosConsolidados,
      timestamp: new Date().toISOString(),
      cached: true // Indica que los datos podrían venir de caché
    };
    
    Logger.info('getDashboardData', 'Datos cargados exitosamente', {
      cuentas: cuentas.length,
      metas: metas.length,
      categorias: Object.keys(gastosPorCategoria).length
    });
    
    return ResponseBuilder.success(resultado);
    
  } catch (error) {
    Logger.error('getDashboardData', error);
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Procesa los datos de cuentas desde el array cargado
 */
function procesarCuentas(cuentasData) {
  const cuentas = [];
  
  for (let i = 1; i < cuentasData.length; i++) {
    if (!cuentasData[i][0]) continue; // Skip filas vacías
    
    cuentas.push({
      idCuenta: cuentasData[i][COLUMNAS_CUENTAS.ID],
      nombre: cuentasData[i][COLUMNAS_CUENTAS.NOMBRE],
      saldo: parseFloat(cuentasData[i][COLUMNAS_CUENTAS.SALDO]) || 0,
      imagen: cuentasData[i][COLUMNAS_CUENTAS.IMAGEN] || '',
      beneficiario: cuentasData[i][COLUMNAS_CUENTAS.BENEFICIARIO] || '',
      numeroTarjeta: cuentasData[i][COLUMNAS_CUENTAS.NUMERO_TARJETA] || ''
    });
  }
  
  return cuentas;
}

/**
 * Procesa los datos de metas desde el array cargado
 */
function procesarMetas(metasData) {
  const fechaActual = new Date().toISOString();
  const metas = [];
  
  for (let i = 1; i < metasData.length; i++) {
    const row = metasData[i];
    
    if (!row[0]) continue; // Skip filas vacías

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
  
  return metas;
}

/**
 * Calcula gastos por categoría desde el array de transacciones
 */
function calcularGastosPorCategoria(transaccionesData) {
  const gastosPorCategoria = {};
  
  for (let i = 1; i < transaccionesData.length; i++) {
    const row = transaccionesData[i];
    
    if (!row[COLUMNAS_TRANSACCIONES.ID]) continue;
    
    const tipoTransaccion = row[COLUMNAS_TRANSACCIONES.TIPO];
    const categoria = row[COLUMNAS_TRANSACCIONES.CATEGORIA] || 'Sin categoría';
    const monto = parseFloat(row[COLUMNAS_TRANSACCIONES.MONTO]) || 0;
    
    // Solo contar gastos y pagos
    if (tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
        tipoTransaccion === TIPOS_TRANSACCION.PAGOS) {
      
      if (!gastosPorCategoria[categoria]) {
        gastosPorCategoria[categoria] = 0;
      }
      gastosPorCategoria[categoria] += monto;
    }
  }
  
  return gastosPorCategoria;
}

/**
 * Calcula saldos consolidados
 */
function calcularSaldosConsolidados(cuentasData, transaccionesData) {
  let totalIngresos = 0;
  let totalGastos = 0;
  let saldoCuentas = 0;
  
  // Sumar saldos de cuentas
  for (let i = 1; i < cuentasData.length; i++) {
    if (cuentasData[i][0]) {
      saldoCuentas += parseFloat(cuentasData[i][COLUMNAS_CUENTAS.SALDO]) || 0;
    }
  }
  
  // Sumar ingresos y gastos de transacciones
  for (let i = 1; i < transaccionesData.length; i++) {
    const row = transaccionesData[i];
    if (!row[COLUMNAS_TRANSACCIONES.ID]) continue;
    
    const tipo = row[COLUMNAS_TRANSACCIONES.TIPO];
    const monto = parseFloat(row[COLUMNAS_TRANSACCIONES.MONTO]) || 0;
    
    if (tipo === TIPOS_TRANSACCION.INGRESOS || tipo === TIPOS_TRANSACCION.REEMBOLSOS) {
      totalIngresos += monto;
    } else if (tipo === TIPOS_TRANSACCION.GASTOS || tipo === TIPOS_TRANSACCION.PAGOS) {
      totalGastos += monto;
    }
  }
  
  return {
    ingresos: totalIngresos,
    gastos: totalGastos,
    saldoCuentas: saldoCuentas
  };
}
