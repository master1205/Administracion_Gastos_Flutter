// ============================================================================
// MÓDULO DE ANÁLISIS DE TRANSACCIONES
// ============================================================================

const AnalizadorTransacciones = {
  /**
   * Analiza todas las transacciones y genera estadísticas
   */
  analizar: function(data) {
    try {
      const gastos = [];
      const gastosPorCategoria = {};
      const gastosPorCuenta = {};
      const diasConGastos = {};
      let totalGastos = 0;

      // Analizar cada transacción
      for (let i = 1; i < data.length; i++) {
        const tipoTransaccion = data[i][COLUMNAS_TRANSACCIONES.TIPO];
        const monto = parseFloat(data[i][COLUMNAS_TRANSACCIONES.MONTO]) || 0;
        const descripcion = data[i][COLUMNAS_TRANSACCIONES.DESCRIPCION] || 'Sin descripción';
        const fecha = data[i][COLUMNAS_TRANSACCIONES.FECHA];
        const categoria = data[i][COLUMNAS_TRANSACCIONES.CATEGORIA] || 'Sin categoría';
        const cuenta = data[i][COLUMNAS_TRANSACCIONES.CUENTA] || 'Sin cuenta';

        if (tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
            tipoTransaccion === TIPOS_TRANSACCION.PAGOS) {
          
          // Agregar a lista de gastos
          gastos.push({
            monto: monto,
            descripcion: descripcion,
            fecha: FormatoUtil.diaEnLetra(fecha),
            categoria: categoria,
            cuenta: cuenta
          });

          // Acumular por categoría
          if (!gastosPorCategoria[categoria]) {
            gastosPorCategoria[categoria] = 0;
          }
          gastosPorCategoria[categoria] += monto;

          // Acumular por cuenta
          if (!gastosPorCuenta[cuenta]) {
            gastosPorCuenta[cuenta] = 0;
          }
          gastosPorCuenta[cuenta] += monto;

          // Contar días únicos con gastos
          if (fecha) {
            const fechaStr = fecha.toString();
            diasConGastos[fechaStr] = true;
          }

          totalGastos += monto;
        }
      }

      // Calcular métricas
      const resultados = {
        top3Gastos: this._calcularTop3(gastos),
        gastosPorCategoria: this._ordenarPorMonto(gastosPorCategoria),
        totalGastos: totalGastos,
        totalTransacciones: gastos.length,
        gastoPromedio: gastos.length > 0 ? totalGastos / gastos.length : 0,
        categoriaPrincipal: this._obtenerCategoriaPrincipal(gastosPorCategoria),
        cuentaMasUtilizada: this._obtenerCuentaMasUtilizada(gastosPorCuenta),
        diasConGastos: Object.keys(diasConGastos).length,
        diasDelMes: this._obtenerDiasDelMes()
      };

      Logger.info('AnalizadorTransacciones', 'Análisis completado', {
        transacciones: resultados.totalTransacciones,
        total: resultados.totalGastos
      });

      return resultados;
      
    } catch (error) {
      Logger.error('AnalizadorTransacciones.analizar', error);
      return this._resultadosVacios();
    }
  },

  /**
   * Analiza transacciones desde un array (para corte mensual optimizado)
   * @param {Array} transacciones - Array de objetos transacción desde Flutter
   */
  analizarArray: function(transacciones) {
    try {
      const gastos = [];
      const gastosPorCategoria = {};
      const gastosPorCuenta = {};
      const diasConGastos = {};
      let totalGastos = 0;

      // Analizar cada transacción
      transacciones.forEach(function(t) {
        const tipoTransaccion = t.tipoTransaccion;
        const monto = parseFloat(t.monto) || 0;
        const descripcion = t.descripcion || 'Sin descripción';
        const fecha = t.fecha;
        const categoria = t.categoria || 'Sin categoría';
        const cuenta = t.cuenta || 'Sin cuenta';

        if (tipoTransaccion === TIPOS_TRANSACCION.GASTOS || 
            tipoTransaccion === TIPOS_TRANSACCION.PAGOS) {
          
          // Agregar a lista de gastos
          gastos.push({
            monto: monto,
            descripcion: descripcion,
            fecha: fecha,
            categoria: categoria,
            cuenta: cuenta
          });

          // Acumular por categoría
          if (!gastosPorCategoria[categoria]) {
            gastosPorCategoria[categoria] = 0;
          }
          gastosPorCategoria[categoria] += monto;

          // Acumular por cuenta
          if (!gastosPorCuenta[cuenta]) {
            gastosPorCuenta[cuenta] = 0;
          }
          gastosPorCuenta[cuenta] += monto;

          // Contar días únicos con gastos
          if (fecha) {
            const fechaStr = fecha.toString();
            diasConGastos[fechaStr] = true;
          }

          totalGastos += monto;
        }
      });

      // Calcular métricas
      const resultados = {
        top3Gastos: this._calcularTop3(gastos),
        gastosPorCategoria: this._ordenarPorMonto(gastosPorCategoria),
        totalGastos: totalGastos,
        totalTransacciones: gastos.length,
        gastoPromedio: gastos.length > 0 ? totalGastos / gastos.length : 0,
        categoriaPrincipal: this._obtenerCategoriaPrincipal(gastosPorCategoria),
        cuentaMasUtilizada: this._obtenerCuentaMasUtilizada(gastosPorCuenta),
        diasConGastos: Object.keys(diasConGastos).length,
        diasDelMes: this._obtenerDiasDelMes()
      };

      Logger.info('AnalizadorTransacciones', 'Análisis completado', {
        transacciones: resultados.totalTransacciones,
        total: resultados.totalGastos
      });

      return resultados;
      
    } catch (error) {
      Logger.error('AnalizadorTransacciones.analizarArray', error);
      return this._resultadosVacios();
    }
  },

  /**
   * Calcula el top 3 de gastos más grandes
   */
  _calcularTop3: function(gastos) {
    const gastosOrdenados = gastos.slice().sort(function(a, b) {
      return b.monto - a.monto;
    });
    return gastosOrdenados.slice(0, 3);
  },

  /**
   * Ordena categorías por monto
   */
  _ordenarPorMonto: function(gastosPorCategoria) {
    const categoriasArray = [];
    for (const cat in gastosPorCategoria) {
      categoriasArray.push({
        categoria: cat,
        monto: gastosPorCategoria[cat]
      });
    }
    
    categoriasArray.sort(function(a, b) {
      return b.monto - a.monto;
    });
    
    return categoriasArray;
  },

  /**
   * Obtiene la categoría con mayor gasto
   */
  _obtenerCategoriaPrincipal: function(gastosPorCategoria) {
    let maxCategoria = 'N/A';
    let maxMonto = 0;

    for (const cat in gastosPorCategoria) {
      if (gastosPorCategoria[cat] > maxMonto) {
        maxMonto = gastosPorCategoria[cat];
        maxCategoria = cat;
      }
    }

    return { categoria: maxCategoria, monto: maxMonto };
  },

  /**
   * Obtiene la cuenta más utilizada
   */
  _obtenerCuentaMasUtilizada: function(gastosPorCuenta) {
    let maxCuenta = 'N/A';
    let maxMonto = 0;

    for (const cuenta in gastosPorCuenta) {
      if (gastosPorCuenta[cuenta] > maxMonto) {
        maxMonto = gastosPorCuenta[cuenta];
        maxCuenta = cuenta;
      }
    }

    return maxCuenta;
  },

  /**
   * Obtiene el número de días del mes actual
   */
  _obtenerDiasDelMes: function() {
    const fecha = new Date();
    return new Date(fecha.getFullYear(), fecha.getMonth() + 1, 0).getDate();
  },

  /**
   * Retorna resultados vacíos en caso de error
   */
  _resultadosVacios: function() {
    return {
      top3Gastos: [],
      gastosPorCategoria: [],
      totalGastos: 0,
      totalTransacciones: 0,
      gastoPromedio: 0,
      categoriaPrincipal: { categoria: 'N/A', monto: 0 },
      cuentaMasUtilizada: 'N/A',
      diasConGastos: 0,
      diasDelMes: 30
    };
  }
};