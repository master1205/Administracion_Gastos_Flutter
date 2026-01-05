// ============================================================================
// MÓDULO DE GENERACIÓN DE REPORTES
// ============================================================================

/**
 * Lista todos los reportes disponibles
 */
function listReportes() {
  try {
    const folder = DriveApp.getFolderById(CONFIG.FOLDER_REPORTES_ID);
    const files = folder.getFiles();
    const reportes = [];

    while (files.hasNext()) {
      const file = files.next();
      reportes.push({
        name: file.getName(),
        file: file.getUrl(),
        fechaCorte: file.getDescription() || ''
      });
    }

    Logger.info('listReportes', 'Reportes encontrados', { count: reportes.length });
    return ResponseBuilder.success({ items: reportes });
    
  } catch (error) {
    Logger.error('listReportes', error);
    return ResponseBuilder.error(MESSAGES.ERROR_GENERAL + ": " + error.message);
  }
}

/**
 * Gestor de generación de reportes
 */
const GeneradorReportes = {
  /**
   * Genera el reporte mensual completo
   */
  corteMensual: function() {
    try {
      Logger.info('GeneradorReportes', 'Iniciando corte mensual');
      
      const fechaCorte = FormatoUtil.mesAnterior();
      
      // Crear documento desde plantilla
      const documento = this._crearDocumentoDesdePlantilla(fechaCorte);
      
      // Obtener datos y analizar
      const data = SheetManager.getNuevasTransacciones().getDataRange().getValues();
      const analisis = AnalizadorTransacciones.analizar(data);
      
      // Llenar documento
      this._llenarDatosBasicos(documento.body, fechaCorte);
      this._agregarTop3Gastos(documento.body, analisis);
      this._agregarDistribucionCategorias(documento.body, analisis);
      this._agregarEstadisticas(documento.body, analisis);
      this._agregarTablaTransacciones(documento.body, data);
      
      // Guardar y convertir a PDF
      const pdfFile = this._convertirAPDF(documento, fechaCorte);
      
      // Limpiar transacciones
      this._limpiarTransacciones();
      
      // Enviar notificación
      EmailSender.enviarReporteMensual(fechaCorte, analisis);
      
      Logger.info('GeneradorReportes', 'Corte mensual completado', {
        fecha: fechaCorte,
        transacciones: analisis.totalTransacciones
      });
      
      return { exito: true, archivo: pdfFile.getUrl() };
      
    } catch (error) {
      Logger.error('GeneradorReportes.corteMensual', error);
      return { exito: false, error: error.message };
    }
  },

  /**
   * Crea documento desde plantilla
   */
  _crearDocumentoDesdePlantilla: function(fechaCorte) {
    const plantilla = DriveApp.getFileById(CONFIG.PLANTILLA_REPORTE_ID);
    const carpetaDestino = DriveApp.getFolderById(CONFIG.FOLDER_REPORTES_ID);
    const copiaPlantilla = plantilla.makeCopy("Reporte_Temporal", carpetaDestino);
    
    const docCopia = DocumentApp.openById(copiaPlantilla.getId());
    
    return {
      doc: docCopia,
      body: docCopia.getBody(),
      copiaId: copiaPlantilla.getId()
    };
  },

  /**
   * Llena los datos básicos del reporte
   */
  _llenarDatosBasicos: function(body, fechaCorte) {
    const sheet = SheetManager.getCuentas();
    
    body.replaceText("{{saldoCorte}}", FormatoUtil.currency(sheet.getRange(2, 3).getValue()));
    body.replaceText("{{gastos}}", FormatoUtil.currency(sheet.getRange(2, 2).getValue()));
    body.replaceText("{{ingresos}}", FormatoUtil.currency(sheet.getRange(2, 1).getValue()));
    body.replaceText("{{mesCorte}}", fechaCorte);
  },

  /**
   * Agrega sección de top 3 gastos
   */
  _agregarTop3Gastos: function(body, analisis) {
    body.appendParagraph('\n').setSpacingAfter(10);
    
    const titulo = body.appendParagraph('🏆 Top 3 Gastos Más Grandes');
    titulo.setHeading(DocumentApp.ParagraphHeading.HEADING2);
    titulo.setForegroundColor(COLORES.PRIMARIO);
    titulo.setBold(true);
    titulo.setSpacingBefore(20);
    titulo.setSpacingAfter(10);

    if (analisis.top3Gastos.length > 0) {
      const medallas = ['🥇', '🥈', '🥉'];
      
      analisis.top3Gastos.forEach(function(gasto, index) {
        const parrafo = body.appendParagraph(
          medallas[index] + ' ' + gasto.descripcion + ' - ' + FormatoUtil.currency(gasto.monto) + '\n' +
          '   📅 ' + gasto.fecha + ' | 📁 ' + gasto.categoria
        );
        parrafo.setIndentStart(20);
        parrafo.setSpacingAfter(8);
        parrafo.editAsText()
               .setBold(true)
               .setForegroundColor(COLORES.MEDALLAS[index]);
      });
    } else {
      body.appendParagraph('No hay gastos registrados este mes.').setItalic(true);
    }
  },

  /**
   * Agrega tabla de distribución por categorías
   */
  _agregarDistribucionCategorias: function(body, analisis) {
    body.appendParagraph('\n').setSpacingAfter(10);
    
    const titulo = body.appendParagraph('📊 Distribución de Gastos por Categoría');
    titulo.setHeading(DocumentApp.ParagraphHeading.HEADING2);
    titulo.setForegroundColor(COLORES.PRIMARIO);
    titulo.setBold(true);
    titulo.setSpacingBefore(20);
    titulo.setSpacingAfter(10);

    const tablaCategorias = [['Categoría', 'Total', 'Porcentaje', 'Gráfica']];
    const totalGastos = analisis.totalGastos;
    
    analisis.gastosPorCategoria.forEach(function(cat) {
      const porcentaje = totalGastos > 0 ? (cat.monto / totalGastos * 100).toFixed(1) : 0;
      const barras = FormatoUtil.barraVisual(porcentaje);
      
      tablaCategorias.push([
        cat.categoria,
        FormatoUtil.currency(cat.monto),
        porcentaje + '%',
        barras
      ]);
    });

    const tabla = body.appendTable(tablaCategorias);
    FormateadorTablas.formatearTablaCategorias(tabla);
  },

  /**
   * Agrega sección de estadísticas
   */
  _agregarEstadisticas: function(body, analisis) {
    body.appendParagraph('\n').setSpacingAfter(10);
    
    const titulo = body.appendParagraph('📈 Resumen Estadístico');
    titulo.setHeading(DocumentApp.ParagraphHeading.HEADING2);
    titulo.setForegroundColor(COLORES.PRIMARIO);
    titulo.setBold(true);
    titulo.setSpacingBefore(20);
    titulo.setSpacingAfter(10);

    const estadisticas = [
      '📌 Total de Transacciones: ' + analisis.totalTransacciones,
      '💰 Gasto Promedio: ' + FormatoUtil.currency(analisis.gastoPromedio),
      '📊 Categoría Principal: ' + analisis.categoriaPrincipal.categoria + 
        ' (' + FormatoUtil.currency(analisis.categoriaPrincipal.monto) + ')',
      '💳 Cuenta Más Utilizada: ' + analisis.cuentaMasUtilizada,
      '📅 Días con Gastos: ' + analisis.diasConGastos + ' de ' + analisis.diasDelMes
    ];

    estadisticas.forEach(function(stat) {
      const p = body.appendParagraph(stat);
      p.setIndentStart(20);
      p.setSpacingAfter(6);
    });
  },

  /**
   * Agrega tabla de todas las transacciones
   */
  _agregarTablaTransacciones: function(body, data) {
    body.appendParagraph('\n').setSpacingAfter(10);
    
    const titulo = body.appendParagraph('📋 Detalle de Transacciones');
    titulo.setHeading(DocumentApp.ParagraphHeading.HEADING2);
    titulo.setForegroundColor(COLORES.PRIMARIO);
    titulo.setBold(true);
    titulo.setSpacingBefore(20);
    titulo.setSpacingAfter(10);

    const tabla = [["Fecha", "Categoría", "Descripción", "Monto", "Tipo"]];

    for (let i = 1; i < data.length; i++) {
      tabla.push([
        FormatoUtil.diaEnLetra(data[i][COLUMNAS_TRANSACCIONES.FECHA]),
        data[i][COLUMNAS_TRANSACCIONES.CATEGORIA],
        data[i][COLUMNAS_TRANSACCIONES.DESCRIPCION].toString(),
        FormatoUtil.currency(data[i][COLUMNAS_TRANSACCIONES.MONTO]),
        data[i][COLUMNAS_TRANSACCIONES.TIPO]
      ]);
    }

    const tableElement = body.appendTable(tabla);
    FormateadorTablas.formatearTablaTransacciones(tableElement);
  },

  /**
   * Convierte el documento a PDF
   */
  _convertirAPDF: function(documento, fechaCorte) {
    documento.doc.saveAndClose();
    
    const docPdf = documento.doc.getAs("application/pdf");
    const nombreArchivo = "Reporte_Mensual_" + fechaCorte.replace(/ /g, "_") + ".pdf";
    docPdf.setName(nombreArchivo);
    
    const carpetaDestino = DriveApp.getFolderById(CONFIG.FOLDER_REPORTES_ID);
    const newPdf = DriveApp.createFile(docPdf);
    newPdf.moveTo(carpetaDestino);
    newPdf.setDescription(fechaCorte);
    
    // Eliminar copia temporal
    DriveApp.getFileById(documento.copiaId).setTrashed(true);
    
    return newPdf;
  },

  /**
   * Limpia las transacciones del mes
   */
  _limpiarTransacciones: function() {
    const sheet = SheetManager.getNuevasTransacciones();
    const totalFilas = sheet.getLastRow();
    
    if (totalFilas > 1) {
      sheet.deleteRows(2, totalFilas - 1);
      Logger.info('GeneradorReportes', 'Transacciones limpiadas', { filas: totalFilas - 1 });
    }
  },

  /**
   * Genera el corte semanal
   */
corteSemanal: function() {
    try {
      Logger.info('GeneradorReportes', 'Iniciando corte semanal');
      
      let suma = 0;
      const sheet = SheetManager.getNuevasTransacciones();
      const data = sheet.getDataRange().getValues();
      
      // Categorías de alimentación
      const categoriasAlimentacion = ['Supermercado', 'Restaurantes', 'Comida Rápida'];
      
      // Buscar y sumar gastos de alimentación
      for (let i = data.length - 1; i >= 1; i--) {
        const categoria = data[i][COLUMNAS_TRANSACCIONES.CATEGORIA];
        if (categoriasAlimentacion.includes(categoria)) {
          suma += parseFloat(data[i][COLUMNAS_TRANSACCIONES.MONTO]) || 0;
          sheet.deleteRow(i + 1);
        }
      }

      // Si hay gastos, crear resumen
      if (suma > 0) {
        const id = FormatoUtil.generarId();
        sheet.appendRow([
          id,
          TIPOS_TRANSACCION.GASTOS,
          suma,
          "Corte Semanal Alimentación",
          FormatoUtil.fechaActual(),
          "Semanal",
          "",
          "",
          ""
        ]);
        
        Logger.info('GeneradorReportes', 'Corte semanal generado', {
          total: suma,
          id: id
        });
      }
      
      return { exito: true, total: suma };
      
    } catch (error) {
      Logger.error('GeneradorReportes.corteSemanal', error);
      return { exito: false, error: error.message };
    }
  }
}

/**
 * Funciones de compatibilidad (legacy)
 */
function corteMensual() {
  return GeneradorReportes.corteMensual();
}

function corteSemanal() {
  return GeneradorReportes.corteSemanal();
}