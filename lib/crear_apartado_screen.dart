import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'models/Apartado.dart';
import 'models/Account.dart';
import 'models/Categoria.dart';
import 'data_provider.dart';
import 'services/firestore_service.dart';
import 'widgets/discard_changes_dialog.dart';
import 'widgets/select_amount.dart';
import 'componentes/heads_up_notification.dart';

class CrearApartadoScreen extends StatefulWidget {
  final Apartado? apartado;

  const CrearApartadoScreen({Key? key, this.apartado}) : super(key: key);

  @override
  State<CrearApartadoScreen> createState() => _CrearApartadoScreenState();
}

class _CrearApartadoScreenState extends State<CrearApartadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _montoController;
  late TextEditingController _numeroPagosController;

  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 90));
  String _frecuencia = 'quincenal';
  Color _colorSeleccionado = const Color(0xFF2196F3);
  bool _esRecurrente = false;

  // Datos para la transacción final
  Categoria? _categoriaSeleccionada;
  Account? _cuentaSeleccionada;
  List<Categoria> _categorias = [];
  StreamSubscription<List<Map<String, dynamic>>>? _categoriasSubscription;

  bool _isLoading = false;

  // Fechas de pago programadas
  List<DateTime> _fechasPago = [];
  bool _notificacionesActivas = true;
  bool _fechasGeneradas = false;

  // Variables para detectar cambios
  late String _initialNombre;
  late String _initialDescripcion;
  late String _initialMonto;
  late String _initialNumeroPagos;
  late DateTime _initialFecha;
  late String _initialFrecuencia;
  late Color _initialColor;

  final List<Color> _colores = [
    const Color(0xFF2196F3), // Azul
    const Color(0xFF4CAF50), // Verde
    const Color(0xFFFF9800), // Naranja
    const Color(0xFFE91E63), // Rosa
    const Color(0xFF9C27B0), // Morado
    const Color(0xFFF44336), // Rojo
  ];

  final List<Map<String, String>> _frecuencias = [
    {'value': 'semanal', 'label': 'Semanal'},
    {'value': 'quincenal', 'label': 'Quincenal'},
    {'value': 'mensual', 'label': 'Mensual'},
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.apartado?.nombre ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.apartado?.descripcion ?? '',
    );
    _montoController = TextEditingController(
      text: widget.apartado?.montoTotal.toString() ?? '',
    );
    _numeroPagosController = TextEditingController(
      text: widget.apartado?.numeroPagos.toString() ?? '6',
    );

    if (widget.apartado != null) {
      _colorSeleccionado = Color(
        int.parse('FF${widget.apartado!.color}', radix: 16),
      );
      _fechaLimite = widget.apartado!.fechaLimite;
      _frecuencia = widget.apartado!.frecuencia;
      _esRecurrente = widget.apartado!.esRecurrente;
      _fechasPago = List<DateTime>.from(widget.apartado!.fechasPago);
      _notificacionesActivas = widget.apartado!.notificacionesActivas;
      _fechasGeneradas = _fechasPago.isNotEmpty;
    }

    _loadCategorias();
    _saveInitialState();
  }

  void _loadCategorias() {
    _categoriasSubscription = _firestoreService.obtenerCategorias().listen((
      categoriasData,
    ) {
      if (mounted) {
        setState(() {
          _categorias =
              categoriasData.map((cat) => Categoria.fromJson(cat)).toList();

          // Filtrar solo categorías de pagos
          _categorias =
              _categorias.where((cat) {
                return cat.tipoTransaccion
                    .split(',')
                    .map((e) => e.trim())
                    .any((t) => t == 'Pago' || t == 'Pagos');
              }).toList();

          // Seleccionar categoría del apartado si estamos editando
          if (widget.apartado != null && _categoriaSeleccionada == null) {
            try {
              _categoriaSeleccionada = _categorias.firstWhere(
                (c) => c.categoria == widget.apartado!.categoria,
              );
            } catch (_) {
              if (_categorias.isNotEmpty) {
                _categoriaSeleccionada = _categorias.first;
              }
            }
          }
        });
      }
    });

    // Seleccionar cuenta del apartado si estamos editando
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.apartado != null) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        if (dataProvider.cuentas.isNotEmpty && _cuentaSeleccionada == null) {
          try {
            _cuentaSeleccionada = dataProvider.cuentas.firstWhere(
              (a) => a.id == widget.apartado!.cuentaId,
            );
          } catch (_) {
            _cuentaSeleccionada = dataProvider.cuentas.first;
          }
          if (mounted) setState(() {});
        }
      }
    });
  }

  void _saveInitialState() {
    _initialNombre = _nombreController.text;
    _initialDescripcion = _descripcionController.text;
    _initialMonto = _montoController.text;
    _initialNumeroPagos = _numeroPagosController.text;
    _initialFecha = _fechaLimite;
    _initialFrecuencia = _frecuencia;
    _initialColor = _colorSeleccionado;
  }

  bool _hasChanges() {
    return _nombreController.text != _initialNombre ||
        _descripcionController.text != _initialDescripcion ||
        _montoController.text != _initialMonto ||
        _numeroPagosController.text != _initialNumeroPagos ||
        _fechaLimite != _initialFecha ||
        _frecuencia != _initialFrecuencia ||
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
    _numeroPagosController.dispose();
    _categoriasSubscription?.cancel();
    super.dispose();
  }

  IconData _getIconFromString(String iconString) {
    final codePoint = int.tryParse(iconString);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return Icons.category;
  }

  /// Genera fechas de pago sugeridas basado en frecuencia y número de pagos
  void _generarFechasPago() {
    final pagos = int.tryParse(_numeroPagosController.text) ?? 0;
    if (pagos <= 0) return;

    final List<DateTime> fechas = [];
    DateTime fecha = DateTime.now();

    for (int i = 0; i < pagos; i++) {
      switch (_frecuencia) {
        case 'semanal':
          fecha = fecha.add(const Duration(days: 7));
          break;
        case 'quincenal':
          fecha = fecha.add(const Duration(days: 15));
          break;
        case 'mensual':
          fecha = DateTime(fecha.year, fecha.month + 1, fecha.day);
          break;
      }
      fechas.add(DateTime(fecha.year, fecha.month, fecha.day));
    }

    setState(() {
      _fechasPago = fechas;
      _fechasGeneradas = true;
    });
  }

  /// Permite editar una fecha de pago individual
  Future<void> _editarFechaPago(int index) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechasPago[index],
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            dialogBackgroundColor: theme.colorScheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (fecha != null) {
      setState(() {
        _fechasPago[index] = DateTime(fecha.year, fecha.month, fecha.day);
        // Reordenar por fecha
        _fechasPago.sort((a, b) => a.compareTo(b));
      });
    }
  }

  double get _montoPorPago {
    final monto =
        double.tryParse(_montoController.text.replaceAll(',', '')) ?? 0;
    final pagos = int.tryParse(_numeroPagosController.text) ?? 1;
    if (pagos <= 0 || monto <= 0) return 0;
    return monto / pagos;
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
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subheading: Text(
                            'Toca para seleccionar',
                            style: GoogleFonts.openSans(
                              fontSize: 11.sp,
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
                        Text(
                          'Colores rápidos',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
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
                        style: GoogleFonts.lato(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
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
                        foregroundColor: Colors.white,
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
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoController.text.replaceAll(',', ''));
    if (monto == null || monto <= 0) {
      showErrorNotification(context, message: 'Ingresa un monto válido');
      return;
    }

    final pagos = int.tryParse(_numeroPagosController.text);
    if (pagos == null || pagos <= 0) {
      showErrorNotification(
        context,
        message: 'Ingresa un número de pagos válido',
      );
      return;
    }

    if (_categoriaSeleccionada == null) {
      showErrorNotification(context, message: 'Selecciona una categoría');
      return;
    }

    if (_cuentaSeleccionada == null) {
      showErrorNotification(context, message: 'Selecciona una cuenta');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      DateTime? proximoPago;
      if (widget.apartado == null) {
        // Nuevo: calcular primer pago según frecuencia
        switch (_frecuencia) {
          case 'semanal':
            proximoPago = now.add(const Duration(days: 7));
            break;
          case 'quincenal':
            proximoPago = now.add(const Duration(days: 15));
            break;
          case 'mensual':
            proximoPago = DateTime(now.year, now.month + 1, now.day);
            break;
        }
      }

      // Si hay fechas de pago programadas, usar la primera como proximoPago
      if (widget.apartado == null && _fechasPago.isNotEmpty) {
        proximoPago = _fechasPago.first;
      }

      final apartado = Apartado(
        id: widget.apartado?.id ?? '',
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        icono: _categoriaSeleccionada!.imagen,
        color:
            _colorSeleccionado.value
                .toRadixString(16)
                .substring(2)
                .toUpperCase(),
        montoTotal: monto,
        montoApartado: widget.apartado?.montoApartado ?? 0,
        numeroPagos: pagos,
        pagosRealizados: widget.apartado?.pagosRealizados ?? 0,
        fechaLimite: _fechaLimite,
        fechaProximoPago: widget.apartado?.fechaProximoPago ?? proximoPago,
        frecuencia: _frecuencia,
        estado: widget.apartado?.estado ?? 'activo',
        fechasPago: _fechasPago,
        notificacionesActivas: _notificacionesActivas,
        categoria: _categoriaSeleccionada!.categoria,
        cuentaId: _cuentaSeleccionada!.id,
        cuentaNombre: _cuentaSeleccionada!.nombre,
        esRecurrente: _esRecurrente,
      );

      if (widget.apartado == null) {
        await _firestoreService.crearApartado(apartado);
      } else {
        await _firestoreService.actualizarApartado(apartado);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorNotification(
          context,
          message: 'Error al guardar',
          subtitle: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSeleccionado = _colorSeleccionado;
    final dataProvider = Provider.of<DataProvider>(context);

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
        backgroundColor: theme.colorScheme.background,
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
            widget.apartado == null ? 'Nuevo Apartado' : 'Editar Apartado',
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
                    'Reserva dinero para un gasto planeado',
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
                      // ── Nombre ──
                      _buildSectionTitle('Nombre del apartado', theme),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: _buildInputDecoration(
                          hintText: 'Ej: Seguro del auto, Renta, Internet',
                          prefixIcon: Icons.label_outline,
                          color: colorSeleccionado,
                          theme: theme,
                        ),
                        validator:
                            (v) =>
                                v?.trim().isEmpty == true
                                    ? 'Campo requerido'
                                    : null,
                      ),
                      SizedBox(height: 16.h),

                      // ── Descripción ──
                      _buildSectionTitle('Descripción (opcional)', theme),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _descripcionController,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: _buildInputDecoration(
                          hintText: 'Detalles adicionales',
                          prefixIcon: Icons.description_outlined,
                          color: colorSeleccionado,
                          theme: theme,
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 16.h),

                      // ── Monto total ──
                      _buildSectionTitle('Monto total a apartar', theme),
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
                            title: 'Monto total del apartado',
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

                      // ── Número de pagos + Frecuencia ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Número de pagos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Nº de pagos', theme),
                                SizedBox(height: 8.h),
                                TextFormField(
                                  controller: _numeroPagosController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: 'Ej: 6',
                                    prefixIcon: Icons.repeat_rounded,
                                    color: colorSeleccionado,
                                    theme: theme,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v?.isEmpty == true) return 'Requerido';
                                    final n = int.tryParse(v!);
                                    if (n == null || n <= 0) return 'Inválido';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Frecuencia
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Frecuencia', theme),
                                SizedBox(height: 8.h),
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: theme.colorScheme.surface,
                                    value: _frecuencia,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 14.h,
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: theme.colorScheme.onSurface,
                                      size: 20.sp,
                                    ),
                                    isExpanded: true,
                                    onChanged: (v) {
                                      if (v != null)
                                        setState(() => _frecuencia = v);
                                    },
                                    items:
                                        _frecuencias.map((f) {
                                          return DropdownMenuItem<String>(
                                            value: f['value'],
                                            child: Text(
                                              f['label']!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ── Preview monto por pago ──
                      if (_montoPorPago > 0) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: colorSeleccionado.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: colorSeleccionado.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18.sp,
                                color: colorSeleccionado,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.lato(
                                      fontSize: 13.sp,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.8),
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Cada abono será de ',
                                      ),
                                      TextSpan(
                                        text: NumberFormat.currency(
                                          locale: 'es_MX',
                                          symbol: '\$',
                                          decimalDigits: 2,
                                        ).format(_montoPorPago),
                                        style: GoogleFonts.lato(
                                          fontWeight: FontWeight.bold,
                                          color: colorSeleccionado,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),

                      // ── Recurrente ──
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              size: 20.sp,
                              color:
                                  _esRecurrente
                                      ? colorSeleccionado
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recurrente',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Al pagar, se creará uno nuevo automáticamente',
                                    style: GoogleFonts.lato(
                                      fontSize: 11.sp,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _esRecurrente,
                              activeColor: colorSeleccionado,
                              onChanged:
                                  (v) => setState(() => _esRecurrente = v),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ── Fechas de pago programadas ──
                      _buildSectionTitle('Fechas de pago', theme),
                      SizedBox(height: 8.h),
                      if (!_fechasGeneradas || _fechasPago.isEmpty) ...[
                        // Botón para generar fechas
                        InkWell(
                          onTap: () {
                            final pagos =
                                int.tryParse(_numeroPagosController.text) ?? 0;
                            if (pagos <= 0) {
                              showErrorNotification(
                                context,
                                message: 'Ingresa el número de pagos primero',
                              );
                              return;
                            }
                            _generarFechasPago();
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: colorSeleccionado.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_fix_high_rounded,
                                  color: colorSeleccionado,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Generar fechas automáticamente',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: colorSeleccionado,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Lista de fechas generadas
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: theme.colorScheme.secondary.withOpacity(
                                0.15,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Header con botón regenerar
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.event_note_rounded,
                                      color: colorSeleccionado,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        '${_fechasPago.length} pagos programados',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _generarFechasPago,
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        size: 16.sp,
                                      ),
                                      label: Text(
                                        'Regenerar',
                                        style: GoogleFonts.lato(
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: colorSeleccionado,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.1,
                                ),
                              ),
                              // Lista de fechas
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _fechasPago.length,
                                separatorBuilder:
                                    (_, __) => Divider(
                                      height: 1,
                                      indent: 48.w,
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.08),
                                    ),
                                itemBuilder: (context, index) {
                                  final fecha = _fechasPago[index];
                                  final esPasada = fecha.isBefore(
                                    DateTime.now(),
                                  );
                                  return InkWell(
                                    onTap: () => _editarFechaPago(index),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 10.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28.w,
                                            height: 28.h,
                                            decoration: BoxDecoration(
                                              color: (esPasada
                                                      ? Colors.orange
                                                      : colorSeleccionado)
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.lato(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    esPasada
                                                        ? Colors.orange
                                                        : colorSeleccionado,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Text(
                                              DateFormat(
                                                "EEEE d 'de' MMMM, yyyy",
                                                'es',
                                              ).format(fecha),
                                              style: GoogleFonts.lato(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.edit_calendar_rounded,
                                            size: 18.sp,
                                            color: theme.colorScheme.secondary
                                                .withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 12.h),

                      // ── Toggle notificaciones ──
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 20.sp,
                              color:
                                  _notificacionesActivas
                                      ? colorSeleccionado
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recordatorios de pago',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Notificación el día anterior y el día de pago',
                                    style: GoogleFonts.lato(
                                      fontSize: 11.sp,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _notificacionesActivas,
                              activeColor: colorSeleccionado,
                              onChanged:
                                  (v) => setState(
                                    () => _notificacionesActivas = v,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ── Fecha límite ──
                      _buildSectionTitle('Fecha límite', theme),
                      SizedBox(height: 8.h),
                      InkWell(
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaLimite,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
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
                            setState(() => _fechaLimite = fecha);
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
                                ).format(_fechaLimite),
                                style: GoogleFonts.lato(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
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

                      // ── Divider: Datos de transacción ──
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              'Al completar, se registrará como gasto',
                              style: GoogleFonts.lato(
                                fontSize: 11.sp,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // ── Categoría ──
                      _buildCategorySelector(theme),
                      SizedBox(height: 16.h),

                      // ── Cuenta ──
                      _buildAccountSelector(theme, dataProvider.cuentas),
                      SizedBox(height: 20.h),

                      // ── Selector de color ──
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
                                  style: GoogleFonts.lato(
                                    fontSize: 13.sp,
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
            onPressed: _isLoading ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorSeleccionado,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child:
                _isLoading
                    ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      widget.apartado == null
                          ? 'Crear Apartado'
                          : 'Guardar Cambios',
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

  // ── Selector de categoría ──
  Widget _buildCategorySelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Categoría del gasto', theme),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<Categoria>(
            dropdownColor: theme.colorScheme.surface,
            value:
                _categorias.contains(_categoriaSeleccionada)
                    ? _categoriaSeleccionada
                    : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
            hint: Text(
              'Selecciona una categoría',
              style: GoogleFonts.poppins(
                color: theme.colorScheme.secondary.withOpacity(0.5),
                fontSize: 12.sp,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurface,
              size: 20.sp,
            ),
            isExpanded: true,
            onChanged: (v) => setState(() => _categoriaSeleccionada = v),
            items:
                _categorias.map((category) {
                  return DropdownMenuItem<Categoria>(
                    value: category,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            _getIconFromString(category.imagen),
                            size: 14.sp,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: Text(
                            category.categoria,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Selector de cuenta ──
  Widget _buildAccountSelector(ThemeData theme, List<Account> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cuenta de pago', theme),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<Account>(
            dropdownColor: theme.colorScheme.surface,
            value:
                accounts.contains(_cuentaSeleccionada)
                    ? _cuentaSeleccionada
                    : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            hint: Text(
              'Selecciona una cuenta',
              style: GoogleFonts.poppins(
                color: theme.colorScheme.secondary.withOpacity(0.5),
                fontSize: 12.sp,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurface,
              size: 20.sp,
            ),
            isExpanded: true,
            onChanged: (v) => setState(() => _cuentaSeleccionada = v),
            items:
                accounts.map((account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: Image.asset(
                              'assets/images/${account.imagen}.png',
                              width: 20.w,
                              height: 20.h,
                              color: theme.colorScheme.primary,
                              colorBlendMode: BlendMode.srcIn,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.account_balance_wallet,
                                  color: theme.colorScheme.primary,
                                  size: 20.sp,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: Text(
                            account.nombre,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
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
    if (_categoriaSeleccionada != null) {
      final codePoint = int.tryParse(_categoriaSeleccionada!.imagen);
      if (codePoint != null) {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
    }
    return Icons.account_balance_wallet;
  }
}
