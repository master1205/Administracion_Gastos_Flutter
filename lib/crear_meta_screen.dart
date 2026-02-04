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
    final theme = Theme.of(context);
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
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.meta == null ? 'Nueva Meta' : 'Editar Meta',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
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
                color: colorSeleccionado.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: colorSeleccionado.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: colorSeleccionado.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconoActual(),
                      color: colorSeleccionado,
                      size: 40.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Define tu objetivo de ahorro',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.secondary.withOpacity(0.7),
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
                      _buildSectionTitle('Nombre de la meta', theme),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: _buildInputDecoration(
                          hintText: 'Ej: Casa nueva, Auto, Vacaciones',
                          prefixIcon: Icons.label_outline,
                          color: colorSeleccionado,
                          theme: theme,
                        ),
                        validator:
                            (v) =>
                                v?.isEmpty == true ? 'Campo requerido' : null,
                      ),
                      SizedBox(height: 16.h),

                      // Descripción
                      _buildSectionTitle('Descripción (opcional)', theme),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _descripcionController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: _buildInputDecoration(
                          hintText: 'Añade más detalles sobre tu meta',
                          prefixIcon: Icons.description_outlined,
                          color: colorSeleccionado,
                          theme: theme,
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 16.h),

                      // Monto objetivo
                      _buildSectionTitle('Monto objetivo', theme),
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
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: theme.colorScheme.secondary.withOpacity(
                                0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: colorSeleccionado.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.attach_money,
                                  color: colorSeleccionado,
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
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.secondary
                                                .withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Fecha objetivo
                      _buildSectionTitle('Fecha objetivo', theme),
                      SizedBox(height: 8.h),
                      InkWell(
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaObjetivo,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 3650)),
                            builder: (context, child) {
                              final theme = Theme.of(context);
                              return Theme(
                                data: theme.copyWith(
                                  dialogBackgroundColor:
                                      theme.colorScheme.surface,
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
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: theme.colorScheme.secondary.withOpacity(
                                0.2,
                              ),
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
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_drop_down,
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Selector de ícono
                      _buildSectionTitle('Ícono', theme),
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
                                            : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color:
                                          seleccionado
                                              ? colorSeleccionado.withOpacity(
                                                0.3,
                                              )
                                              : theme.colorScheme.secondary
                                                  .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    icono['icon'],
                                    size: 28.sp,
                                    color:
                                        seleccionado
                                            ? colorSeleccionado
                                            : theme.colorScheme.secondary
                                                .withOpacity(0.6),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      SizedBox(height: 20.h),

                      // Selector de color
                      _buildSectionTitle('Color', theme),
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
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.secondary
                                                  .withOpacity(0.3),
                                      width: seleccionado ? 3 : 1,
                                    ),
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
              elevation: 0,
            ),
            child: Text(
              'Guardar Meta',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.secondary.withOpacity(0.7),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required Color color,
    required ThemeData theme,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.openSans(
        color: theme.colorScheme.secondary.withOpacity(0.5),
        fontSize: 12.sp,
      ),
      prefixIcon: Container(
        margin: EdgeInsets.all(10.r),
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(prefixIcon, color: color, size: 20.sp),
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: theme.colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: theme.colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color, width: 1.5),
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
