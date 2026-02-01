// ============================================================================
// CORTE MENSUAL AUTOMÁTICO - Ejecutado por Trigger de Apps Script
// ============================================================================

/**
 * Ejecuta el corte mensual automáticamente
 * Esta función debe ser programada como trigger para ejecutarse el 1º de cada mes
 */
function ejecutarCorteMensualAutomatico() {
  try {
    Logger.info('🔄 Iniciando corte mensual automático...');
    
    // Calcular fechas del mes anterior
    const ahora = new Date();
    const inicioMesAnterior = calcularInicioMesAnterior(ahora);
    const finMesAnterior = calcularFinMesAnterior(ahora);
    
    Logger.info('📅 Periodo: ' + formatearFecha(inicioMesAnterior) + ' al ' + formatearFecha(finMesAnterior));
    
    // Obtener transacciones desde Firebase
    const transacciones = obtenerTransaccionesDesdeFirebase(inicioMesAnterior, finMesAnterior);
    
    if (transacciones.length === 0) {
      Logger.info('ℹ️ No hay transacciones del mes anterior. Corte omitido.');
      return;
    }
    
    Logger.info('📊 Transacciones obtenidas: ' + transacciones.length);
    
    // Calcular totales
    const resumen = calcularResumen(transacciones);
    Logger.info('💰 Resumen: Ingresos: $' + resumen.totalIngresos.toFixed(2) + 
               ', Gastos: $' + resumen.totalGastos.toFixed(2) + 
               ', Saldo: $' + resumen.saldoTotal.toFixed(2));
    
    // Generar reporte PDF
    const resultadoReporte = GeneradorReportes.corteMensual(resumen, transacciones);
    
    if (!resultadoReporte.exito) {
      Logger.error('ejecutarCorteMensualAutomatico', 'Error al generar reporte: ' + resultadoReporte.error);
      return;
    }
    
    Logger.info('✅ Reporte generado: ' + resultadoReporte.archivo);
    
    // ✅ Guardar reporte en Firebase (colección 'reportes')
    guardarReporteEnFirebase(inicioMesAnterior, finMesAnterior, resultadoReporte.archivo);
    Logger.info('💾 Reporte guardado en Firebase colección reportes');
    
    // Eliminar transacciones de Firebase
    const eliminadas = eliminarTransaccionesDeFirebase(transacciones);
    Logger.info('🗑️ Transacciones eliminadas de Firebase: ' + eliminadas);
    
    // Enviar notificación push a todos los dispositivos
    const notificacionResultado = notificarCorteMensualCompletado(
      resumen,
      transacciones.length,
      resultadoReporte.archivo
    );
    
    if (notificacionResultado.exito) {
      Logger.info('📨 Notificaciones enviadas a ' + notificacionResultado.enviados + ' dispositivos');
    } else {
      Logger.error('ejecutarCorteMensualAutomatico', 'Error al enviar notificaciones: ' + notificacionResultado.error);
    }
    
    Logger.info('✅ Corte mensual automático completado exitosamente');
    
  } catch (error) {
    Logger.error('ejecutarCorteMensualAutomatico', error);
    // Enviar email de error al administrador (opcional)
    enviarEmailError('Corte Mensual Automático', error.message);
  }
}

/**
 * Obtiene todas las transacciones del mes anterior desde Firebase
 */
