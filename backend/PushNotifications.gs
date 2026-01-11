// ============================================================================
// FIREBASE CLOUD MESSAGING - Envío de notificaciones push
// ============================================================================

/**
 * Envía notificación push a todos los dispositivos registrados
 * usando Firebase Cloud Messaging
 * 
 * @param {string} titulo - Título de la notificación
 * @param {string} mensaje - Cuerpo del mensaje
 * @param {object} data - Datos adicionales (opcional)
 * @returns {object} Resultado del envío
 */
function enviarNotificacionPush(titulo, mensaje, data = {}) {
  try {
    // Obtener credenciales desde Script Properties
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    
    if (!projectId) {
      Logger.error('enviarNotificacionPush', 'FIREBASE_PROJECT_ID no configurado');
      return {
        exito: false,
        error: 'Project ID de Firebase no configurado'
      };
    }

    // Obtener access token OAuth 2.0
    const accessToken = obtenerAccessToken();
    
    // Obtener tokens de dispositivos desde Firestore
    const tokens = obtenerTokensDispositivos();
    
    if (tokens.length === 0) {
      Logger.info('enviarNotificacionPush', 'No hay dispositivos registrados');
      return {
        exito: true,
        mensaje: 'No hay dispositivos registrados',
        enviados: 0
      };
    }

    Logger.info('enviarNotificacionPush', 'Enviando a ' + tokens.length + ' dispositivos');

    // Convertir data object a strings (FCM V1 solo acepta strings en data)
    const dataStrings = {};
    for (let key in data) {
      dataStrings[key] = String(data[key]);
    }

    let exitosos = 0;
    let fallidos = 0;
    const errores = [];

    // Enviar notificación a cada token
    for (let i = 0; i < tokens.length; i++) {
      const resultado = enviarAToken(tokens[i], titulo, mensaje, dataStrings, projectId, accessToken);
      
      if (resultado.exito) {
        exitosos++;
      } else {
        fallidos++;
        errores.push({
          token: tokens[i].substring(0, 20) + '...',
          error: resultado.error
        });
      }
    }

    Logger.info('enviarNotificacionPush', 'Envío completado', {
      exitosos: exitosos,
      fallidos: fallidos
    });

    return {
      exito: true,
      enviados: exitosos,
      fallidos: fallidos,
      errores: errores
    };

  } catch (error) {
    Logger.error('enviarNotificacionPush', error);
    return {
      exito: false,
      error: error.message
    };
  }
}

/**
 * Envía notificación a un token específico usando FCM API V1
 */
function enviarAToken(token, titulo, mensaje, data, projectId, accessToken) {
  try {
    const payload = {
      message: {
        token: token,
        notification: {
          title: titulo,
          body: mensaje
        },
        data: data,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            icon: 'ic_notificacion',
            channel_id: 'fcm_channel'
          }
        }
      }
    };

    const options = {
      method: 'post',
      contentType: 'application/json',
      headers: {
        'Authorization': 'Bearer ' + accessToken
      },
      payload: JSON.stringify(payload),
      muteHttpExceptions: true
    };

    const url = 'https://fcm.googleapis.com/v1/projects/' + projectId + '/messages:send';
    const response = UrlFetchApp.fetch(url, options);

    const responseCode = response.getResponseCode();
    const responseText = response.getContentText();

    if (responseCode === 200) {
      return { exito: true };
    } else {
      return {
        exito: false,
        error: 'HTTP ' + responseCode + ': ' + responseText
      };
    }

  } catch (error) {
    return {
      exito: false,
      error: error.message
    };
  }
}

/**
 * Obtiene un access token OAuth 2.0 usando Service Account
 */
function obtenerAccessToken() {
  try {
    const scriptProperties = PropertiesService.getScriptProperties();
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');

    if (!email || !key) {
      throw new Error('Credenciales de Service Account no configuradas');
    }

    // Crear JWT
    const now = Math.floor(Date.now() / 1000);
    const claim = {
      iss: email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now
    };

    // Generar JWT usando OAuth2 library de Apps Script
    const jwt = createJWT(claim, key);

    // Intercambiar JWT por access token
    const options = {
      method: 'post',
      contentType: 'application/x-www-form-urlencoded',
      payload: {
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt
      },
      muteHttpExceptions: true
    };

    const response = UrlFetchApp.fetch('https://oauth2.googleapis.com/token', options);
    const result = JSON.parse(response.getContentText());

    if (result.access_token) {
      return result.access_token;
    } else {
      throw new Error('No se pudo obtener access token: ' + response.getContentText());
    }

  } catch (error) {
    Logger.error('obtenerAccessToken', error);
    throw error;
  }
}

