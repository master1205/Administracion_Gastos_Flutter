// ============================================================================
// CORTE SEMANAL AUTOMÁTICO - Ejecutado por Trigger de Apps Script
// ============================================================================

/**
 * Ejecuta el corte semanal automáticamente
 * Esta función debe ser programada como trigger para ejecutarse cada domingo
 */
function ejecutarCorteSemanalAutomatico() {
  try {
    Logger.info('🔄 Iniciando corte semanal automático...');
    
    // Calcular fechas de la semana pasada (domingo a sábado)
    const ahora = new Date();
    const inicioSemana = calcularInicioSemanaPasada(ahora);
    const finSemana = calcularFinSemanaPasada(inicioSemana);
    
    Logger.info('📅 Periodo: ' + formatearFecha(inicioSemana) + ' al ' + formatearFecha(finSemana));
    
    // Obtener transacciones de Alimentación desde Firebase
    const transacciones = obtenerTransaccionesAlimentacionDesdeFirebase(inicioSemana, finSemana);
    
    if (transacciones.length === 0) {
      Logger.info('ℹ️ No hay transacciones de Alimentación esta semana. Corte omitido.');
      return;
    }
    
    Logger.info('📊 Transacciones de Alimentación obtenidas: ' + transacciones.length);
    
    // Calcular total semanal
    let totalSemanal = 0;
    transacciones.forEach(t => {
      totalSemanal += t.monto;
    });
    
    Logger.info('💰 Total semanal en Alimentación: $' + totalSemanal.toFixed(2));
    
    // Eliminar transacciones de Alimentación de Firebase
    const eliminadas = eliminarTransaccionesDeFirebase(transacciones);
    Logger.info('🗑️ Transacciones eliminadas de Firebase: ' + eliminadas);
    
    // Crear transacción resumen "Corte Semanal"
    crearTransaccionResumenSemanal(totalSemanal);
    Logger.info('✅ Transacción resumen "Corte Semanal" creada en Firebase');
    
    // Renovar fechas de presupuestos semanales
    const presupuestosRenovados = renovarPresupuestosSemanales();
    if (presupuestosRenovados > 0) {
      Logger.info('📆 Presupuestos semanales renovados: ' + presupuestosRenovados);
    }

    // Enviar notificación push a todos los dispositivos
    const notificacionResultado = notificarCorteSemanalCompletado(totalSemanal, transacciones.length);
    
    if (notificacionResultado.exito) {
      Logger.info('📨 Notificaciones enviadas a ' + notificacionResultado.enviados + ' dispositivos');
    } else {
      Logger.error('ejecutarCorteSemanalAutomatico', 'Error al enviar notificaciones: ' + notificacionResultado.error);
    }
    
    Logger.info('✅ Corte semanal automático completado exitosamente');
    
  } catch (error) {
    Logger.error('ejecutarCorteSemanalAutomatico', error);
    enviarEmailError('Corte Semanal Automático', error.message);
  }
}

/**
 * Obtiene transacciones de categoría "Alimentación" y tipo "Gastos" de la semana
 */
function obtenerTransaccionesAlimentacionDesdeFirebase(inicioSemana, finSemana) {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');
    
    if (!projectId || !email || !key) {
      throw new Error('Credenciales de Firebase no configuradas');
    }
    
    const firestore = FirestoreApp.getFirestore(email, key, projectId);
    
    Logger.info('🔍 Buscando transacciones de Alimentación en Firebase...');
    
    // Obtener todas las transacciones y filtrar
    const allDocs = firestore.getDocuments('transacciones');
    const transacciones = [];
    
    allDocs.forEach(doc => {
      const data = doc.fields;
      
      // Validar usuarioId
      if (!data.usuarioId || data.usuarioId.stringValue !== 'default_user') {
        return;
      }
      
      // Validar tipo = Gastos
      if (!data.tipo || data.tipo.stringValue !== 'Gastos') {
        return;
      }
      
      // Validar categoría = Alimentación
      if (!data.categoria || data.categoria.stringValue !== 'Alimentación') {
        return;
      }
      
      // Extraer fecha
      let fechaDoc;
      if (data.fecha && data.fecha.timestampValue) {
        fechaDoc = new Date(data.fecha.timestampValue);
      }
      if (!fechaDoc) return;
      
      // Filtrar por rango de fechas
      if (fechaDoc >= inicioSemana && fechaDoc <= finSemana) {
        transacciones.push({
          id: doc.name.split('/').pop(),
          tipo: data.tipo.stringValue,
          categoria: data.categoria.stringValue,
          monto: data.monto ? (data.monto.doubleValue || data.monto.integerValue || 0) : 0,
          descripcion: data.descripcion ? data.descripcion.stringValue : '',
          fecha: fechaDoc.toISOString()
        });
      }
    });
    
    return transacciones;
    
  } catch (error) {
    Logger.error('obtenerTransaccionesAlimentacionDesdeFirebase', error);
    throw error;
  }
}

/**
 * Elimina transacciones de Firebase
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
 * Crea transacción resumen "Corte Semanal" en Firebase
 */
