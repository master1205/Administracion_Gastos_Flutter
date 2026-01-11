// ============================================================================
// SISTEMA DE CACHÉ PARA OPTIMIZACIÓN DE RENDIMIENTO
// ============================================================================

/**
 * Administrador de caché usando CacheService de Google Apps Script
 */
const CacheManager = {
  CACHE_DURATION: 300, // 5 minutos en segundos
  
  /**
   * Obtiene un valor del caché
   */
  get: function(key) {
    try {
      const cache = CacheService.getScriptCache();
      const cached = cache.get(key);
      if (cached) {
        Logger.info('CacheManager.get', 'Cache HIT: ' + key);
        return JSON.parse(cached);
      }
      Logger.info('CacheManager.get', 'Cache MISS: ' + key);
      return null;
    } catch (error) {
      Logger.error('CacheManager.get', error);
      return null;
    }
  },
  
  /**
   * Guarda un valor en el caché
   */
  set: function(key, data, duration) {
    try {
      const cache = CacheService.getScriptCache();
      const cacheTime = duration || this.CACHE_DURATION;
      cache.put(key, JSON.stringify(data), cacheTime);
      Logger.info('CacheManager.set', 'Cached: ' + key + ' for ' + cacheTime + 's');
      return true;
    } catch (error) {
      Logger.error('CacheManager.set', error);
      return false;
    }
  },
  
  /**
   * Elimina una o todas las entradas del caché
   */
  clear: function(key) {
    try {
      const cache = CacheService.getScriptCache();
      if (key) {
        cache.remove(key);
        Logger.info('CacheManager.clear', 'Cleared: ' + key);
      } else {
        // Limpiar todas las claves conocidas
        const keys = ['cuentas', 'metas', 'transacciones', 'categorias', 'dashboard'];
        cache.removeAll(keys);
        Logger.info('CacheManager.clear', 'Cleared all cache');
      }
      return true;
    } catch (error) {
      Logger.error('CacheManager.clear', error);
      return false;
    }
  },
  
  /**
   * Invalida múltiples claves relacionadas
   */
  invalidateRelated: function(keys) {
    try {
      const cache = CacheService.getScriptCache();
      cache.removeAll(keys);
      Logger.info('CacheManager.invalidateRelated', 'Cleared: ' + keys.join(', '));
      return true;
    } catch (error) {
      Logger.error('CacheManager.invalidateRelated', error);
      return false;
    }
  }
};

/**
 * Wrapper para SheetManager con soporte de caché
 */
const CachedSheetManager = {
  /**
   * Obtiene datos de cuentas con caché
   */
  getCuentas: function(useCache) {
    const shouldUseCache = useCache !== false; // Por defecto true
    
    if (shouldUseCache) {
      const cached = CacheManager.get('cuentas');
      if (cached) return cached;
    }
    
    const sheet = SheetManager.getNuevasCuentas();
    const data = sheet.getDataRange().getValues();
    
    if (shouldUseCache) {
      CacheManager.set('cuentas', data);
    }
    
    return data;
  },
  
  /**
   * Obtiene datos de metas con caché
   */
  getMetas: function(useCache) {
    const shouldUseCache = useCache !== false;
    
    if (shouldUseCache) {
      const cached = CacheManager.get('metas');
      if (cached) return cached;
    }
    
    const sheet = SheetManager.getMetas();
    const data = sheet.getDataRange().getValues();
    
    if (shouldUseCache) {
      CacheManager.set('metas', data);
    }
    
    return data;
  },
  
  /**
   * Obtiene datos de transacciones con caché (limitado a 60 segundos)
   */
  getTransacciones: function(useCache) {
    const shouldUseCache = useCache !== false;
    
    if (shouldUseCache) {
      const cached = CacheManager.get('transacciones');
      if (cached) return cached;
    }
    
    const sheet = SheetManager.getNuevasTransacciones();
    const data = sheet.getDataRange().getValues();
    
    if (shouldUseCache) {
      // Caché más corto para transacciones (60 segundos)
      CacheManager.set('transacciones', data, 60);
    }
    
    return data;
  },
  
  /**
   * Obtiene datos de categorías con caché
   */
  getCategorias: function(useCache) {
    const shouldUseCache = useCache !== false;
    
    if (shouldUseCache) {
      const cached = CacheManager.get('categorias');
      if (cached) return cached;
    }
    
    const sheet = SheetManager.getCategorias();
    const data = sheet.getDataRange().getValues();
    
    if (shouldUseCache) {
      CacheManager.set('categorias', data);
    }
    
    return data;
  },
  
  /**
   * Invalida el caché de cuentas
   */
  invalidateCuentas: function() {
    CacheManager.clear('cuentas');
    CacheManager.clear('dashboard'); // Dashboard también depende de cuentas
  },
  
  /**
   * Invalida el caché de metas
   */
  invalidateMetas: function() {
    CacheManager.clear('metas');
    CacheManager.clear('dashboard');
  },
  
  /**
   * Invalida el caché de transacciones
   */
  invalidateTransacciones: function() {
    CacheManager.clear('transacciones');
    CacheManager.clear('dashboard');
  },
  
  /**
   * Invalida todo el caché
   */
  invalidateAll: function() {
    CacheManager.clear();
  }
};

