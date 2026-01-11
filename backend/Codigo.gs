// ============================================================================
// ENDPOINTS PRINCIPALES
// ============================================================================

/**
 * Maneja las peticiones GET
 */
function doGet(e) {
  return routeRequest(e, {
    'getCategorias': getCategorias,
    'getTransacciones': getTransacciones,
    'getCuentas': getCuentas,
    'getNuevasCuentas': getNuevasCuentas,
    'getSaldos': getSaldos,
    'listReportes': listReportes,
    'getGastosPorCategoria': getGastosPorCategoria,
    'getNotificaciones': getNotificaciones,
    'getMetas': getMetas,
    'getDashboardData': getDashboardData // ← NUEVO ENDPOINT UNIFICADO
  });
}

/**
 * Maneja las peticiones POST
 */
function doPost(e) {
  return routeRequest(e, {
    'addTransaccion': addTransaccion,
    'deleteTransaccion': eliminarTransaccion,
    'addTransacciones': cargarTransacciones,
    'updateAccountBalance': updateAccountBalance,
    'saveNotificacion': saveNotificacion,       // ← NUEVA RUTA
    'deleteNotificacion': deleteNotificacion,   // ← NUEVA RUTA
    'toggleNotificacion': toggleNotificacion,   // ← NUEVA RUTA
    'saveMeta':saveMeta,
    'deleteMeta':deleteMeta,
    'updateMetaProgress': updateMetaProgress,
    'crearCuenta':crearCuenta,
    'eliminarCuenta':eliminarCuenta,
    'registrarCorteMensual': registrarCorteMensual  // ← CORTE MENSUAL
  });
}

/**
 * Enruta la petición al endpoint correspondiente
 */
function routeRequest(e, endpoints) {
  try {
    const action = e.parameter.action;
    
    if (endpoints[action]) {
      return endpoints[action](e);
    }
    
    return ResponseBuilder.error(MESSAGES.ACCION_INVALIDA);
    
  } catch (error) {
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}
