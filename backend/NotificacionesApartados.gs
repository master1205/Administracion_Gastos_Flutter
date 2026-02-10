// ============================================================================
// NOTIFICACIONES DE APARTADOS - Verificación diaria de pagos programados
// ============================================================================

/**
 * Verifica los apartados activos y envía notificaciones push:
 * - Recordatorio 1 día antes del pago
 * - Notificación el día del pago
 * - Alerta de pago atrasado (máximo 3 días consecutivos)
 * 
 * Debe ejecutarse diariamente con un trigger a las 8-9 AM
 */
function verificarPagosApartados() {
  try {
    Logger.info('🔔 Iniciando verificación de pagos de apartados...');

    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');

    if (!projectId || !email || !key) {
      Logger.error('verificarPagosApartados', 'Credenciales de Firebase no configuradas');
      return;
    }

    const firestore = FirestoreApp.getFirestore(email, key, projectId);

    // Obtener todos los apartados activos
    const apartados = firestore.getDocuments('apartados');
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);

    const manana = new Date(hoy);
    manana.setDate(manana.getDate() + 1);

    let notificacionesEnviadas = 0;

    apartados.forEach(doc => {
      try {
        const estado = obtenerValorCampo(doc.fields.estado);
        const notificacionesActivas = obtenerValorCampo(doc.fields.notificacionesActivas);
        
        // Solo procesar apartados activos con notificaciones habilitadas
        if (estado !== 'activo' || notificacionesActivas === false) {
          return;
        }

        const nombre = obtenerValorCampo(doc.fields.nombre) || 'Apartado';
        const fechasPago = obtenerFechasArray(doc.fields.fechasPago);
        const montoPorPago = calcularMontoPorPago(doc);

        if (fechasPago.length === 0) {
          return;
        }

        // Verificar cada fecha de pago
        for (let i = 0; i < fechasPago.length; i++) {
          const fechaPago = new Date(fechasPago[i]);
          fechaPago.setHours(0, 0, 0, 0);

          // ── Recordatorio: 1 día antes ──
          if (esMismoDia(fechaPago, manana)) {
            enviarNotificacionPush(
              '📅 Recordatorio de pago mañana',
              '"' + nombre + '" tiene un pago de $' + montoPorPago.toFixed(2) + ' programado para mañana',
              {
                screen: 'apartados',
                tipo: 'recordatorio_pago',
                apartadoId: doc.name.split('/').pop(),
                timestamp: new Date().toISOString()
              }
            );
            notificacionesEnviadas++;
            Logger.info('📅 Recordatorio enviado (mañana): ' + nombre);
          }

          // ── Notificación: día del pago ──
          if (esMismoDia(fechaPago, hoy)) {
            enviarNotificacionPush(
              '💰 Hoy toca pago',
              'Tienes un pago de $' + montoPorPago.toFixed(2) + ' en "' + nombre + '"',
              {
                screen: 'apartados',
                tipo: 'dia_pago',
                apartadoId: doc.name.split('/').pop(),
                timestamp: new Date().toISOString()
              }
            );
            notificacionesEnviadas++;
            Logger.info('💰 Notificación del día enviada: ' + nombre);

            // Actualizar fechaProximoPago a la siguiente fecha disponible
            actualizarProximoPago(firestore, doc, fechasPago, i);
          }

          // ── Pago atrasado (1-3 días después) ──
          const diasAtraso = calcularDiasAtraso(fechaPago, hoy);
          if (diasAtraso >= 1 && diasAtraso <= 3) {
            enviarNotificacionPush(
              '⚠️ Pago atrasado (' + diasAtraso + ' día' + (diasAtraso > 1 ? 's' : '') + ')',
              '"' + nombre + '" tenía un pago de $' + montoPorPago.toFixed(2) + ' hace ' + diasAtraso + ' día' + (diasAtraso > 1 ? 's' : ''),
              {
                screen: 'apartados',
                tipo: 'pago_atrasado',
                apartadoId: doc.name.split('/').pop(),
                diasAtraso: String(diasAtraso),
                timestamp: new Date().toISOString()
              }
            );
            notificacionesEnviadas++;
            Logger.info('⚠️ Alerta de atraso (' + diasAtraso + 'd) enviada: ' + nombre);
          }
        }

        // ── Alerta: vencimiento en 3 días o menos ──
        const fechaLimite = obtenerValorCampo(doc.fields.fechaLimite);
        if (fechaLimite) {
          const limite = new Date(fechaLimite);
          limite.setHours(0, 0, 0, 0);
          const diasParaVencimiento = Math.floor((limite.getTime() - hoy.getTime()) / (1000 * 60 * 60 * 24));

          if (diasParaVencimiento >= 0 && diasParaVencimiento <= 3) {
            const montoApartado = obtenerValorCampo(doc.fields.montoApartado) || 0;
            const montoTotal = obtenerValorCampo(doc.fields.montoTotal) || 0;
            const progreso = montoTotal > 0 ? Math.round((montoApartado / montoTotal) * 100) : 0;

            if (progreso < 100) {
              const textoVence = diasParaVencimiento === 0 ? '¡HOY!' : 'en ' + diasParaVencimiento + ' día' + (diasParaVencimiento > 1 ? 's' : '');
              enviarNotificacionPush(
                '⏰ Apartado por vencer ' + (diasParaVencimiento === 0 ? '¡HOY!' : '(' + diasParaVencimiento + 'd)'),
                '"' + nombre + '" vence ' + textoVence + '. Progreso: ' + progreso + '% ($' + montoApartado.toFixed(2) + ' de $' + montoTotal.toFixed(2) + ')',
                {
                  screen: 'apartados',
                  tipo: 'vencimiento_proximo',
                  apartadoId: doc.name.split('/').pop(),
                  timestamp: new Date().toISOString()
                }
              );
              notificacionesEnviadas++;
              Logger.info('⏰ Alerta vencimiento enviada (' + diasParaVencimiento + 'd): ' + nombre);
            }
          }
        }
      } catch (e) {
        Logger.error('verificarPagosApartados', 'Error procesando apartado: ' + e.message);
      }
    });

    Logger.info('✅ Verificación completada. Notificaciones enviadas: ' + notificacionesEnviadas);

  } catch (error) {
    Logger.error('verificarPagosApartados', error);
  }
}

