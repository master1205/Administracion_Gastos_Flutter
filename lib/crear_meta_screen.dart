import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:intl/intl.dart';
import 'componentes/heads_up_notification.dart';
import 'models/Meta.dart';
import 'widgets/discard_changes_dialog.dart';
import 'widgets/select_amount.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

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
  Color _colorSeleccionado = const Color(0xFF4CAF50);

  // Variables para detectar cambios
  late String _initialNombre;
  late String _initialDescripcion;
  late String _initialMonto;
  late DateTime _initialFecha;
  late String _initialIcono;
  late Color _initialColor;

  final List<Map<String, dynamic>> _iconos = [
    {'icon': Icons.savings, 'name': 'savings', 'label': 'Ahorro'},
    {'icon': Icons.home, 'name': 'home', 'label': 'Casa'},
    {'icon': Icons.directions_car, 'name': 'car', 'label': 'Auto'},
    {'icon': Icons.flight, 'name': 'travel', 'label': 'Viaje'},
    {'icon': Icons.school, 'name': 'education', 'label': 'Educación'},
    {'icon': Icons.local_hospital, 'name': 'emergency', 'label': 'Emergencia'},
    {'icon': Icons.card_giftcard, 'name': 'gift', 'label': 'Regalo'},
  ];

  final List<Color> _colores = [
    const Color(0xFF4CAF50), // Verde
    const Color(0xFF2196F3), // Azul
    const Color(0xFFFF9800), // Naranja
    const Color(0xFFE91E63), // Rosa
    const Color(0xFF9C27B0), // Morado
    const Color(0xFFF44336), // Rojo
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
      _colorSeleccionado = Color(
        int.parse('FF${widget.meta!.color}', radix: 16),
      );
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

  void _showColorPicker(BuildContext context, ThemeData theme) {
    Color tempColor = _colorSeleccionado;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  title: Text(
                    'Seleccionar color',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Selector de color completo
                        ColorPicker(
                          color: tempColor,
                          onColorChanged: (Color color) {
                            setState(() {
                              tempColor = color;
                            });
                          },
                          width: 40.w,
                          height: 40.h,
                          borderRadius: 8.r,
                          spacing: 5,
                          runSpacing: 5,
                          wheelDiameter: 200.w,
                          heading: Text(
                            'Selector de color',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subheading: Text(
                            'Toca para seleccionar',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          pickersEnabled: const <ColorPickerType, bool>{
                            ColorPickerType.both: false,
                            ColorPickerType.primary: true,
                            ColorPickerType.accent: true,
                            ColorPickerType.bw: false,
                            ColorPickerType.custom: false,
                            ColorPickerType.wheel: true,
                          },
                          enableShadesSelection: true,
                          showColorCode: true,
                          colorCodeHasColor: true,
                          showColorName: false,
                          showMaterialName: false,
                          enableOpacity: false,
                          enableTonalPalette: true,
                        ),
                        SizedBox(height: 16.h),
                        Divider(
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                        SizedBox(height: 8.h),
                        // Colores rápidos
                        Text(
                          'Colores rápidos',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.maxFinite,
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            alignment: WrapAlignment.center,
                            children:
                                _colores.map((color) {
                                  final isSelected = color == tempColor;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        tempColor = color;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Container(
                                      width: 44.w,
                                      height: 44.h,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: Colors.white,
                                                  width: 3.w,
                                                )
                                                : null,
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: color.withOpacity(
                                                      0.5,
                                                    ),
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
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        this.setState(() {
                          _colorSeleccionado = tempColor;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tempColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                      ),
                      child: Text(
                        'Aplicar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSeleccionado = _colorSeleccionado;

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
        backgroundColor: theme.colorScheme.surface,
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
            style: theme.textTheme.titleLarge?.copyWith(
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
                    style: theme.textTheme.labelMedium?.copyWith(
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
                                  style: theme.textTheme.bodyLarge?.copyWith(
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
                                style: theme.textTheme.bodyMedium?.copyWith(
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
                      InkWell(
                        onTap: () => _showColorPicker(context, theme),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.1,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  color: _colorSeleccionado,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  'Toca para seleccionar color',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 20.sp,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (_montoController.text.isEmpty ||
                                  double.tryParse(
                                        _montoController.text.replaceAll(
                                          ',',
                                          '',
                                        ),
                                      ) ==
                                      0) {
                                showErrorNotification(
                                  context,
                                  message:
                                      'Por favor ingresa un monto objetivo',
                                );
                                return;
                              }

                              final cleanMonto = _montoController.text
                                  .replaceAll(',', '');
                              final meta = Meta(
                                id:
                                    widget.meta?.id ??
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                nombre: _nombreController.text,
                                descripcion: _descripcionController.text,
                                montoObjetivo: double.parse(cleanMonto),
                                montoActual: widget.meta?.montoActual ?? 0,
                                fechaInicio:
                                    widget.meta?.fechaInicio ??
                                    DateTime.now().toIso8601String(),
                                fechaObjetivo: _fechaObjetivo.toIso8601String(),
                                icono: _iconoSeleccionado,
                                color:
                                    _colorSeleccionado.value
                                        .toRadixString(16)
                                        .substring(2)
                                        .toUpperCase(),
                                completada: widget.meta?.completada ?? false,
                                cuentaId: widget.meta?.cuentaId,
                                cuentaNombre: widget.meta?.cuentaNombre,
                                numeroCuenta: widget.meta?.numeroCuenta,
                              );
                              Navigator.pop(context, meta);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            foregroundColor:
                                theme.colorScheme.onSecondaryContainer,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Guardar Meta',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
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
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.secondary.withOpacity(0.5),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color, width: 2),
      ),
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
