import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'componentes/heads_up_notification.dart';
import 'models/Meta.dart';
import 'theme_provider.dart';
import 'widgets/discard_changes_dialog.dart';
import 'widgets/select_amount.dart';

class CrearMetaScreen extends StatefulWidget {
  final Meta? meta;

  const CrearMetaScreen({Key? key, this.meta}) : super(key: key);

  @override
  State<CrearMetaScreen> createState() => _CrearMetaScreenState();
}

class _CrearMetaScreenState extends State<CrearMetaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _montoController;
  DateTime _fechaObjetivo = DateTime.now().add(Duration(days: 365));
  String _iconoSeleccionado = 'savings';
  String _colorSeleccionado = '4CAF50';

  // Variables para detectar cambios
  late String _initialNombre;
  late String _initialDescripcion;
  late String _initialMonto;
  late DateTime _initialFecha;
  late String _initialIcono;
  late String _initialColor;

  final List<Map<String, dynamic>> _iconos = [
    {'icon': Icons.savings, 'name': 'savings', 'label': 'Ahorro'},
    {'icon': Icons.home, 'name': 'home', 'label': 'Casa'},
    {'icon': Icons.directions_car, 'name': 'car', 'label': 'Auto'},
    {'icon': Icons.flight, 'name': 'travel', 'label': 'Viaje'},
    {'icon': Icons.school, 'name': 'education', 'label': 'Educación'},
    {'icon': Icons.local_hospital, 'name': 'emergency', 'label': 'Emergencia'},
    {'icon': Icons.card_giftcard, 'name': 'gift', 'label': 'Regalo'},
  ];

  final List<Map<String, String>> _colores = [
    {'color': '4CAF50', 'name': 'Verde'},
    {'color': '2196F3', 'name': 'Azul'},
    {'color': 'FF9800', 'name': 'Naranja'},
    {'color': 'E91E63', 'name': 'Rosa'},
    {'color': '9C27B0', 'name': 'Morado'},
    {'color': 'F44336', 'name': 'Rojo'},
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.meta?.nombre ?? '');
    _descripcionController = TextEditingController(
      text: widget.meta?.descripcion ?? '',
    );
    _montoController = TextEditingController(
      text: widget.meta?.montoObjetivo.toString() ?? '',
    );

    if (widget.meta != null) {
      _iconoSeleccionado = widget.meta!.icono;
      _colorSeleccionado = widget.meta!.color;
      try {
        _fechaObjetivo = DateTime.parse(widget.meta!.fechaObjetivo);
      } catch (e) {}
    }

    _saveInitialState();
  }

  void _saveInitialState() {
    _initialNombre = _nombreController.text;
    _initialDescripcion = _descripcionController.text;
    _initialMonto = _montoController.text;
    _initialFecha = _fechaObjetivo;
    _initialIcono = _iconoSeleccionado;
    _initialColor = _colorSeleccionado;
  }

  bool _hasChanges() {
    return _nombreController.text != _initialNombre ||
        _descripcionController.text != _initialDescripcion ||
        _montoController.text != _initialMonto ||
        _fechaObjetivo != _initialFecha ||
        _iconoSeleccionado != _initialIcono ||
        _colorSeleccionado != _initialColor;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges()) {
      return await DiscardChangesDialog.show(context);
    }
    return true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;
    final colorSeleccionado = Color(
      int.parse('FF$_colorSeleccionado', radix: 16),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: colorSeleccionado,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.meta == null ? 'Nueva Meta' : 'Editar Meta',
            style: GoogleFonts.lato(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          children: [
            // Header con ícono
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: colorSeleccionado,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconoActual(),
                      color: Colors.white,
                      size: 48.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Define tu objetivo de ahorro',
                    style: GoogleFonts.openSans(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20.r,
                  right: 20.r,
                  top: 20.r,
                  bottom: 20.r + MediaQuery.of(context).padding.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      _buildSectionTitle('Nombre de la meta'),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          hintText: 'Ej: Casa nueva, Auto, Vacaciones',
                          prefixIcon: Icons.label_outline,
                          color: colorSeleccionado,
                        ),
                        validator:
                            (v) =>
                                v?.isEmpty == true ? 'Campo requerido' : null,
                      ),
                      SizedBox(height: 16.h),

                      // Descripción
                      _buildSectionTitle('Descripción (opcional)'),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _descripcionController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          hintText: 'Añade más detalles sobre tu meta',
                          prefixIcon: Icons.description_outlined,
                          color: colorSeleccionado,
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 16.h),

                      // Monto objetivo
                      _buildSectionTitle('Monto objetivo'),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () async {
                          final currentAmount =
                              _montoController.text.isNotEmpty
                                  ? double.tryParse(
                                        _montoController.text.replaceAll(
                                          ',',
                                          '',
                                        ),
                                      ) ??
                                      0.0
                                  : 0.0;

                          final result = await showSelectAmountBottomSheet(
                            context,
                            title: 'Ingresa el monto objetivo',
                            initialAmount: currentAmount,
                            allowZero: false,
                            currencySymbol: '\$',
                          );

                          if (result != null) {
                            setState(() {
                              _montoController.text = result.toStringAsFixed(2);
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                            left: 8.w,
                            right: 16.w,
                            top: 8.h,
                            bottom: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: colorSeleccionado.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorSeleccionado,
                                      colorSeleccionado.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorSeleccionado.withOpacity(0.3),
                                      blurRadius: 4.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.attach_money,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  _montoController.text.isNotEmpty
                                      ? NumberFormat.currency(
                                        locale: 'es_MX',
                                        symbol: '\$',
                                        decimalDigits: 2,
                                      ).format(
                                        double.tryParse(
                                              _montoController.text.replaceAll(
                                                ',',
                                                '',
                                              ),
                                            ) ??
                                            0.0,
                                      )
                                      : '\$ 0.00',
                                  style: GoogleFonts.lato(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _montoController.text.isNotEmpty
                                            ? (isDark
                                                ? Colors.white
                                                : Colors.black87)
                                            : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Fecha objetivo
                      _buildSectionTitle('Fecha objetivo'),
                      SizedBox(height: 8.h),
                      InkWell(
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaObjetivo,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 3650)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: colorSeleccionado,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (fecha != null) {
                            setState(() => _fechaObjetivo = fecha);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: colorSeleccionado,
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                DateFormat(
                                  'dd \'de\' MMMM \'de\' yyyy',
                                  'es',
                                ).format(_fechaObjetivo),
                                style: GoogleFonts.lato(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Spacer(),
                              Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Selector de ícono
                      _buildSectionTitle('Ícono'),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children:
                            _iconos.map((icono) {
                              final seleccionado =
                                  _iconoSeleccionado == icono['name'];
                              return GestureDetector(
                                onTap:
                                    () => setState(
                                      () => _iconoSeleccionado = icono['name'],
                                    ),
                                child: Container(
                                  width: 60.w,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    color:
                                        seleccionado
                                            ? colorSeleccionado.withOpacity(0.1)
                                            : (isDark
                                                ? Colors.grey.shade800
                                                : Colors.white),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color:
                                          seleccionado
                                              ? colorSeleccionado
                                              : (isDark
                                                  ? Colors.grey.shade700
                                                  : Colors.grey.shade300),
                                      width: seleccionado ? 2 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    icono['icon'],
                                    size: 28.sp,
                                    color:
                                        seleccionado
                                            ? colorSeleccionado
                                            : Colors.grey.shade600,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      SizedBox(height: 20.h),

                      // Selector de color
                      _buildSectionTitle('Color'),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children:
                            _colores.map((color) {
                              final seleccionado =
                                  _colorSeleccionado == color['color'];
                              final colorInt = int.parse(
                                'FF${color['color']}',
                                radix: 16,
                              );
                              return GestureDetector(
                                onTap:
                                    () => setState(
                                      () =>
                                          _colorSeleccionado = color['color']!,
                                    ),
                                child: Container(
                                  width: 50.w,
                                  height: 50.h,
                                  decoration: BoxDecoration(
                                    color: Color(colorInt),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          seleccionado
                                              ? Colors.black
                                              : Colors.grey.shade300,
                                      width: seleccionado ? 3 : 1,
                                    ),
                                    boxShadow:
                                        seleccionado
                                            ? [
                                              BoxShadow(
                                                color: Color(
                                                  colorInt,
                                                ).withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child:
                                      seleccionado
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
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 12.h),
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_montoController.text.isEmpty ||
                    double.tryParse(
                          _montoController.text.replaceAll(',', ''),
                        ) ==
                        0) {
                  showErrorNotification(
                    context,
                    message: 'Por favor ingresa un monto objetivo',
                  );
                  return;
                }

                final cleanMonto = _montoController.text.replaceAll(',', '');
                final meta = Meta(
                  id:
                      widget.meta?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  nombre: _nombreController.text,
                  descripcion: _descripcionController.text,
                  montoObjetivo: double.parse(cleanMonto),
                  montoActual: widget.meta?.montoActual ?? 0,
                  fechaInicio:
                      widget.meta?.fechaInicio ??
                      DateTime.now().toIso8601String(),
                  fechaObjetivo: _fechaObjetivo.toIso8601String(),
                  icono: _iconoSeleccionado,
                  color: _colorSeleccionado,
                  completada: widget.meta?.completada ?? false,
                  cuentaId: widget.meta?.cuentaId,
                  cuentaNombre: widget.meta?.cuentaNombre,
                  numeroCuenta: widget.meta?.numeroCuenta,
                );
                Navigator.pop(context, meta);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorSeleccionado,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
            ),
            child: Text(
              'Guardar Meta',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.isDarkMode;
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required Color color,
  }) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.isDarkMode;
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.openSans(
        color: Colors.grey.shade400,
        fontSize: 12.sp,
      ),
      prefixIcon: Container(
        margin: EdgeInsets.all(10.r),
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Icon(prefixIcon, color: Colors.white, size: 20.sp),
      ),
      filled: true,
      fillColor: isDark ? Colors.grey.shade800 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    );
  }

  IconData _getIconoActual() {
    final iconoData = _iconos.firstWhere(
      (i) => i['name'] == _iconoSeleccionado,
      orElse: () => _iconos[0],
    );
    return iconoData['icon'];
  }
}