function obtenerTransaccionesDesdeFirebase(inicioMes, finMes) {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');
    
    if (!projectId || !email || !key) {
      throw new Error('Credenciales de Firebase no configuradas');
    }
    
    // Crear cliente de Firestore
    const firestore = FirestoreApp.getFirestore(email, key, projectId);
    
    // Convertir fechas a timestamps de Firestore
    const inicioTimestamp = inicioMes.toISOString();
    const finTimestamp = finMes.toISOString();
    
    Logger.info('🔍 Buscando transacciones en Firebase...');
    
    // Obtener TODAS las transacciones del mes
    const allDocs = firestore.getDocuments('transacciones');
    const transacciones = [];
    
    allDocs.forEach(doc => {
      const data = doc.fields;
      
      // Validar que tenga usuarioId = default_user
      if (!data.usuarioId || data.usuarioId.stringValue !== 'default_user') {
        return;
      }
      
      // Extraer fecha
      let fechaDoc;
      if (data.fecha && data.fecha.timestampValue) {
        fechaDoc = new Date(data.fecha.timestampValue);
      }
      if (!fechaDoc) return;
      
      // Filtrar por rango de fechas
      if (fechaDoc >= inicioMes && fechaDoc <= finMes) {
        transacciones.push({
          id: doc.name.split('/').pop(),
          tipo: data.tipo ? data.tipo.stringValue : '',
          categoria: data.categoria ? data.categoria.stringValue : '',
          monto: data.monto ? (data.monto.doubleValue || data.monto.integerValue || 0) : 0,
          descripcion: data.descripcion ? data.descripcion.stringValue : '',
          fecha: fechaDoc.toISOString(),
          cuenta: data.cuentaNombre ? data.cuentaNombre.stringValue : (data.cuenta ? data.cuenta.stringValue : ''),
          cuentaNombre: data.cuentaNombre ? data.cuentaNombre.stringValue : '',
          idTransaccion: data.idTransaccion ? data.idTransaccion.stringValue : ''
        });
      }
    });
    
    return transacciones;
    
  } catch (error) {
    Logger.error('obtenerTransaccionesDesdeFirebase', error);
    throw error;
  }
}

/**
 * Calcula resumen financiero de las transacciones
 */
function calcularResumen(transacciones) {
  let totalIngresos = 0;
  let totalGastos = 0;
  
  transacciones.forEach(t => {
    // Convertir monto a número para evitar concatenación de strings
    const monto = parseFloat(t.monto) || 0;
    
    if (t.tipo === 'Ingresos') {
      totalIngresos += monto;
    } else if (t.tipo === 'Gastos' || t.tipo === 'Pagos') {
      totalGastos += monto;
    }
  });
  
  // Obtener saldo total actual de las cuentas
  const saldoTotal = obtenerSaldoTotalCuentas();
  
  return {
    totalIngresos: Number(totalIngresos) || 0,
    totalGastos: Number(totalGastos) || 0,
    saldoTotal: Number(saldoTotal) || 0
  };
}

/**
 * Obtiene el saldo total de todas las cuentas activas
 */
function obtenerSaldoTotalCuentas() {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');
    
    const firestore = FirestoreApp.getFirestore(email, key, projectId);
    const cuentasDocs = firestore.getDocuments('cuentas');
    
    let saldoTotal = 0;
    
    cuentasDocs.forEach(doc => {
      const data = doc.fields;
      
      // Solo cuentas activas de default_user
      if (data.usuarioId && data.usuarioId.stringValue === 'default_user' &&
          data.activa && data.activa.booleanValue === true) {
        const saldo = data.saldo ? (data.saldo.doubleValue || data.saldo.integerValue || 0) : 0;
        saldoTotal += parseFloat(saldo) || 0;
      }
    });
    
    return Number(saldoTotal) || 0;
    
  } catch (error) {
    Logger.error('obtenerSaldoTotalCuentas', error);
    return 0;
  }
}

/**
 * Elimina las transacciones del mes anterior de Firebase
 */
function eliminarTransaccionesDeFirebase(transacciones) {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');
    
    const firestore = FirestoreApp.getFirestore(email, key, projectId);
    
    let eliminadas = 0;
    
    transacciones.forEach(t => {
      try {
        firestore.deleteDocument('transacciones/' + t.id);
        eliminadas++;
      } catch (deleteError) {
        Logger.error('eliminarTransaccionesDeFirebase', 'Error al eliminar ' + t.id + ': ' + deleteError.message);
      }
    });
    
    return eliminadas;
    
  } catch (error) {
    Logger.error('eliminarTransaccionesDeFirebase', error);
    return 0;
  }
}

/**
 * Guarda el reporte mensual en Firebase (colección 'reportes')
 */