// ── Funciones auxiliares ──

/**
 * Compara si dos fechas son el mismo día
 */
function esMismoDia(fecha1, fecha2) {
  return fecha1.getFullYear() === fecha2.getFullYear() &&
         fecha1.getMonth() === fecha2.getMonth() &&
         fecha1.getDate() === fecha2.getDate();
}

/**
 * Calcula los días de atraso entre la fecha de pago y hoy
 * Retorna 0 si no hay atraso
 */
function calcularDiasAtraso(fechaPago, hoy) {
  const diff = hoy.getTime() - fechaPago.getTime();
  const dias = Math.floor(diff / (1000 * 60 * 60 * 24));
  return dias > 0 ? dias : 0;
}

/**
 * Extrae un valor de un campo de Firestore (maneja stringValue, booleanValue, etc.)
 */
function obtenerValorCampo(field) {
  if (!field) return null;
  if (field.stringValue !== undefined) return field.stringValue;
  if (field.booleanValue !== undefined) return field.booleanValue;
  if (field.integerValue !== undefined) return parseInt(field.integerValue);
  if (field.doubleValue !== undefined) return parseFloat(field.doubleValue);
  if (field.timestampValue !== undefined) return new Date(field.timestampValue);
  return null;
}

/**
 * Extrae un array de fechas (timestamps) de un campo de Firestore
 */
function obtenerFechasArray(field) {
  if (!field || !field.arrayValue || !field.arrayValue.values) return [];
  
  return field.arrayValue.values
    .filter(v => v.timestampValue)
    .map(v => new Date(v.timestampValue));
}

/**
 * Calcula el monto por pago basado en los campos del documento
 */
function calcularMontoPorPago(doc) {
  const montoTotal = obtenerValorCampo(doc.fields.montoTotal) || 0;
  const montoApartado = obtenerValorCampo(doc.fields.montoApartado) || 0;
  const numeroPagos = obtenerValorCampo(doc.fields.numeroPagos) || 1;
  const pagosRealizados = obtenerValorCampo(doc.fields.pagosRealizados) || 0;

  const restante = montoTotal - montoApartado;
  const pagosFaltantes = numeroPagos - pagosRealizados;

  if (pagosFaltantes <= 0 || restante <= 0) return 0;
  return restante / pagosFaltantes;
}

/**
 * Actualiza el campo fechaProximoPago al siguiente pago disponible
 * después del pago actual (Point 7)
 */
function actualizarProximoPago(firestore, doc, fechasPago, indiceActual) {
  try {
    const apartadoId = doc.name.split('/').pop();
    
    // Buscar la siguiente fecha después de la actual
    let siguienteFecha = null;
    for (let i = indiceActual + 1; i < fechasPago.length; i++) {
      siguienteFecha = fechasPago[i];
      break;
    }

    const updateData = {};
    if (siguienteFecha) {
      updateData['fechaProximoPago'] = siguienteFecha.toISOString();
    } else {
      // No hay más pagos programados
      updateData['fechaProximoPago'] = null;
    }

    firestore.updateDocument('apartados/' + apartadoId, updateData, true);
    Logger.info('📆 fechaProximoPago actualizado para: ' + (obtenerValorCampo(doc.fields.nombre) || apartadoId));

  } catch (e) {
    Logger.error('actualizarProximoPago', 'Error: ' + e.message);
  }
}

// ============================================================================
// CONFIGURACIÓN DEL TRIGGER
// ============================================================================

