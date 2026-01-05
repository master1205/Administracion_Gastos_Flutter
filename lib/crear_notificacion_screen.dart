import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/NotificacionPersonalizada.dart';
import 'theme_provider.dart';

class CrearNotificacionScreen extends StatefulWidget {
  final NotificacionPersonalizada? notificacion;

  const CrearNotificacionScreen({Key? key, this.notificacion})
    : super(key: key);

  @override
  State<CrearNotificacionScreen> createState() =>
      _CrearNotificacionScreenState();
}

class _CrearNotificacionScreenState extends State<CrearNotificacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _mensajeController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7}; // Todos los días por defecto
  String _selectedIcon = 'notifications';
  String _selectedColor = 'FF4CAF50';

  final List<Map<String, dynamic>> _iconos = [
    {'name': 'notifications', 'icon': Icons.notifications_rounded},
    {'name': 'alarm', 'icon': Icons.alarm_rounded},
    {'name': 'schedule', 'icon': Icons.schedule_rounded},
    {'name': 'event', 'icon': Icons.event_rounded},
    {'name': 'lightbulb', 'icon': Icons.lightbulb_rounded},
    {'name': 'star', 'icon': Icons.star_rounded},
    {'name': 'favorite', 'icon': Icons.favorite_rounded},
    {'name': 'check_circle', 'icon': Icons.check_circle_rounded},
  ];

  final List<String> _colores = [
    'FF4CAF50', // Verde
    'FF2196F3', // Azul
    'FFFF9800', // Naranja
    'FFF44336', // Rojo
    'FF9C27B0', // Púrpura
    'FFFF5722', // Naranja oscuro
    'FF00BCD4', // Cian
    'FFFFEB3B', // Amarillo
  ];

  final List<Map<String, dynamic>> _dias = [
    {'num': 1, 'nombre': 'Lun'},
    {'num': 2, 'nombre': 'Mar'},
    {'num': 3, 'nombre': 'Mié'},
    {'num': 4, 'nombre': 'Jue'},
    {'num': 5, 'nombre': 'Vie'},
    {'num': 6, 'nombre': 'Sáb'},
    {'num': 7, 'nombre': 'Dom'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.notificacion != null) {
      _tituloController.text = widget.notificacion!.titulo;
      _mensajeController.text = widget.notificacion!.mensaje;
      _selectedTime = TimeOfDay(
        hour: widget.notificacion!.horaInt,
        minute: widget.notificacion!.minutoInt,
      );
      _selectedDays = widget.notificacion!.diasSemana.toSet();
      _selectedIcon = widget.notificacion!.icono;
      _selectedColor = widget.notificacion!.color;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final themeManager = Provider.of<ThemeManager>(context, listen: false);
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(int.parse('0xFF$_selectedColor')),
              onPrimary: Colors.white,
              surface:
                  themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
              onSurface: themeManager.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _guardarNotificacion() {
    if (_formKey.currentState!.validate() && _selectedDays.isNotEmpty) {
      final notificacion = NotificacionPersonalizada(
        id:
            widget.notificacion?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: _tituloController.text.trim(),
        mensaje: _mensajeController.text.trim(),
        hora:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        diasSemana: _selectedDays.toList()..sort(),
        activa: widget.notificacion?.activa ?? true,
        icono: _selectedIcon,
        color: _selectedColor,
      );

      Navigator.pop(context, notificacion);
    } else if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona al menos un día'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isEdit = widget.notificacion != null;

    return Scaffold(
      backgroundColor:
          themeManager.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Editar Notificación' : 'Nueva Notificación',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: Color(int.parse('0xFF$_selectedColor')),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _buildSeccionTitulo('Información Básica', Icons.info_outline),
            SizedBox(height: 12.h),
            _buildCampoTexto(
              controller: _tituloController,
              label: 'Título',
              hint: 'Ej: Revisar gastos del día',
              icon: Icons.title_rounded,
              themeManager: themeManager,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El título es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _buildCampoTexto(
              controller: _mensajeController,
              label: 'Mensaje',
              hint: 'Ej: No olvides registrar tus transacciones',
              icon: Icons.message_outlined,
              maxLines: 3,
              themeManager: themeManager,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El mensaje es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),

            _buildSeccionTitulo('Programación', Icons.schedule_outlined),
            SizedBox(height: 12.h),
            _buildSelectorHora(themeManager),
            SizedBox(height: 16.h),
            _buildSelectorDias(themeManager),
            SizedBox(height: 24.h),

            _buildSeccionTitulo('Personalización', Icons.palette_outlined),
            SizedBox(height: 12.h),
            _buildSelectorIcono(themeManager),
            SizedBox(height: 16.h),
            _buildSelectorColor(themeManager),
            SizedBox(height: 32.h),

            _buildBotonGuardar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(
          icono,
          size: 20.sp,
          color: Color(int.parse('0xFF$_selectedColor')),
        ),
        SizedBox(width: 8.w),
        Text(
          titulo,
          style: GoogleFonts.lato(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Color(int.parse('0xFF$_selectedColor')),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeManager themeManager,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.openSans(
          fontSize: 13.sp,
          color: themeManager.isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Color(int.parse('0xFF$_selectedColor')),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSelectorHora(ThemeManager themeManager) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF$_selectedColor')).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: Color(int.parse('0xFF$_selectedColor')),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hora',
                  style: GoogleFonts.openSans(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  _selectedTime.format(context),
                  style: GoogleFonts.lato(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color:
                        themeManager.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _selectTime,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(int.parse('0xFF$_selectedColor')),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text('Cambiar', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorDias(ThemeManager themeManager) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Días de la semana',
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children:
                _dias.map((dia) {
                  final isSelected = _selectedDays.contains(dia['num']);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(dia['num']);
                        } else {
                          _selectedDays.add(dia['num']);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Color(int.parse('0xFF$_selectedColor'))
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dia['nombre'],
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorIcono(ThemeManager themeManager) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Icono',
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children:
                _iconos.map((icono) {
                  final isSelected = _selectedIcon == icono['name'];
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icono['name']),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Color(
                                  int.parse('0xFF$_selectedColor'),
                                ).withOpacity(0.2)
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12.r),
                        border:
                            isSelected
                                ? Border.all(
                                  color: Color(
                                    int.parse('0xFF$_selectedColor'),
                                  ),
                                  width: 2.w,
                                )
                                : null,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icono['icon'],
                        color:
                            isSelected
                                ? Color(int.parse('0xFF$_selectedColor'))
                                : Colors.grey.shade600,
                        size: 24.sp,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorColor(ThemeManager themeManager) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: themeManager.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children:
                _colores.map((color) {
                  final isSelected = _selectedColor == color;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF$color')),
                        borderRadius: BorderRadius.circular(12.r),
                        border:
                            isSelected
                                ? Border.all(color: Colors.white, width: 3.w)
                                : null,
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: Color(
                                      int.parse('0xFF$color'),
                                    ).withOpacity(0.5),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ]
                                : null,
                      ),
                      alignment: Alignment.center,
                      child:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24.sp,
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse('0xFF$_selectedColor')),
            Color(int.parse('0xFF$_selectedColor')).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse('0xFF$_selectedColor')).withOpacity(0.4),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _guardarNotificacion,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 22.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  widget.notificacion != null
                      ? 'Actualizar'
                      : 'Crear Notificación',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
