// ============================================================================
// FUNCIONES DE GESTIÓN DE CATEGORÍAS
// ============================================================================

/**
 * Obtiene todas las categorías
 */
function getCategorias() {
  try {
    const sheet = SheetManager.getCategorias();
    const data = sheet.getDataRange().getValues();
    const encabezados = data[0];
    const categoriasArray = [];

    for (let i = 1; i < data.length; i++) {
      const categoria = {};
      for (let j = 0; j < encabezados.length; j++) {
        categoria[encabezados[j]] = data[i][j];
      }
      categoriasArray.push(categoria);
    }
    
    return ResponseBuilder.success(categoriasArray);
    
  } catch (error) {
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Obtiene gastos agrupados por categoría
 */
function getGastosPorCategoria() {
  try {
    const sheet = SheetManager.getNuevasTransacciones();
    const data = sheet.getDataRange().getValues();
    const gastosPorCategoria = {};

    for (let i = 1; i < data.length; i++) {
      const tipoTransaccion = data[i][COLUMNAS_TRANSACCIONES.TIPO];
      const categoria = data[i][COLUMNAS_TRANSACCIONES.CATEGORIA];
      const monto = parseFloat(data[i][COLUMNAS_TRANSACCIONES.MONTO]) || 0;

      if (tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
          tipoTransaccion === TIPOS_TRANSACCION.PAGOS) {
        if (!gastosPorCategoria[categoria]) {
          gastosPorCategoria[categoria] = 0;
        }
        gastosPorCategoria[categoria] += monto;
      }
    }

    Logger.info('getGastosPorCategoria', 'Análisis completado', {
      categorias: Object.keys(gastosPorCategoria).length
    });
    return ResponseBuilder.success(gastosPorCategoria);
    
  } catch (error) {
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}