/**
 * Cola para sincronización por lotes
 */
const SyncQueue = {
  queue: [],
  
  /**
   * Agrega una cuenta a la cola de sincronización
   */
  add: function(nombreCuenta) {
    if (!nombreCuenta) return;
    if (!this.queue.includes(nombreCuenta)) {
      this.queue.push(nombreCuenta);
      Logger.info('SyncQueue.add', 'Agregado a cola: ' + nombreCuenta);
    }
  },
  
  /**
   * Procesa toda la cola de sincronización (optimizado)
   */
  process: function() {
    if (this.queue.length === 0) {
      return;
    }
    
    try {
      Logger.info('SyncQueue.process', 'Procesando ' + this.queue.length + ' cuentas');
      
      // Cargar datos UNA SOLA VEZ
      const cuentasData = CachedSheetManager.getCuentas(false); // Sin caché para datos frescos
      const metasSheet = SheetManager.getMetas();
      const metasData = metasSheet.getDataRange().getValues();
      
      // Si no hay metas, salir rápido
      if (metasData.length <= 1) {
        Logger.info('SyncQueue.process', 'No hay metas, saltando sincronización');
        this.queue = [];
        return;
      }
      
      // Crear un mapa de numeroTarjeta -> índice de meta para búsqueda rápida
      const metasMap = {};
      for (let i = 1; i < metasData.length; i++) {
        const numeroTarjeta = metasData[i][6]; // Columna G
        if (numeroTarjeta) {
          metasMap[numeroTarjeta.toString()] = i;
        }
      }
      
      // Si no hay metas con cuentas asociadas, salir
      if (Object.keys(metasMap).length === 0) {
        Logger.info('SyncQueue.process', 'No hay metas con cuentas asociadas');
        this.queue = [];
        return;
      }
      
      // Procesar solo las cuentas que tienen metas asociadas
      const cuentasConMeta = [];
      this.queue.forEach(nombreCuenta => {
        // Buscar numeroTarjeta
        for (let i = 1; i < cuentasData.length; i++) {
          if (cuentasData[i][1] === nombreCuenta) {
            const numeroTarjeta = cuentasData[i][5];
            if (numeroTarjeta && metasMap[numeroTarjeta.toString()]) {
              cuentasConMeta.push({
                nombre: nombreCuenta,
                numeroTarjeta: numeroTarjeta.toString(),
                saldo: parseFloat(cuentasData[i][2]) || 0,
                metaIndex: metasMap[numeroTarjeta.toString()]
              });
            }
            break;
          }
        }
      });
      
      // Actualizar solo las metas que necesitan actualización
      cuentasConMeta.forEach(cuenta => {
        metasSheet.getRange(cuenta.metaIndex + 1, 5).setValue(cuenta.saldo);
      });
      
      Logger.info('SyncQueue.process', 'Sincronizadas ' + cuentasConMeta.length + ' metas');
      
      // Limpiar cola
      this.queue = [];
      
      // Invalidar caché de metas solo si hubo cambios
      if (cuentasConMeta.length > 0) {
        CachedSheetManager.invalidateMetas();
      }
      
    } catch (error) {
      Logger.error('SyncQueue.process', error);
      this.queue = [];
    }
  },
  
  /**
   * Sincroniza una cuenta individual usando datos ya cargados
   */
  _syncSingle: function(nombreCuenta, cuentasData, metasData, metasSheet) {
    try {
      // Buscar numeroTarjeta de la cuenta
      let numeroTarjeta = null;
      for (let i = 1; i < cuentasData.length; i++) {
        if (cuentasData[i][1] === nombreCuenta) { // Columna B: nombre
          numeroTarjeta = cuentasData[i][5]; // Columna F: numeroTarjeta
          break;
        }
      }
      
      if (!numeroTarjeta) return;
      
      // Buscar meta asociada
      for (let i = 1; i < metasData.length; i++) {
        if (metasData[i][6] && metasData[i][6].toString() === numeroTarjeta.toString()) {
          // Encontrar saldo actual de la cuenta
          let saldoActual = 0;
          for (let j = 1; j < cuentasData.length; j++) {
            if (cuentasData[j][5] && cuentasData[j][5].toString() === numeroTarjeta.toString()) {
              saldoActual = parseFloat(cuentasData[j][2]) || 0; // Columna C: saldo
              break;
            }
          }
          
          // Actualizar meta
          metasSheet.getRange(i + 1, 5).setValue(saldoActual); // Columna E: montoActual
          Logger.info('SyncQueue._syncSingle', 'Meta actualizada para ' + nombreCuenta);
          break;
        }
      }
      
    } catch (error) {
      Logger.error('SyncQueue._syncSingle', error);
    }
  }
};