function crearTransaccionResumenSemanal(totalSemanal) {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');
    
    const firestore = FirestoreApp.getFirestore(email, key, projectId);
    
    const idTransaccion = 'corte_semanal_' + Date.now();
    
    const transaccionData = {
      usuarioId: 'default_user',
      tipo: 'Gastos',
      categoria: 'Semanal',
      monto: totalSemanal,
      descripcion: 'Corte Semanal',
      fecha: new Date(),
      cuenta: '',
      cuentaNombre: '',
      cuentaOrigen: '',
      cuentaOrigenNombre: '',
      cuentaDestino: '',
      cuentaDestinoNombre: '',
      idTransaccion: idTransaccion
    };
    
    firestore.createDocument('transacciones', transaccionData);
    Logger.info('✅ Transacción resumen creada: Corte Semanal - $' + totalSemanal.toFixed(2));
    
  } catch (error) {
    Logger.error('crearTransaccionResumenSemanal', error);
    throw error;
  }
}

/**
 * Busca presupuestos semanales recurrentes en Firebase y actualiza sus fechas al nuevo periodo
 * Solo renueva los que tengan esRecurrente: true
 * Guarda historial del periodo anterior antes de resetear
 * Envía notificación push por cada presupuesto renovado
 */
function renovarPresupuestosSemanales() {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');

    const firestore = FirestoreApp.getFirestore(email, key, projectId);

    // Obtener todos los presupuestos
    const allDocs = firestore.getDocuments('presupuestos');
    let renovados = 0;
    const presupuestosRenovados = [];

    allDocs.forEach(doc => {
      const data = doc.fields;

      // Solo presupuestos semanales de default_user
      if (!data.usuarioId || data.usuarioId.stringValue !== 'default_user') return;
      if (!data.periodo || data.periodo.stringValue !== 'semanal') return;

      // Solo renovar presupuestos recurrentes
      if (!data.esRecurrente || data.esRecurrente.booleanValue !== true) return;

      const docId = doc.name.split('/').pop();
      const nombre = data.nombre ? data.nombre.stringValue : 'Sin nombre';
      const montoLimite = data.montoLimite ? (data.montoLimite.doubleValue || data.montoLimite.integerValue || 0) : 0;
      const montoGastado = data.montoGastado ? (data.montoGastado.doubleValue || data.montoGastado.integerValue || 0) : 0;

      // Extraer fechas del periodo anterior
      let fechaInicioAnterior = null;
      let fechaFinAnterior = null;
      if (data.fechaInicio && data.fechaInicio.timestampValue) {
        fechaInicioAnterior = new Date(data.fechaInicio.timestampValue);
      }
      if (data.fechaFin && data.fechaFin.timestampValue) {
        fechaFinAnterior = new Date(data.fechaFin.timestampValue);
      }

      // ✅ Guardar historial del periodo anterior antes de resetear
      const historialData = {
        montoLimite: montoLimite,
        montoGastado: montoGastado,
        porcentaje: montoLimite > 0 ? Math.round((montoGastado / montoLimite) * 100) : 0,
        fechaInicio: fechaInicioAnterior || new Date(),
        fechaFin: fechaFinAnterior || new Date(),
        periodo: 'semanal',
        fechaCorte: new Date()
      };

      firestore.createDocument('presupuestos/' + docId + '/historial', historialData);
      Logger.info('📋 Historial guardado para: ' + nombre + ' (' + historialData.porcentaje + '% usado)');

      // Calcular nuevas fechas: desde hoy (domingo) hasta el sábado
      const ahora = new Date();
      const nuevoInicio = new Date(ahora);
      nuevoInicio.setHours(0, 0, 0, 0);

      const nuevoFin = new Date(nuevoInicio);
      nuevoFin.setDate(nuevoInicio.getDate() + 6);
      nuevoFin.setHours(23, 59, 59, 999);

      // Actualizar el documento
      const updateData = {
        fechaInicio: nuevoInicio,
        fechaFin: nuevoFin,
        montoGastado: 0,
        updatedAt: new Date()
      };

      firestore.updateDocument('presupuestos/' + docId, updateData);
      renovados++;

      presupuestosRenovados.push({
        nombre: nombre,
        montoLimite: montoLimite,
        fechaInicio: nuevoInicio,
        fechaFin: nuevoFin
      });

      Logger.info('📆 Presupuesto semanal renovado: ' + nombre +
        ' → ' + formatearFecha(nuevoInicio) + ' al ' + formatearFecha(nuevoFin));
    });

    // ✅ Enviar notificación push si se renovaron presupuestos
    if (presupuestosRenovados.length > 0) {
      notificarPresupuestosRenovados(presupuestosRenovados, 'semanal');
    }

    return renovados;

  } catch (error) {
    Logger.error('renovarPresupuestosSemanales', error);
    return 0;
  }
}

/**
 * Calcula el inicio de la semana pasada (domingo a las 00:00:00)
 */
function calcularInicioSemanaPasada(fecha) {
  const diasDesdeUltimoDomingo = fecha.getDay() === 0 ? 7 : fecha.getDay();
  const domingoAnterior = new Date(fecha);
  domingoAnterior.setDate(fecha.getDate() - diasDesdeUltimoDomingo);
  domingoAnterior.setHours(0, 0, 0, 0);
  
  return domingoAnterior;
}

/**
 * Calcula el fin de la semana pasada (sábado a las 23:59:59)
 */
function calcularFinSemanaPasada(inicioSemana) {
  const sabado = new Date(inicioSemana);
  sabado.setDate(inicioSemana.getDate() + 6);
  sabado.setHours(23, 59, 59, 999);
  
  return sabado;
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
 * Envía email de error al administrador
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

/**
 * Función de prueba - Ejecutar manualmente para probar el corte semanal
 */
function probarCorteSemanal() {
  Logger.info('🧪 Ejecutando prueba de corte semanal...');
  ejecutarCorteSemanalAutomatico();
}

