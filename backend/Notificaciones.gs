/**
 * Obtener todas las notificaciones personalizadas
 */
function getNotificaciones() {
  try {
    const sheet = SheetManager.getNotificaciones();
    const data = sheet.getDataRange().getValues();
    
    if (data.length <= 1) {
      return ResponseBuilder.success([]);
    }
    
    const notificaciones = [];
    for (let i = 1; i < data.length; i++) {
      // Validar que la fila no esté vacía
      if (data[i][0]) {
        notificaciones.push({
          id: data[i][0],
          titulo: data[i][1],
          mensaje: data[i][2],
          hora: data[i][3],
          diasSemana: String(data[i][4]).split(',').map(d => parseInt(d)),
          icono: data[i][5] || 'notifications',
          color: data[i][6] || 'FF4CAF50',
          activa: data[i][7] === true || data[i][7] === 'true',
          fechaCreacion: data[i][8] || '',
          dispositivo: data[i][9] || ''
        });
      }
    }
    
    return ResponseBuilder.success(notificaciones);
    
  } catch (error) {
    return ResponseBuilder.error('Error al obtener notificaciones: ' + error.message);
  }
}

/**
 * Guardar o actualizar notificación personalizada
 */
function saveNotificacion(params) {
  try {
    const sheet = SheetManager.getNotificaciones();
    const data = sheet.getDataRange().getValues();
    
    // Convertir id a número para comparación
    const id = params.parameter.id ? parseFloat(params.parameter.id) : Date.now();
    const titulo = params.parameter.titulo;
    const mensaje = params.parameter.mensaje;
    const hora = params.parameter.hora;
    const diasSemana = params.parameter.diasSemana; // "1,3,5"
    const icono = params.parameter.icono || 'notifications';
    const color = params.parameter.color || 'FF4CAF50';
    const activa = params.parameter.activa === 'true';
    const dispositivo = params.parameter.dispositivo || '';
    
    // Validar campos requeridos
    if (!titulo || !mensaje || !hora) {
      return ResponseBuilder.error('Faltan campos requeridos');
    }
    
    // Buscar si existe
    let filaExistente = -1;
    for (let i = 1; i < data.length; i++) {
      if (parseFloat(data[i][0]) === id) {  // Comparar números
        filaExistente = i + 1;
        break;
      }
    }
    
    const ahora = new Date().toISOString();
    
    if (filaExistente > 0) {
      // Actualizar
      sheet.getRange(filaExistente, 1, 1, 10).setValues([[
        id, titulo, mensaje, hora, diasSemana, icono, color, activa, ahora, dispositivo
      ]]);
      
      Logger.info('saveNotificacion', 'Notificación actualizada', { id, titulo });
      return ResponseBuilder.success({
        id: id,
        message: 'Notificación actualizada correctamente'
      });
    } else {
      // Crear nueva
      sheet.appendRow([
        id, titulo, mensaje, hora, diasSemana, icono, color, activa, ahora, dispositivo
      ]);
      
      Logger.info('saveNotificacion', 'Notificación creada', { id, titulo });
      return ResponseBuilder.success({
        id: id,
        message: 'Notificación creada correctamente'
      });
    }
    
  } catch (error) {
    Logger.error('saveNotificacion', error);
    return ResponseBuilder.error('Error al guardar notificación: ' + error.message);
  }
}

/**
 * Eliminar notificación personalizada
 */
function deleteNotificacion(params) {
  try {
    const sheet = SheetManager.getNotificaciones();
    const data = sheet.getDataRange().getValues();
    const id = params.parameter.id;
    
    if (!id) {
      return ResponseBuilder.error('ID de notificación es requerido');
    }
    
    // Convertir id a número para comparación
    const idNum = parseFloat(id);
    Logger.info('deleteNotificacion', 'Buscando notificación', { id: idNum, tipo: typeof idNum });
    
    for (let i = 1; i < data.length; i++) {
      const idFila = parseFloat(data[i][0]);
      if (idFila === idNum) {
        sheet.deleteRow(i + 1);
        Logger.info('deleteNotificacion', 'Notificación eliminada', { id: idNum });
        return ResponseBuilder.success({ message: 'Notificación eliminada correctamente' });
      }
    }
    
    return ResponseBuilder.error('Notificación no encontrada');
    
  } catch (error) {
    Logger.error('deleteNotificacion', error);
    return ResponseBuilder.error('Error al eliminar notificación: ' + error.message);
  }
}

/**
 * Actualizar estado activo/inactivo
 */
function toggleNotificacion(params) {
  try {
    const sheet = SheetManager.getNotificaciones();
    const data = sheet.getDataRange().getValues();
    const id = params.parameter.id;
    const activa = params.parameter.activa === 'true';
    
    if (!id) {
      return ResponseBuilder.error('ID de notificación es requerido');
    }
    
    // Convertir id a número para comparación
    const idNum = parseFloat(id);
    
    for (let i = 1; i < data.length; i++) {
      const idFila = parseFloat(data[i][0]);
      if (idFila === idNum) {
        sheet.getRange(i + 1, 8).setValue(activa); // Columna H (activa)
        Logger.info('toggleNotificacion', 'Estado actualizado', { id: idNum, activa });
        return ResponseBuilder.success({ message: 'Estado actualizado correctamente' });
      }
    }
    
    return ResponseBuilder.error('Notificación no encontrada');
    
  } catch (error) {
    Logger.error('toggleNotificacion', error);
    return ResponseBuilder.error('Error al actualizar estado: ' + error.message);
  }
}
