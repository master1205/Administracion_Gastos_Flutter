import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'componentes/heads_up_notification.dart';
import 'componentes/color_picker_tile.dart';
import 'theme_provider.dart';
import 'services/biometric_service.dart';

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
  bool biometricEnabled = false;
  bool biometricAvailable = false;
  String biometricType = 'No disponible';
  String moneda = 'MXN';
  String idioma = 'Español';
  String versionApp = '1.0.0';

  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    _cargarVersionApp();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final isSupported = await _biometricService.isDeviceSupported();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final typeName = await _biometricService.getBiometricTypeName();

    setState(() {
      biometricAvailable = canCheck && isSupported;
      biometricEnabled = isEnabled;
      biometricType = typeName;
    });
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Ajustes',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16.r,
          right: 16.r,
          top: 16.r,
          bottom: 16.r + MediaQuery.of(context).padding.bottom,
        ),
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
              const ColorPickerTile(),
              _buildListTile(
                'Moneda',
                moneda,
                Icons.attach_money_outlined,
                () => _mostrarSelectorMoneda(),
                themeManager,
              ),
              _buildListTile(
                'Idioma',
                idioma,
                Icons.language_outlined,
                () => _mostrarSelectorIdioma(),
                themeManager,
              ),
            ],
          ),

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
              _buildListTile(
                'Bloqueo con PIN',
                'No configurado',
                Icons.pin_outlined,
                () => _configurarPIN(),
                themeManager,
              ),
              if (biometricAvailable) ...[
                _buildSwitchTile(
                  'Autenticación biométrica',
                  biometricType,
                  Icons.fingerprint_outlined,
                  biometricEnabled,
                  (value) => _toggleBiometric(value),
                  themeManager,
                ),
              ],
            ],
          ),

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
              _buildListTile(
                'Limpiar caché',
                'Liberar espacio',
                Icons.cleaning_services_outlined,
                () => _limpiarCache(),
                themeManager,
              ),
            ],
          ),

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
              _buildListTile(
                'Términos y condiciones',
                '',
                Icons.description_outlined,
                () => _mostrarTerminos(),
                themeManager,
              ),
              _buildListTile(
                'Política de privacidad',
                '',
                Icons.privacy_tip_outlined,
                () => _mostrarPrivacidad(),
                themeManager,
              ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 8.h, top: 16.h),
      child: Row(
        children: [
          Icon(
            icono,
            size: 18.sp,
            color: theme.colorScheme.secondary.withOpacity(0.7),
          ),
          SizedBox(width: 8.w),
          Text(
            titulo,
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: theme.colorScheme.secondary.withOpacity(0.7),
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
    return Column(children: children);
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
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(enabled ? 0.3 : 0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: theme.colorScheme.background,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
        leading: Icon(
          icono,
          color:
              enabled
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.secondary.withOpacity(0.3),
          size: 22.sp,
        ),
        title: Text(
          titulo,
          style: GoogleFonts.lato(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color:
                enabled
                    ? theme.colorScheme.onBackground
                    : theme.colorScheme.onBackground.withOpacity(0.4),
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: GoogleFonts.openSans(
            fontSize: 11.sp,
            color: theme.colorScheme.secondary.withOpacity(enabled ? 0.6 : 0.3),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: theme.colorScheme.primary,
          inactiveTrackColor: theme.colorScheme.secondary.withOpacity(0.2),
          inactiveThumbColor: theme.colorScheme.secondary.withOpacity(0.4),
        ),
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
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: theme.colorScheme.background,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
        leading: Icon(icono, color: theme.colorScheme.secondary, size: 22.sp),
        title: Text(
          titulo,
          style: GoogleFonts.lato(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null && trailing.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  trailing,
                  style: GoogleFonts.openSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            if (onTap != null) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right,
                size: 20.sp,
                color: theme.colorScheme.secondary,
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
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
    final theme = Theme.of(context);
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
                      activeColor: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
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
                      activeColor: theme.colorScheme.primary,
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
    showErrorNotification(context, message: 'Función en desarrollo');
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Autenticar primero antes de habilitar
      final authenticated = await _biometricService.authenticate(
        localizedReason:
            'Verifica tu identidad para habilitar la autenticación biométrica',
      );

      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        setState(() => biometricEnabled = true);

        if (mounted) {
          showSuccessNotification(
            context,
            message: 'Autenticación biométrica activada',
          );
        }
      } else {
        if (mounted) {
          showErrorNotification(
            context,
            message: 'No se pudo verificar tu identidad',
          );
        }
      }
    } else {
      // Desactivar sin autenticación
      await _biometricService.setBiometricEnabled(false);
      setState(() => biometricEnabled = false);

      if (mounted) {
        showSuccessNotification(
          context,
          message: 'Autenticación biométrica desactivada',
        );
      }
    }
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
                  showSuccessNotification(
                    context,
                    message: 'Exportando a Excel...',
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
                  showSuccessNotification(
                    context,
                    message: 'Exportando a CSV...',
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
                  showSuccessNotification(
                    context,
                    message: 'Exportando a PDF...',
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
        final theme = Theme.of(context);
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
                backgroundColor: theme.colorScheme.primary,
              ),
              child: Text('Limpiar', style: GoogleFonts.lato()),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      showSuccessNotification(context, message: 'Caché limpiado correctamente');
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
    showSuccessNotification(context, message: 'Redirigiendo a la tienda...');
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
      showSuccessNotification(context, message: 'Sesión cerrada');
    }
  }
}
