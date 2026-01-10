// ============================================================================
// CORTE MENSUAL - Registro de transacciones en Sheets
// ============================================================================

/**
 * Registra un lote de transacciones desde Firebase al finalizar el mes
 * Endpoint: POST ?action=registrarCorteMensual
 */
function registrarCorteMensual(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    
    // Validar que venga el array de transacciones
    if (!data.transacciones || !Array.isArray(data.transacciones)) {
      return ResponseBuilder.error("Se requiere un array de transacciones");
    }
    
    // Validar que venga el resumen financiero
    if (!data.resumen || typeof data.resumen !== 'object') {
      return ResponseBuilder.error("Se requiere resumen financiero (totalIngresos, totalGastos, saldoTotal)");
    }
    
    const transacciones = data.transacciones;
    const resumen = data.resumen;
    
    Logger.info('registrarCorteMensual', 'Datos recibidos', {
      transacciones: transacciones.length,
      resumen: resumen
    });
    
    if (transacciones.length === 0) {
      return ResponseBuilder.success({
        mensaje: "No hay transacciones para registrar",
        registradas: 0
      });
    }
    
    // ✅ Generar reporte mensual directamente con las transacciones del payload (sin escribir en Sheets)
    Logger.info('registrarCorteMensual', 'Iniciando generación de reporte PDF directo');
    const resultadoReporte = GeneradorReportes.corteMensual(resumen, transacciones);
    
    if (resultadoReporte.exito) {
      Logger.info('registrarCorteMensual', 'Reporte PDF generado exitosamente');
      return ResponseBuilder.success({
        mensaje: "Corte mensual completado y reporte generado exitosamente",
        registradas: transacciones.length,
        total: transacciones.length,
        reporteUrl: resultadoReporte.archivo
      });
    } else {
      Logger.error('registrarCorteMensual', 'Error al generar reporte: ' + resultadoReporte.error);
      return ResponseBuilder.error(
        "Error al generar reporte: " + resultadoReporte.error
      );
    }
    
  } catch (error) {
    Logger.error('registrarCorteMensual', error);
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

// NOTA: Este endpoint ya NO escribe en Google Sheets.
// Las transacciones se usan directamente del payload para generar el PDF.
// Sheets queda solo para propósitos legacy o respaldo manual.
