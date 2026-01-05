// ============================================================================
// MÓDULO DE TEMPLATES Y ENVÍO DE CORREOS
// ============================================================================

const EmailTemplates = {
  /**
   * Genera el HTML completo del reporte mensual
   */
  reporteMensual: function(fechaCorte, analisis) {
    return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #f5f5f5; padding: 20px;">' +
      '<div style="background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">' +
        this._header(fechaCorte) +
        this._contenido(analisis) +
        this._footer() +
      '</div>' +
    '</div>';
  },

  /**
   * Genera el header del correo
   */
  _header: function(fechaCorte) {
    return '<div style="background: linear-gradient(135deg, ' + COLORES.PRIMARIO + ' 0%, ' + COLORES.SECUNDARIO + ' 100%); padding: 30px; text-align: center;">' +
      '<img src="https://r7.pngwing.com/path/157/616/973/piggy-bank-clip-art-pig-bbda91a05aa0e73c219cbfd39ac23a0a.png" ' +
           'alt="Piggy Bank" width="80" height="80" />' +
      '<h1 style="color: white; margin: 15px 0 5px 0; font-size: 24px;">Reporte Mensual</h1>' +
      '<p style="color: rgba(255,255,255,0.9); margin: 0; font-size: 16px;">' + fechaCorte + '</p>' +
    '</div>';
  },

  /**
   * Genera el contenido principal
   */
  _contenido: function(analisis) {
    return '<div style="padding: 30px;">' +
      this._saludo() +
      this._resumen(analisis) +
      this._top3Gastos(analisis.top3Gastos) +
      this._cta() +
    '</div>';
  },

  /**
   * Genera el saludo inicial
   */
  _saludo: function() {
    return '<p style="color: #333; font-size: 16px; line-height: 1.6;">' +
      'Hola <strong>Mario y Teo</strong>,' +
    '</p>' +
    '<p style="color: #666; font-size: 14px; line-height: 1.6;">' +
      'Se generó tu reporte mensual con análisis detallado de tus finanzas.' +
    '</p>';
  },

  /**
   * Genera el resumen de gastos
   */
  _resumen: function(analisis) {
    return '<div style="background: #f8f9fa; border-left: 4px solid ' + COLORES.PRIMARIO + '; padding: 15px; margin: 20px 0; border-radius: 5px;">' +
      '<h3 style="margin: 0 0 10px 0; color: ' + COLORES.PRIMARIO + '; font-size: 16px;">📊 Resumen</h3>' +
      '<table style="width: 100%; font-size: 14px;">' +
        '<tr>' +
          '<td style="padding: 5px 0; color: #666;">Total de Gastos:</td>' +
          '<td style="padding: 5px 0; text-align: right; font-weight: bold; color: ' + COLORES.ERROR + ';">' +
            FormatoUtil.currency(analisis.totalGastos) +
          '</td>' +
        '</tr>' +
        '<tr>' +
          '<td style="padding: 5px 0; color: #666;">Gasto Promedio:</td>' +
          '<td style="padding: 5px 0; text-align: right; font-weight: bold;">' +
            FormatoUtil.currency(analisis.gastoPromedio) +
          '</td>' +
        '</tr>' +
        '<tr>' +
          '<td style="padding: 5px 0; color: #666;">Categoría Principal:</td>' +
          '<td style="padding: 5px 0; text-align: right; font-weight: bold; color: ' + COLORES.PRIMARIO + ';">' +
            analisis.categoriaPrincipal.categoria +
          '</td>' +
        '</tr>' +
      '</table>' +
    '</div>';
  },

  /**
   * Genera la tabla del top 3 de gastos
   */
  _top3Gastos: function(top3) {
    if (!top3 || top3.length === 0) {
      return '<p style="color: #999; font-style: italic;">No hay gastos registrados.</p>';
    }

    let html = '<h3 style="color: #333; font-size: 18px; margin: 25px 0 15px 0; border-bottom: 2px solid ' + COLORES.PRIMARIO + '; padding-bottom: 10px;">' +
      '🏆 Top 3 Gastos Más Grandes' +
    '</h3>' +
    '<table style="width: 100%; border-collapse: collapse; font-size: 14px;">';

    const medallas = ['🥇', '🥈', '🥉'];
    
    for (let i = 0; i < top3.length; i++) {
      const gasto = top3[i];
      html += '<tr>' +
        '<td style="padding: 10px; border-bottom: 1px solid #eee;">' +
          '<span style="font-size: 20px;">' + medallas[i] + '</span>' +
        '</td>' +
        '<td style="padding: 10px; border-bottom: 1px solid #eee;">' +
          '<strong>' + gasto.descripcion + '</strong><br>' +
          '<small style="color: #666;">' + gasto.categoria + '</small>' +
        '</td>' +
        '<td style="padding: 10px; text-align: right; border-bottom: 1px solid #eee;">' +
          '<strong style="color: ' + COLORES.ERROR + ';">' + FormatoUtil.currency(gasto.monto) + '</strong>' +
        '</td>' +
      '</tr>';
    }

    html += '</table>';
    return html;
  },

  /**
   * Genera el call-to-action
   */
  _cta: function() {
    return '<div style="text-align: center; margin: 30px 0;">' +
      '<p style="color: #999; font-size: 12px; margin-top: 20px;">' +
        'Puedes acceder al reporte completo desde el apartado de <strong>Reportes</strong> en tu app.' +
      '</p>' +
    '</div>';
  },

  /**
   * Genera el footer
   */
  _footer: function() {
    return '<div style="background: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eee;">' +
      '<p style="margin: 0; color: #666; font-size: 13px;">' +
        '<strong>Administración de Gastos</strong><br>' +
        'Tu asistente financiero personal' +
      '</p>' +
    '</div>';
  }
};

/**
 * Gestor de envío de correos
 */
const EmailSender = {
  /**
   * Envía el correo del reporte mensual
   */
  enviarReporteMensual: function(fechaCorte, analisis) {
    try {
      const htmlBody = EmailTemplates.reporteMensual(fechaCorte, analisis);

      MailApp.sendEmail({
        to: CONFIG.EMAILS_NOTIFICACION.join(", "),
        subject: '💰 Reporte Mensual - ' + fechaCorte,
        htmlBody: htmlBody
      });
      
      Logger.info('EmailSender', 'Correo enviado exitosamente', {
        destinatarios: CONFIG.EMAILS_NOTIFICACION.length,
        fecha: fechaCorte
      });
      
      return { exito: true };
      
    } catch (error) {
      Logger.error('EmailSender.enviarReporteMensual', error);
      return { exito: false, error: error.message };
    }
  }
};

/**
 * Función de compatibilidad (legacy)
 */
function enviarCorreoReporteMejorado(fechaCorte, analisis) {
  return EmailSender.enviarReporteMensual(fechaCorte, analisis);
}