/**
 * Crea un JWT firmado con RS256
 */
function createJWT(claim, privateKey) {
  const header = {
    alg: 'RS256',
    typ: 'JWT'
  };

  const encodedHeader = Utilities.base64EncodeWebSafe(JSON.stringify(header)).replace(/=+$/, '');
  const encodedClaim = Utilities.base64EncodeWebSafe(JSON.stringify(claim)).replace(/=+$/, '');
  const signatureInput = encodedHeader + '.' + encodedClaim;

  const signature = Utilities.computeRsaSha256Signature(signatureInput, privateKey);
  const encodedSignature = Utilities.base64EncodeWebSafe(signature).replace(/=+$/, '');

  return signatureInput + '.' + encodedSignature;
}

/**
 * Obtiene todos los tokens FCM de Firestore
 * Nota: Necesitas configurar las credenciales de Firestore
 */
function obtenerTokensDispositivos() {
  try {
    // Obtener configuración de Firestore desde Script Properties
    const scriptProperties = PropertiesService.getScriptProperties();
    const projectId = scriptProperties.getProperty('FIREBASE_PROJECT_ID');
    const email = scriptProperties.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = scriptProperties.getProperty('FIREBASE_PRIVATE_KEY');

    if (!projectId || !email || !key) {
      Logger.error('obtenerTokensDispositivos', 'Credenciales de Firestore no configuradas');
      return [];
    }

    // Crear cliente de Firestore
    const firestore = FirestoreApp.getFirestore(email, key, projectId);
    
    // Obtener todos los documentos de la colección fcm_tokens
    const documents = firestore.getDocuments('fcm_tokens');
    
    const tokens = [];
    documents.forEach(doc => {
      if (doc.fields.token && doc.fields.token.stringValue) {
        tokens.push(doc.fields.token.stringValue);
      }
    });

    Logger.info('obtenerTokensDispositivos', 'Tokens obtenidos: ' + tokens.length);
    return tokens;

  } catch (error) {
    Logger.error('obtenerTokensDispositivos', error);
    return [];
  }
}

/**
 * Función auxiliar para enviar notificación cuando termine un corte mensual
 * Se debe llamar desde registrarCorteMensual después de generar el reporte
 */
function notificarCorteMensualCompletado(resumen, cantidadTransacciones, reporteUrl) {
  const titulo = '📊 Corte Mensual Completado';
  const mensaje = `Se procesaron ${cantidadTransacciones} transacciones. ` +
                 `Ingresos: $${resumen.totalIngresos.toFixed(2)} | ` +
                 `Gastos: $${resumen.totalGastos.toFixed(2)}`;
  
  const data = {
    screen: 'reportes',
    reporteUrl: reporteUrl,
    tipo: 'corte_mensual',
    timestamp: new Date().toISOString()
  };

  return enviarNotificacionPush(titulo, mensaje, data);
}

/**
 * Función auxiliar para enviar notificación de corte semanal
 */
function notificarCorteSemanalCompletado(totalSemanal, cantidadTransacciones) {
  const titulo = '🍽️ Corte Semanal Completado';
  const mensaje = `Gastaste $${totalSemanal.toFixed(2)} en ${cantidadTransacciones} transacciones esta semana`;
  
  const data = {
    screen: 'transacciones',
    tipo: 'corte_semanal',
    timestamp: new Date().toISOString()
  };

  return enviarNotificacionPush(titulo, mensaje, data);
}

