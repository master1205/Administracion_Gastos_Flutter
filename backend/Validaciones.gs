// ============================================================================
// VALIDACIONES CENTRALIZADAS
// ============================================================================

const Validaciones = {
  /**
   * Valida que el monto sea válido
   */
  validarMonto: function(monto) {
    if (isNaN(monto) || monto <= 0) {
      return { valido: false, error: "Monto inválido" };
    }
    return { valido: true };
  },
  
  /**
   * Valida datos básicos de una transacción
   */
  validarDatosTransaccion: function(data) {
    if (!data.tipoTransaccion || !data.monto || !data.fecha) {
      return { valido: false, error: MESSAGES.DATOS_INVALIDOS };
    }
    return { valido: true };
  },
  
  /**
   * Valida que se especifique cuenta para gastos/pagos
   */
  validarCuentaParaGasto: function(tipoTransaccion, cuenta) {
    if ((tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
         tipoTransaccion === TIPOS_TRANSACCION.PAGOS) && !cuenta) {
      return { valido: false, error: "Debe especificar una cuenta" };
    }
    return { valido: true };
  },
  
  /**
   * Valida que se especifiquen cuentas para traspasos
   */
  validarCuentasParaTraspaso: function(tipoTransaccion, cuentaOrigen, cuentaDestino) {
    if (tipoTransaccion === TIPOS_TRANSACCION.TRASPASOS && 
        (!cuentaOrigen || !cuentaDestino)) {
      return { valido: false, error: "Debe especificar cuenta origen y destino" };
    }
    return { valido: true };
  },
  
  /**
   * Valida que exista el ID de transacción
   */
  validarIdTransaccion: function(idTransaccion) {
    if (!idTransaccion) {
      return { valido: false, error: "ID de transacción requerido" };
    }
    return { valido: true };
  },
  
  /**
   * Valida datos de una transacción simple
   */
  validarTransaccionSimple: function(data) {
    if (!data.categoria || !data.descripcion || !data.monto || 
        !data.fecha || !data.tipoTransaccion) {
      return { valido: false, error: MESSAGES.DATOS_INVALIDOS };
    }
    return { valido: true };
  }
};