function guardarReporteEnFirebase(inicioMes, finMes, urlReporte) {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');
    
    const firestore = FirestoreApp.getFirestore(email, key, projectId);
    
    const mes = obtenerNombreMes(inicioMes.getMonth() + 1);
    const anio = inicioMes.getFullYear();
    
    // ✅ Usar formato simple - FirestoreApp hace la conversión automáticamente
    const reporteData = {
      nombre: 'Reporte_Mensual.pdf',
      año: anio,
      mes: mes,
      urlReporte: urlReporte,
      usuarioId: 'default_user',
      fechaCreacion: new Date()
    };
    
    firestore.createDocument('reportes', reporteData);
    Logger.info('✅ Reporte guardado en Firebase: ' + mes + ' ' + anio);
    
  } catch (error) {
    Logger.error('guardarReporteEnFirebase', error);
  }
}

/**
 * Obtiene el nombre del mes en español
 */
function obtenerNombreMes(mes) {
  const meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  return meses[mes - 1];
}

/**
 * Calcula el inicio del mes anterior (día 1 a las 00:00:00)
 */
function calcularInicioMesAnterior(fecha) {
  const mesAnterior = new Date(fecha);
  
  if (mesAnterior.getMonth() === 0) {
    // Si estamos en enero, ir a diciembre del año anterior
    mesAnterior.setFullYear(mesAnterior.getFullYear() - 1);
    mesAnterior.setMonth(11);
  } else {
    mesAnterior.setMonth(mesAnterior.getMonth() - 1);
  }
  
  mesAnterior.setDate(1);
  mesAnterior.setHours(0, 0, 0, 0);
  
  return mesAnterior;
}

/**
 * Calcula el fin del mes anterior (último día a las 23:59:59)
 */
function calcularFinMesAnterior(fecha) {
  const inicioMesActual = new Date(fecha);
  inicioMesActual.setDate(1);
  inicioMesActual.setHours(0, 0, 0, 0);
  
  // Restar 1 milisegundo para obtener el último momento del mes anterior
  const finMesAnterior = new Date(inicioMesActual.getTime() - 1);
  
  return finMesAnterior;
}

/**
 * Formatea una fecha para mostrar
 */
function formatearFecha(fecha) {
  const dia = fecha.getDate().toString().padStart(2, '0');
  const mes = (fecha.getMonth() + 1).toString().padStart(2, '0');
  const anio = fecha.getFullYear();
  return dia + '/' + mes + '/' + anio;
}

/**
 * Envía email de error al administrador (opcional)
 */
function enviarEmailError(proceso, error) {
  try {
    const email = Session.getActiveUser().getEmail();
    if (email) {
      MailApp.sendEmail({
        to: email,
        subject: '❌ Error en ' + proceso,
        body: 'Se produjo un error:\n\n' + error + '\n\nFecha: ' + new Date().toLocaleString()
      });
    }
  } catch (mailError) {
    Logger.error('enviarEmailError', mailError);
  }
}

// ============================================================================
// CONFIGURACIÓN DE TRIGGER AUTOMÁTICO
// ============================================================================

/**
 * Crea el trigger para ejecutar el corte mensual automáticamente
 * Ejecutar esta función UNA SOLA VEZ manualmente
 */
function configurarTriggerCorteMensual() {
  // Eliminar triggers existentes con el mismo nombre
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(trigger => {
    if (trigger.getHandlerFunction() === 'ejecutarCorteMensualAutomatico') {
      ScriptApp.deleteTrigger(trigger);
    }
  });
  
  // Crear nuevo trigger: día 1 de cada mes a la 1:00 AM
  ScriptApp.newTrigger('ejecutarCorteMensualAutomatico')
    .timeBased()
    .onMonthDay(1)
    .atHour(1)
    .create();
  
  Logger.info('✅ Trigger configurado: Se ejecutará el día 1 de cada mes a la 1:00 AM');
}

/**
 * Elimina el trigger de corte mensual
 */
function eliminarTriggerCorteMensual() {
  const triggers = ScriptApp.getProjectTriggers();
  let eliminados = 0;
  
  triggers.forEach(trigger => {
    if (trigger.getHandlerFunction() === 'ejecutarCorteMensualAutomatico') {
      ScriptApp.deleteTrigger(trigger);
      eliminados++;
    }
  });
  
  Logger.info('🗑️ Triggers eliminados: ' + eliminados);
}

/**
 * Función de prueba - Ejecutar manualmente para probar el corte
 */
function probarCorteMensual() {
  Logger.info('🧪 Ejecutando prueba de corte mensual...');
  ejecutarCorteMensualAutomatico();
}

