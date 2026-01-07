import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/NotificacionPersonalizada.dart';
import 'theme_provider.dart';
import 'crear_notificacion_screen.dart';
import 'local_notifications.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({Key? key}) : super(key: key);

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<NotificacionPersonalizada> notificaciones = [];
  bool isLoading = true;
  int pendingNotificationsCount = 0;
  bool morningEnabled = false;
  bool afternoonEnabled = false;
  bool nightEnabled = false;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
    _cargarEstadoNotificaciones();
    _cargarEstadoSistema();
    // _sincronizarConServidor(); // Ya se sincroniza en loading_screen
  }

  Future<void> _cargarEstadoSistema() async {
    try {
      final morning = await LocalNotifications.isMorningNotificationEnabled();
      final afternoon =
          await LocalNotifications.isAfternoonNotificationEnabled();
      final night = await LocalNotifications.isNightNotificationEnabled();

      if (mounted) {
        setState(() {
          morningEnabled = morning;
          afternoonEnabled = afternoon;
          nightEnabled = night;
        });
      }
    } catch (e) {
      print('Error al cargar estado del sistema: $e');
    }
  }

  Future<void> _cargarEstadoNotificaciones() async {
    try {
      final count = await LocalNotifications.getPendingNotificationsCount();
      if (mounted) {
        setState(() => pendingNotificationsCount = count);
      }
    } catch (e) {
      print('Error al obtener notificaciones pendientes: $e');
    }
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifString = prefs.getString('notificaciones_personalizadas');
      if (notifString != null) {
        final List<dynamic> jsonList = json.decode(notifString);
        notificaciones =
            jsonList
                .map((json) => NotificacionPersonalizada.fromJson(json))
                .toList();

        // Reprogramar notificaciones activas (en caso de reinicio de app)
        for (var notif in notificaciones) {
          if (notif.activa) {
            await _programarNotificacion(notif);
          }
        }
      }
      await _cargarEstadoNotificaciones();
    } catch (e) {
      print('Error al cargar notificaciones: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _guardarNotificaciones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notificaciones.map((n) => n.toJson()).toList();
      await prefs.setString(
        'notificaciones_personalizadas',
        json.encode(jsonList),
      );
    } catch (e) {
      print('Error al guardar notificaciones: $e');
    }
  }

  Future<void> _toggleNotificacion(int index) async {
    final notif = notificaciones[index];
    final nuevoEstado = !notif.activa;

    setState(() {
      notificaciones[index] = notificaciones[index].copyWith(
        activa: nuevoEstado,
      );
    });
    await _guardarNotificaciones();

    // Actualizar notificaciones programadas
    if (notificaciones[index].activa) {
      await _programarNotificacion(notificaciones[index]);
    } else {
      await _cancelarNotificacion(notificaciones[index]);
    }

    await _cargarEstadoNotificaciones();
  }

  Future<void> _programarNotificacion(NotificacionPersonalizada notif) async {
    try {
      await LocalNotifications.scheduleCustomNotificationWithDays(
        notificationId: notif.id,
        title: notif.titulo,
        body: notif.mensaje,
        hour: notif.horaInt,
        minute: notif.minutoInt,
        weekdays: notif.diasSemana,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificación programada correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      print('Error al programar notificación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al programar notificación'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  Future<void> _cancelarNotificacion(NotificacionPersonalizada notif) async {
    try {
      await LocalNotifications.cancelCustomNotification(notif.id);
    } catch (e) {
      print('Error al cancelar notificación: $e');
    }
  }

  Future<void> _eliminarNotificacion(int index) async {
    final notif = notificaciones[index];

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '¿Eliminar notificación?',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Esta acción no se puede deshacer.',
              style: GoogleFonts.openSans(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar', style: GoogleFonts.openSans()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Eliminar', style: GoogleFonts.openSans()),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      await _cancelarNotificacion(notif);
      setState(() => notificaciones.removeAt(index));
      await _guardarNotificaciones();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificación eliminada'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  Future<void> _editarNotificacion(int index) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CrearNotificacionScreen(notificacion: notificaciones[index]),
      ),
    );

    if (resultado is NotificacionPersonalizada) {
      setState(() => notificaciones[index] = resultado);
      await _guardarNotificaciones();
      if (resultado.activa) {
        await _programarNotificacion(resultado);
      }
    }
  }

  Future<void> _crearNotificacion() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CrearNotificacionScreen()),
    );

    if (resultado is NotificacionPersonalizada) {
      setState(() => notificaciones.add(resultado));
      await _guardarNotificaciones();
      if (resultado.activa) {
        await _programarNotificacion(resultado);
      }
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
          'Notificaciones',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: const Color(0xFFf093fb),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, size: 26.sp),
            onPressed: _crearNotificacion,
          ),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3.w,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFf093fb),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  await _cargarNotificaciones();
                  await _cargarEstadoSistema();
                },
                color: const Color(0xFFf093fb),
                child: ListView(
                  padding: EdgeInsets.all(16.r),
                  children: [
                    _buildInfoCard(themeManager),
                    SizedBox(height: 16.h),

                    // Notificaciones del Sistema
                    _buildSeccionHeader(
                      'Notificaciones del Sistema',
                      Icons.schedule_rounded,
                      themeManager,
                    ),
                    SizedBox(height: 12.h),
                    _buildNotificacionSistema(
                      'Recordatorio Matutino',
                      'Revisa tus gastos matutinos',
                      '10:00 AM',
                      morningEnabled,
                      const Color(0xFFFF9800),
                      Icons.wb_sunny_rounded,
                      themeManager,
                    ),
                    SizedBox(height: 12.h),
                    _buildNotificacionSistema(
                      'Recordatorio de Tarde',
                      'No olvides registrar tus compras',
                      '3:00 PM',
                      afternoonEnabled,
                      const Color(0xFF2196F3),
                      Icons.wb_twilight_rounded,
                      themeManager,
                    ),
                    SizedBox(height: 12.h),
                    _buildNotificacionSistema(
                      'Resumen Nocturno',
                      'Cierra el día revisando tu resumen',
                      '9:30 PM',
                      nightEnabled,
                      const Color(0xFF9C27B0),
                      Icons.nightlight_round_rounded,
                      themeManager,
                    ),

                    if (notificaciones.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      _buildSeccionHeader(
                        'Notificaciones Personalizadas',
                        Icons.notifications_active_rounded,
                        themeManager,
                      ),
                      SizedBox(height: 12.h),
                      ...List.generate(
                        notificaciones.length,
                        (index) => _buildNotificacionCard(
                          notificaciones[index],
                          index,
                          themeManager,
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 24.h),
                      _buildEmptyPersonalizadas(),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard(ThemeManager themeManager) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFf093fb).withOpacity(0.3),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 32.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones Personalizadas',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${notificaciones.where((n) => n.activa).length} activas de ${notificaciones.length} totales',
                  style: GoogleFonts.openSans(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$pendingNotificationsCount notificaciones programadas',
                  style: GoogleFonts.openSans(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionCard(
    NotificacionPersonalizada notif,
    int index,
    ThemeManager themeManager,
  ) {
    final color = Color(int.parse('0xFF${notif.color}'));

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editarNotificacion(index),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        _getIcon(notif.icono),
                        color: color,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.titulo,
                            style: GoogleFonts.lato(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            notif.hora,
                            style: GoogleFonts.lato(
                              fontSize: 13.sp,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: notif.activa,
                      onChanged: (value) => _toggleNotificacion(index),
                      activeColor: color,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  notif.mensaje,
                  style: GoogleFonts.openSans(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: color,
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            notif.diasTexto,
                            style: GoogleFonts.openSans(
                              fontSize: 11.sp,
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.send_outlined, size: 20.sp),
                      color: Colors.green.shade400,
                      tooltip: 'Probar ahora',
                      onPressed: () async {
                        await LocalNotifications.showInstantNotification(
                          title: notif.titulo,
                          body: notif.mensaje,
                          payload: 'test_${notif.id}',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Notificación enviada'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.fixed,
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 20.sp),
                      color: Colors.blue.shade400,
                      onPressed: () => _editarNotificacion(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20.sp),
                      color: Colors.red.shade400,
                      onPressed: () => _eliminarNotificacion(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    const iconMap = {
      'notifications': Icons.notifications_rounded,
      'alarm': Icons.alarm_rounded,
      'schedule': Icons.schedule_rounded,
      'event': Icons.event_rounded,
      'lightbulb': Icons.lightbulb_rounded,
      'star': Icons.star_rounded,
      'favorite': Icons.favorite_rounded,
      'check_circle': Icons.check_circle_rounded,
    };
    return iconMap[iconName] ?? Icons.notifications_rounded;
  }

  Widget _buildSeccionHeader(
    String titulo,
    IconData icono,
    ThemeManager themeManager,
  ) {
    return Row(
      children: [
        Icon(
          icono,
          size: 22.sp,
          color:
              themeManager.isDarkMode ? Colors.white : const Color(0xFF667eea),
        ),
        SizedBox(width: 10.w),
        Text(
          titulo,
          style: GoogleFonts.lato(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color:
                themeManager.isDarkMode
                    ? Colors.white
                    : const Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificacionSistema(
    String titulo,
    String mensaje,
    String hora,
    bool activa,
    Color color,
    IconData icono,
    ThemeManager themeManager,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icono, color: color, size: 28.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.lato(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color:
                          themeManager.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hora,
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    mensaje,
                    style: GoogleFonts.openSans(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Activa',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPersonalizadas() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade300, width: 2.w),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notification_add_outlined,
            size: 60.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 12.h),
          Text(
            'Sin notificaciones personalizadas',
            style: GoogleFonts.lato(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Crea recordatorios personalizados con tu horario',
            style: GoogleFonts.openSans(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          TextButton.icon(
            onPressed: _crearNotificacion,
            icon: Icon(Icons.add_circle_outline, size: 18.sp),
            label: Text(
              'Crear Notificación',
              style: GoogleFonts.lato(fontSize: 13.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFf093fb),
              backgroundColor: const Color(0xFFf093fb).withOpacity(0.1),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
