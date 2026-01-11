// ============================================================================
// MÓDULO DE FORMATEO DE TABLAS Y DOCUMENTOS
// ============================================================================

const FormateadorTablas = {
  /**
   * Aplica estilo a encabezado de tabla
   */
  aplicarEstiloEncabezado: function(row, backgroundColor) {
    try {
      row.editAsText()
         .setBold(true)
         .setFontSize(ESTILOS_TABLA.ENCABEZADO.FONT_SIZE)
         .setForegroundColor(ESTILOS_TABLA.ENCABEZADO.FONT_COLOR);
      
      const numCells = row.getNumCells();
      for (let j = 0; j < numCells; j++) {
        row.getCell(j).setBackgroundColor(backgroundColor);
      }
    } catch (error) {
      Logger.error('FormateadorTablas.aplicarEstiloEncabezado', error);
    }
  },
  
  /**
   * Aplica padding a todas las celdas de una fila
   */
  aplicarPadding: function(row) {
    try {
      const numCells = row.getNumCells();
      for (let j = 0; j < numCells; j++) {
        const cell = row.getCell(j);
        cell.setPaddingTop(ESTILOS_TABLA.PADDING.TOP);
        cell.setPaddingBottom(ESTILOS_TABLA.PADDING.BOTTOM);
        cell.setPaddingLeft(ESTILOS_TABLA.PADDING.LEFT);
        cell.setPaddingRight(ESTILOS_TABLA.PADDING.RIGHT);
      }
    } catch (error) {
      Logger.error('FormateadorTablas.aplicarPadding', error);
    }
  },
  
  /**
   * Aplica colores alternados a filas
   */
  aplicarFilasAlternadas: function(row, index) {
    try {
      const bgColor = index % 2 === 0 
        ? ESTILOS_TABLA.FILAS.BG_COLOR_PAR 
        : ESTILOS_TABLA.FILAS.BG_COLOR_IMPAR;
      
      const numCells = row.getNumCells();
      for (let k = 0; k < numCells; k++) {
        row.getCell(k).setBackgroundColor(bgColor);
      }
    } catch (error) {
      Logger.error('FormateadorTablas.aplicarFilasAlternadas', error);
    }
  },
  
  /**
   * Aplica bordes a la tabla
   */
  aplicarBordes: function(table) {
    try {
      table.setBorderColor(ESTILOS_TABLA.BORDES.COLOR);
      table.setBorderWidth(ESTILOS_TABLA.BORDES.WIDTH);
    } catch (error) {
      Logger.error('FormateadorTablas.aplicarBordes', error);
    }
  },
  
  /**
   * Formatea tabla de categorías
   */
  formatearTablaCategorias: function(table) {
    try {
      const numRows = table.getNumRows();
      
      for (let i = 0; i < numRows; i++) {
        const row = table.getRow(i);
        
        // Aplicar padding a todas las filas
        this.aplicarPadding(row);

        if (i === 0) {
          // Encabezado
          this.aplicarEstiloEncabezado(row, ESTILOS_TABLA.ENCABEZADO.BG_COLOR_CATEGORIAS);
        } else {
          // Filas de datos
          row.editAsText()
             .setFontSize(10)
             .setBold(false);
             
          this.aplicarFilasAlternadas(row, i);

          // Formateo especial para columnas
          row.getCell(3).editAsText()
             .setFontFamily("Courier New")
             .setFontSize(9);
          
          row.getCell(1).editAsText().setBold(true);
          row.getCell(2).editAsText().setForegroundColor(COLORES.PRIMARIO);

          // Ajustar anchos para ocupar todo el ancho (total ~468 puntos)
          row.getCell(0).setWidth(140); // Categoría
          row.getCell(1).setWidth(100); // Total
          row.getCell(2).setWidth(70);  // Porcentaje
          row.getCell(3).setWidth(158); // Gráfica
        }
      }

      this.aplicarBordes(table);
      table.setAttributes({ WIDTH: 468 }); // Ancho total de la tabla
      
      Logger.info('FormateadorTablas', 'Tabla de categorías formateada', { filas: numRows });
      
    } catch (error) {
      Logger.error('FormateadorTablas.formatearTablaCategorias', error);
    }
  },
  
  /**
   * Formatea tabla de transacciones
   */
  formatearTablaTransacciones: function(table) {
    try {
      const numRows = table.getNumRows();
      
      for (let i = 0; i < numRows; i++) {
        const row = table.getRow(i);
        
        // Aplicar padding
        this.aplicarPadding(row);

        if (i === 0) {
          // Encabezado
          this.aplicarEstiloEncabezado(row, ESTILOS_TABLA.ENCABEZADO.BG_COLOR_TRANSACCIONES);
        } else {
          // Filas de datos
          row.editAsText()
             .setFontSize(ESTILOS_TABLA.FILAS.FONT_SIZE)
             .setBold(false);
             
          this.aplicarFilasAlternadas(row, i);

          // Formateo especial por columna (sin Categoría)
          row.getCell(0).editAsText().setFontSize(8); // Fecha
          row.getCell(2).editAsText()
             .setBold(true)
             .setForegroundColor("#2D3436"); // Monto
          row.getCell(3).editAsText()
             .setFontSize(8)
             .setItalic(true); // Tipo

          // Ajustar anchos para ocupar todo el ancho (total ~468 puntos)
          row.getCell(0).setWidth(100); // Fecha
          row.getCell(1).setWidth(228); // Descripción (más ancha)
          row.getCell(2).setWidth(70);  // Monto
          row.getCell(3).setWidth(70);  // Tipo
        }
      }

      this.aplicarBordes(table);
      table.setAttributes({ WIDTH: 468 }); // Ancho total de la tabla
      
      Logger.info('FormateadorTablas', 'Tabla de transacciones formateada', { filas: numRows });
      
    } catch (error) {
      Logger.error('FormateadorTablas.formatearTablaTransacciones', error);
    }
  }
};

/**
 * Funciones de compatibilidad (legacy)
 */
function formatearTabla(table) {
  FormateadorTablas.formatearTablaTransacciones(table);
}

function formatearTablaCategorias(table) {
  FormateadorTablas.formatearTablaCategorias(table);
}
