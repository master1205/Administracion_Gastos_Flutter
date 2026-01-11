import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'theme_provider.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({Key? key}) : super(key: key);

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool notificacionesActivas = true;
  bool sonidoActivo = true;
  bool vibracionActiva = true;
  bool ocultarSaldos = false;
  String moneda = 'MXN';
  String idioma = 'Español';
  String versionApp = '1.0.0';

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    _cargarVersionApp();
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificacionesActivas = prefs.getBool('notificaciones_activas') ?? true;
      sonidoActivo = prefs.getBool('sonido_activo') ?? true;
      vibracionActiva = prefs.getBool('vibracion_activa') ?? true;
      ocultarSaldos = prefs.getBool('ocultar_saldos') ?? false;
      moneda = prefs.getString('moneda') ?? 'MXN';
      idioma = prefs.getString('idioma') ?? 'Español';
    });
  }

  Future<void> _cargarVersionApp() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      versionApp = packageInfo.version;
    });
  }

  Future<void> _guardarConfiguracion(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      backgroundColor:
          themeManager.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Ajustes',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: const Color(0xFF30cfd0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          // GENERAL
          _buildSeccionTitulo('General', Icons.settings_outlined, themeManager),
          _buildCard(
            themeManager,
            children: [
              _buildSwitchTile(
                'Tema oscuro',
                'Activar modo nocturno',
                Icons.dark_mode_outlined,
                themeManager.isDarkMode,
                (value) => themeManager.toggleTheme(),
                themeManager,
              ),
              Divider(height: 1.h),
              _buildListTile(
                'Moneda',
                moneda,
                Icons.attach_money_outlined,
                () => _mostrarSelectorMoneda(),
                themeManager,
              ),
              Divider(height: 1.h),
              _buildListTile(
                'Idioma',
                idioma,
                Icons.language_outlined,
                () => _mostrarSelectorIdioma(),
                themeManager,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // NOTIFICACIONES
          _buildSeccionTitulo(
            'Notificaciones',
            Icons.notifications_outlined,
            themeManager,
          ),
          _buildCard(
            themeManager,
            children: [
              _buildSwitchTile(
                'Notificaciones',
                'Activar todas las notificaciones',
                Icons.notifications_active_outlined,
                notificacionesActivas,
                (value) {
                  setState(() => notificacionesActivas = value);
                  _guardarConfiguracion('notificaciones_activas', value);
                },
                themeManager,
              ),
              Divider(height: 1.h),
              _buildSwitchTile(
                'Sonido',
                'Reproducir sonido',
                Icons.volume_up_outlined,
                sonidoActivo,
                (value) {
                  setState(() => sonidoActivo = value);
                  _guardarConfiguracion('sonido_activo', value);
                },
                themeManager,
                enabled: notificacionesActivas,
              ),
              Divider(height: 1.h),
              _buildSwitchTile(
                'Vibración',
                'Vibrar al recibir notificación',
                Icons.vibration_outlined,
                vibracionActiva,
                (value) {
                  setState(() => vibracionActiva = value);
                  _guardarConfiguracion('vibracion_activa', value);
                },
                themeManager,
                enabled: notificacionesActivas,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // PRIVACIDAD
          _buildSeccionTitulo('Privacidad', Icons.lock_outlined, themeManager),
          _buildCard(
            themeManager,
            children: [
              _buildSwitchTile(
                'Ocultar saldos',
                'No mostrar montos en pantalla principal',
                Icons.visibility_off_outlined,
                ocultarSaldos,
                (value) {
                  setState(() => ocultarSaldos = value);
                  _guardarConfiguracion('ocultar_saldos', value);
                },
                themeManager,
              ),
              Divider(height: 1.h),
              _buildListTile(
                'Bloqueo con PIN',
                'No configurado',
                Icons.pin_outlined,
                () => _configurarPIN(),
                themeManager,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // DATOS
          _buildSeccionTitulo('Datos', Icons.storage_outlined, themeManager),
          _buildCard(
            themeManager,
            children: [
              _buildListTile(
                'Exportar datos',
                'CSV, Excel, PDF',
                Icons.file_download_outlined,
                () => _exportarDatos(),
                themeManager,
              ),
              Divider(height: 1.h),
              _buildListTile(
                'Limpiar caché',
                'Liberar espacio',
                Icons.cleaning_services_outlined,
                () => _limpiarCache(),
                themeManager,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // ACERCA DE
          _buildSeccionTitulo('Acerca de', Icons.info_outlined, themeManager),
          _buildCard(
            themeManager,
            children: [
              _buildListTile(
                'Versión',
                versionApp,
                Icons.apps_outlined,
                null,
                themeManager,
              ),
              Divider(height: 1.h),
              _buildListTile(
                'Términos y condiciones',
                '',
                Icons.description_outlined,
                () => _mostrarTerminos(),
                themeManager,
              ),
              Divider(height: 1.h),
              _buildListTile(
                'Política de privacidad',
                '',
                Icons.privacy_tip_outlined,
                () => _mostrarPrivacidad(),
                themeManager,
              ),
              Divider(height: 1.h),
              _buildListTile(
                'Calificar app',
                '',
                Icons.star_outline,
                () => _calificarApp(),
                themeManager,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // BOTÓN DE CERRAR SESIÓN
          _buildBotonPeligro(
            'Cerrar sesión',
            Icons.logout,
            () => _cerrarSesion(),
          ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildSeccionTitulo(
    String titulo,
    IconData icono,
    ThemeManager themeManager,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
      child: Row(
        children: [
          Icon(icono, size: 20.sp, color: const Color(0xFF30cfd0)),
          SizedBox(width: 10.w),
          Text(
            titulo,
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color:
                  themeManager.isDarkMode
                      ? Colors.white
                      : const Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    ThemeManager themeManager, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String titulo,
    String subtitulo,
    IconData icono,
    bool value,
    Function(bool) onChanged,
    ThemeManager themeManager, {
    bool enabled = true,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: Icon(
        icono,
        color: enabled ? const Color(0xFF30cfd0) : Colors.grey,
        size: 24.sp,
      ),
      title: Text(
        titulo,
        style: GoogleFonts.lato(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color:
              enabled
                  ? (themeManager.isDarkMode ? Colors.white : Colors.black87)
                  : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: GoogleFonts.openSans(
          fontSize: 11.sp,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: const Color(0xFF30cfd0),
      ),
    );
  }

  Widget _buildListTile(
    String titulo,
    String? trailing,
    IconData icono,
    VoidCallback? onTap,
    ThemeManager themeManager,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: Icon(icono, color: const Color(0xFF30cfd0), size: 24.sp),
      title: Text(
        titulo,
        style: GoogleFonts.lato(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: themeManager.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null && trailing.isNotEmpty)
            Text(
              trailing,
              style: GoogleFonts.openSans(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          if (onTap != null) ...[
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right, size: 20.sp, color: Colors.grey.shade400),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildBotonPeligro(
    String texto,
    IconData icono,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 20.sp),
        label: Text(
          texto,
          style: GoogleFonts.lato(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares
  void _mostrarSelectorMoneda() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Seleccionar moneda',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                color: themeManager.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['MXN', 'USD', 'EUR', 'GBP'].map((m) {
                    return RadioListTile<String>(
                      title: Text(
                        m,
                        style: GoogleFonts.openSans(
                          color:
                              themeManager.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      value: m,
                      groupValue: moneda,
                      activeColor: const Color(0xFF30cfd0),
                      onChanged: (value) {
                        setState(() => moneda = value!);
                        _guardarConfiguracion('moneda', value);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _mostrarSelectorIdioma() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Seleccionar idioma',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                color: themeManager.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['Español', 'English'].map((i) {
                    return RadioListTile<String>(
                      title: Text(
                        i,
                        style: GoogleFonts.openSans(
                          color:
                              themeManager.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      value: i,
                      groupValue: idioma,
                      activeColor: const Color(0xFF30cfd0),
                      onChanged: (value) {
                        setState(() => idioma = value!);
                        _guardarConfiguracion('idioma', value);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _configurarPIN() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Función en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _exportarDatos() {
    showDialog(
      context: context,
      builder: (context) {
        final themeManager = Provider.of<ThemeManager>(context, listen: false);
        return AlertDialog(
          backgroundColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Exportar datos',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.table_chart, color: Colors.green),
                title: Text(
                  'Excel',
                  style: GoogleFonts.openSans(
                    color:
                        themeManager.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exportando a Excel...')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.description, color: Colors.blue),
                title: Text(
                  'CSV',
                  style: GoogleFonts.openSans(
                    color:
                        themeManager.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exportando a CSV...')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(
                  'PDF',
                  style: GoogleFonts.openSans(
                    color:
                        themeManager.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exportando a PDF...')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _limpiarCache() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final themeManager = Provider.of<ThemeManager>(context, listen: false);
        return AlertDialog(
          backgroundColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            '¿Limpiar caché?',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Se eliminarán datos temporales para liberar espacio',
            style: GoogleFonts.openSans(
              color: themeManager.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.openSans()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF30cfd0),
              ),
              child: Text('Limpiar', style: GoogleFonts.lato()),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caché limpiado correctamente'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  void _mostrarTerminos() {
    showDialog(
      context: context,
      builder: (context) {
        final themeManager = Provider.of<ThemeManager>(context, listen: false);
        return AlertDialog(
          backgroundColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Términos y condiciones',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Aquí irían los términos y condiciones de la aplicación...',
              style: GoogleFonts.openSans(
                color:
                    themeManager.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: GoogleFonts.lato()),
            ),
          ],
        );
      },
    );
  }

  void _mostrarPrivacidad() {
    showDialog(
      context: context,
      builder: (context) {
        final themeManager = Provider.of<ThemeManager>(context, listen: false);
        return AlertDialog(
          backgroundColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Política de privacidad',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Aquí iría la política de privacidad de la aplicación...',
              style: GoogleFonts.openSans(
                color:
                    themeManager.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: GoogleFonts.lato()),
            ),
          ],
        );
      },
    );
  }

  void _calificarApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirigiendo a la tienda...'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  void _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final themeManager = Provider.of<ThemeManager>(context, listen: false);
        return AlertDialog(
          backgroundColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            '¿Cerrar sesión?',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Se perderán los datos no sincronizados',
            style: GoogleFonts.openSans(
              color: themeManager.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.openSans()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: Text('Cerrar sesión', style: GoogleFonts.lato()),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sesión cerrada'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    }
  }
}