function configurarCredencialesFirebase() {
  const scriptProperties = PropertiesService.getScriptProperties();
  
  scriptProperties.setProperty('FIREBASE_PROJECT_ID', 'administracion-gastos-f84ea');
  scriptProperties.setProperty('FIREBASE_CLIENT_EMAIL', 'firebase-adminsdk-fbsvc@administracion-gastos-f84ea.iam.gserviceaccount.com');
  scriptProperties.setProperty('FIREBASE_PRIVATE_KEY', '-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCp4MSx9cFe9IXe\n0f6v9woAXx7ElOHbpC0t2Vb37Lmt0yG54e/LBuakFxjXkV46OciMc+9YMkenitNG\n31ztUTmgFh7KsAjJ0UMoVc7jzQivZhdbXqEyWsDN0ZyAOz8Syx+7RziGWw+NHFV0\nXoI1ysBh8phEEYNeBmGgzue0f4Jg91fBEmeK/NKMcnpKNzMj44MgXEbf+KEB4NO4\nQttFStZY9sAqwe3EEXkvDjjh4MMjQUK+VnWeuuOC3oqYGlS+2rnQOGlnX0qJHP8P\nNAnKoMfrvO50qJNU8Cjt/hlDZcDtqiXVwJnRuPjBbkmmwQuZDkWAJ6IUFOsWPs7Y\nvxhPjReZAgMBAAECggEAAmd3cStQtsbQJDSlnZjp79JozZBr199tckIqrGyRvieI\nSSis65sn5XecNuTMSBesQmybnQxtHi5lShH8LzGglqbpfaXbIfwPrsD0Ih4zOsQ/\nnV/r+Rn2s5L9W4U7Icl1JAHgh2o/gJg/j1uNDTTW3yv/QqtayBhgBlYXSmMplbS0\nd9ByWY5W3GXQPaimgj2sXGs8OigrQUHC9F9FC1R7JGuTk9cKaiu4yThwHAiCxenB\n/23nVPSTSInPxidTehjwofkFuuGyZBJaMAqkdbMoraS32YhAoMVZ7C5CAabUmVbS\nDyneZNPTQz6b/Wu3ffkU/BearBZyhO8MOJlTG6cJeQKBgQDv3SdSsvg2e89jz4vP\nfNLCsGLqWfkTubgV8cqCtPqv9alI7VbidNKcvLQ3ngCvgmepTxfoyyMhUkxjxoO/\nZGAi9dQY3QDuHX7S9WaBQUoG7eaJUmjKYsZoga38j2GYDPI2FC4EM2dmroITR5S5\nzMJWbDnAebtRyMrSjkfgXDj9dQKBgQC1TlgPdfti3YblfrOfk7HGn0iJRFYbCKwQ\nZ1KOOGWMZrE+ivHOHWNOdH9ziqOLtsjJi/oHAA5glqsusdHAbqaMqi9nD9cKXv4D\nscsv17F1AVDyGy7EG/wEuhkiYuoB6dlcpZPPhswYMiWyJ3/5j2px29/epuAf4/+a\nrjshDER5FQKBgHGka98IoATgP+/gAzN4xjora5HwssufsBHljrbCnAsF7wB4QjPk\neWx9Ez1OhLCirg5PRNqsc6Zz4XFcOktReSLXKXfmLWyjWNUGI1yV3EbQK+tfufo5\nNhuJZS9Fl018xLzObsbau+CwSTxtK4+j7WcYu3vvsMocwctkUbWAvBeJAoGBAKYq\n/JiG+HR/NiBmBHjP45J38AImyIgUZabPG6HPXHrWr8HzlHTlCFwid6FMwmHNj67x\nBKGf0o2B6bhtLyGgCDNJ0xIxOVR/BW4baG8bz7++ChMrCKyiPVOTwG98mp5QVnAM\nLTF5iNrwMw5aF3eBkvxxmXe2GBoCXATHhNfgJ22VAoGBAKOKqPKMtxM4QLsQRrr3\nKlrUlGMY8qKx6QHB8T3RFiUM61oHHqDXbsA1iapIBm6IFw1whf7W1Zen9IqhDL9j\nwFvdkLtdkQ169OmRdNozleldO2bAU1NQPOmbZkOEO0SvhVG5Nl5iyKqiJUpPqu9O\nHTvgHqPYoQBwod+hkVn+QnzV\n-----END PRIVATE KEY-----\n');
  
  Logger.info('✅ Credenciales configuradas correctamente');
  Logger.info('⚠️ IMPORTANTE: Elimina los valores de esta función después de ejecutarla');
}

/**
 * Función de prueba para verificar que las credenciales funcionan
 */
function verificarCredenciales() {
  try {
    const props = PropertiesService.getScriptProperties();
    const projectId = props.getProperty('FIREBASE_PROJECT_ID');
    const email = props.getProperty('FIREBASE_CLIENT_EMAIL');
    const key = props.getProperty('FIREBASE_PRIVATE_KEY');
    
    Logger.info('Project ID: ' + (projectId ? '✅ ' + projectId : '❌ No configurado'));
    Logger.info('Client Email: ' + (email ? '✅ ' + email : '❌ No configurado'));
    Logger.info('Private Key: ' + (key ? '✅ Configurado (' + key.length + ' caracteres)' : '❌ No configurado'));
    
    if (projectId && email && key) {
      Logger.info('\n🔄 Probando obtener access token...');
      const token = obtenerAccessToken();
      Logger.info('✅ Access token obtenido exitosamente: ' + token.substring(0, 30) + '...');
    }
    
  } catch (error) {
    Logger.info('❌ Error: ' + error.message);
  }
}