/**
 * Crea un trigger diario para verificar pagos de apartados
 * Ejecutar esta función UNA SOLA VEZ manualmente
 */
function crearTriggerNotificacionesApartados() {
  // Eliminar triggers anteriores de esta función
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(trigger => {
    if (trigger.getHandlerFunction() === 'verificarPagosApartados') {
      ScriptApp.deleteTrigger(trigger);
      Logger.info('🗑️ Trigger anterior eliminado');
    }
  });

  // Crear nuevo trigger diario a las 8:00 AM
  ScriptApp.newTrigger('verificarPagosApartados')
    .timeBased()
    .everyDays(1)
    .atHour(8)
    .create();

  Logger.info('✅ Trigger diario creado: verificarPagosApartados se ejecutará todos los días a las 8:00 AM');
}

/**
 * Función de prueba para verificar el funcionamiento sin esperar al trigger
 */
function probarNotificacionesApartados() {
  Logger.info('🧪 Ejecutando prueba de notificaciones de apartados...');
  verificarPagosApartados();
}

// ============================================================================
// RESUMEN SEMANAL DE APARTADOS
// ============================================================================
/**
 * Envía un resumen semanal de apartados activos los lunes.
 * Incluye pagos programados para la semana entrante y montos pendientes.
 */
function enviarResumenSemanalApartados() {
  try {
    Logger.info('📊 Iniciando resumen semanal de apartados...');

    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');

    if (!projectId || !email || !key) {
      Logger.error('enviarResumenSemanalApartados', 'Credenciales de Firebase no configuradas');
      return;
    }

    const firestore = FirestoreApp.getFirestore(email, key, projectId);
    const apartados = firestore.getDocuments('apartados');

    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);

    // Fin de semana (próximo domingo)
    const finSemana = new Date(hoy);
    finSemana.setDate(finSemana.getDate() + 7);

    let apartadosActivos = 0;
    let pagosEstaSemana = 0;
    let montoTotalSemana = 0;
    let detallesPagos = [];

    apartados.forEach(doc => {
      try {
        const estado = obtenerValorCampo(doc.fields.estado);
        if (estado !== 'activo') return;

        apartadosActivos++;

        const nombre = obtenerValorCampo(doc.fields.nombre) || 'Apartado';
        const fechasPago = obtenerFechasArray(doc.fields.fechasPago);
        const montoPorPago = calcularMontoPorPago(doc);

        fechasPago.forEach(fecha => {
          const fechaPago = new Date(fecha);
          fechaPago.setHours(0, 0, 0, 0);

          if (fechaPago >= hoy && fechaPago < finSemana) {
            pagosEstaSemana++;
            montoTotalSemana += montoPorPago;
            const dia = fechaPago.toLocaleDateString('es-MX', { weekday: 'short', day: 'numeric', month: 'short' });
            detallesPagos.push('• "' + nombre + '" - $' + montoPorPago.toFixed(2) + ' (' + dia + ')');
          }
        });
      } catch (e) {
        Logger.error('enviarResumenSemanalApartados', 'Error procesando: ' + e.message);
      }
    });

    if (apartadosActivos === 0 || pagosEstaSemana === 0) {
      Logger.info('📊 No hay apartados activos o pagos esta semana, no se envía resumen');
      return;
    }

    let cuerpo = 'Tienes ' + apartadosActivos + ' apartado' + (apartadosActivos > 1 ? 's' : '') + ' activo' + (apartadosActivos > 1 ? 's' : '') + '. ';
    cuerpo += pagosEstaSemana + ' pago' + (pagosEstaSemana > 1 ? 's' : '') + ' esta semana por $' + montoTotalSemana.toFixed(2) + ':\n' + detallesPagos.join('\n');

    enviarNotificacionPush(
      '📊 Resumen semanal de apartados',
      cuerpo,
      {
        screen: 'apartados',
        tipo: 'resumen_semanal',
        timestamp: new Date().toISOString()
      }
    );

    Logger.info('✅ Resumen semanal enviado');

  } catch (error) {
    Logger.error('enviarResumenSemanalApartados', error);
  }
}
// ============================================================================
// ENDPOINT PARA PUSH DESDE FLUTTER (Web App)
// ============================================================================

/**
 * Recibe solicitudes POST desde Flutter para enviar notificaciones push.
 * Parámetros JSON: { titulo, mensaje, data }
 * 
 * Desplegar como Web App con acceso "Anyone" y ejecutar como "Me"
 */
function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    const titulo = body.titulo || 'Notificación';
    const mensaje = body.mensaje || '';
    const data = body.data || {};

    enviarNotificacionPush(titulo, mensaje, data);

    return ContentService
      .createTextOutput(JSON.stringify({ exito: true }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    Logger.error('doPost', error);
    return ContentService
      .createTextOutput(JSON.stringify({ exito: false, error: error.message }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
