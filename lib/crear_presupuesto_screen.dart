import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/models/Budget.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/widgets/animations.dart';
import 'package:notificaciones/widgets/discard_changes_dialog.dart';
import 'package:notificaciones/widgets/select_amount.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:notificaciones/componentes/heads_up_notification.dart';
import 'package:provider/provider.dart';
import 'utils/haptic_utils.dart';

class CrearPresupuestoScreen extends StatefulWidget {
  final Budget? presupuesto;

  const CrearPresupuestoScreen({Key? key, this.presupuesto}) : super(key: key);

  @override
  State<CrearPresupuestoScreen> createState() => _CrearPresupuestoScreenState();
}

class _CrearPresupuestoScreenState extends State<CrearPresupuestoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nombreController;
  late TextEditingController _montoController;

  String _periodo = 'semanal'; // 'semanal' | 'mensual'
  bool _aplicaTodasCategorias = true;
  List<String> _categoriasSeleccionadas = [];
  bool _esRecurrente = true;
  bool _alertaActiva = true;
  double _porcentajeAlerta = 80.0;
  Color _colorSeleccionado = const Color(0xFF4CAF50);

  bool _isLoading = false;

  // Colores rápidos disponibles
  final List<Color> _colores = [
    const Color(0xFF4CAF50), // Verde
    const Color(0xFF2196F3), // Azul
    const Color(0xFFFF9800), // Naranja
    const Color(0xFFE91E63), // Rosa
    const Color(0xFF9C27B0), // Morado
    const Color(0xFFF44336), // Rojo
  ];

  // Categorías dinámicas desde DataProvider
  List<String> _categoriasDisponibles = [];

  // Variables para detectar cambios
  late String _initialNombre;
  late String _initialMonto;
  late String _initialPeriodo;
  late bool _initialAplicaTodasCategorias;
  late List<String> _initialCategoriasSeleccionadas;
  late bool _initialEsRecurrente;
  late bool _initialAlertaActiva;
  late double _initialPorcentajeAlerta;
  late Color _initialColorSeleccionado;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _montoController = TextEditingController();

    if (widget.presupuesto != null) {
      _loadPresupuesto();
    }

    _cargarCategorias();
    _saveInitialState();
  }

  void _saveInitialState() {
    _initialNombre = _nombreController.text;
    _initialMonto = _montoController.text;
    _initialPeriodo = _periodo;
    _initialAplicaTodasCategorias = _aplicaTodasCategorias;
    _initialCategoriasSeleccionadas = List.from(_categoriasSeleccionadas);
    _initialEsRecurrente = _esRecurrente;
    _initialAlertaActiva = _alertaActiva;
    _initialPorcentajeAlerta = _porcentajeAlerta;
    _initialColorSeleccionado = _colorSeleccionado;
  }

  bool _hasChanges() {
    return _nombreController.text != _initialNombre ||
        _montoController.text != _initialMonto ||
        _periodo != _initialPeriodo ||
        _aplicaTodasCategorias != _initialAplicaTodasCategorias ||
        _categoriasSeleccionadas.length !=
            _initialCategoriasSeleccionadas.length ||
        !_categoriasSeleccionadas.every(
          (cat) => _initialCategoriasSeleccionadas.contains(cat),
        ) ||
        _esRecurrente != _initialEsRecurrente ||
        _alertaActiva != _initialAlertaActiva ||
        _porcentajeAlerta != _initialPorcentajeAlerta ||
        _colorSeleccionado != _initialColorSeleccionado;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges()) {
      return await DiscardChangesDialog.show(context);
    }
    return true;
  }

  void _loadPresupuesto() {
    final p = widget.presupuesto!;
    _nombreController.text = p.nombre;
    _montoController.text = p.montoLimite.toStringAsFixed(2);
    _periodo = p.periodo;
    _aplicaTodasCategorias = p.aplicaTodasCategorias;
    _categoriasSeleccionadas = List.from(p.categorias);
    _esRecurrente = p.esRecurrente;
    _alertaActiva = p.alertaActiva;
    _porcentajeAlerta = p.porcentajeAlerta;

    // Cargar color si existe
    if (p.colorAsignado != null) {
      _colorSeleccionado = Color(p.colorAsignado!);
    }
  }

  Future<void> _cargarCategorias() async {
    final dp = Provider.of<DataProvider>(context, listen: false);
    final categoriasData = dp.categorias;

    setState(() {
      _categoriasDisponibles =
          categoriasData
              .map((cat) => Categoria.fromJson(cat))
              .where((categoria) {
                final tipo = categoria.tipoTransaccion.toLowerCase();
                return tipo == 'gastos' ||
                    tipo == 'gasto' ||
                    tipo == 'pagos' ||
                    tipo == 'pago';
              })
              .map((cat) => cat.categoria)
              .toList();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
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
    final isEditing = widget.presupuesto != null;

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
            isEditing ? 'Editar Presupuesto' : 'Nuevo Presupuesto',
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
                color: theme.colorScheme.primary.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.primary,
                      size: 40.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Controla tus gastos estableciendo límites',
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
                  bottom: 100.r + MediaQuery.of(context).padding.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contenido del formulario aquí
                      _buildFormContent(theme, isEditing),
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

  Widget _buildFormContent(ThemeData theme, bool isEditing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre
        _buildSectionTitle('Nombre del presupuesto', theme),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _nombreController,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: _buildInputDecoration(
            hintText: 'Ej: Gastos de comida',
            prefixIcon: Icons.label_rounded,
            theme: theme,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa un nombre';
            }
            return null;
          },
        ),

        SizedBox(height: 20.h),

        // Monto límite
        _buildSectionTitle('Monto límite', theme),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () async {
            final currentAmount =
                _montoController.text.isNotEmpty
                    ? double.tryParse(
                          _montoController.text.replaceAll(',', ''),
                        ) ??
                        0.0
                    : 0.0;

            final result = await showSelectAmountBottomSheet(
              context,
              title: 'Ingresa el monto límite',
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
                color: theme.colorScheme.secondary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: theme.colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monto límite',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _montoController.text.isEmpty ||
                                _montoController.text == '0.00'
                            ? '\$0.00'
                            : '\$${double.parse(_montoController.text).toStringAsFixed(2)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.secondary.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // Período
        Text(
          'Período',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildPeriodoOption(
                title: 'Semanal',
                subtitle: 'Domingo - Sábado',
                icon: Icons.calendar_view_week_rounded,
                selected: _periodo == 'semanal',
                onTap: () => setState(() => _periodo = 'semanal'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildPeriodoOption(
                title: 'Mensual',
                subtitle: 'Día 1 - Último día',
                icon: Icons.calendar_month_rounded,
                selected: _periodo == 'mensual',
                onTap: () => setState(() => _periodo = 'mensual'),
              ),
            ),
          ],
        ),

        SizedBox(height: 24.h),

        // Categorías
        Text(
          'Categorías',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 12.h),

        // Switch todas las categorías
        MorphingContainer(
          padding: EdgeInsets.all(16.r),
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          child: Row(
            children: [
              Icon(
                Icons.category_rounded,
                color: theme.colorScheme.primary,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Aplicar a todas las categorías',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _aplicaTodasCategorias,
                activeColor: theme.colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _aplicaTodasCategorias = value;
                    if (value) {
                      _categoriasSeleccionadas.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ),

        // Selector de categorías específicas
        if (!_aplicaTodasCategorias) ...[
          SizedBox(height: 12.h),
          MorphingContainer(
            padding: EdgeInsets.all(16.r),
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona categorías',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children:
                      _categoriasDisponibles.map((categoria) {
                        final isSelected = _categoriasSeleccionadas.contains(
                          categoria,
                        );
                        return AnimatedFilterChip(
                          label: categoria,
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _categoriasSeleccionadas.add(categoria);
                              } else {
                                _categoriasSeleccionadas.remove(categoria);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
                if (_categoriasSeleccionadas.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Selecciona al menos una categoría',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],

        SizedBox(height: 24.h),

        // Selector de color
        MorphingContainer(
          padding: EdgeInsets.zero,
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            leading: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: _colorSeleccionado,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
            title: Text(
              'Color del presupuesto',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Toca para seleccionar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            onTap: () => _showColorPicker(context, theme),
          ),
        ),

        SizedBox(height: 24.h),

        // Configuración avanzada
        Text(
          'Configuración',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 12.h),

        // Recurrente
        _buildSwitchTile(
          icon: Icons.sync_rounded,
          title: 'Presupuesto recurrente',
          subtitle: 'Se renovará automáticamente',
          value: _esRecurrente,
          onChanged: (value) => setState(() => _esRecurrente = value),
        ),

        SizedBox(height: 12.h),

        // Alerta
        _buildSwitchTile(
          icon: Icons.notifications_active_rounded,
          title: 'Activar alertas',
          subtitle: 'Recibe notificaciones al alcanzar el límite',
          value: _alertaActiva,
          onChanged: (value) => setState(() => _alertaActiva = value),
        ),

        // Porcentaje de alerta
        if (_alertaActiva) ...[
          SizedBox(height: 16.h),
          MorphingContainer(
            padding: EdgeInsets.all(16.r),
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alertar al alcanzar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${_porcentajeAlerta.toInt()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Slider(
                  value: _porcentajeAlerta,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  label: '${_porcentajeAlerta.toInt()}%',
                  onChanged:
                      (value) => setState(() => _porcentajeAlerta = value),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 32.h),

        // Botón guardar
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: FilledButton.tonal(
            onPressed: _isLoading ? null : _guardarPresupuesto,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              disabledBackgroundColor: theme.colorScheme.secondaryContainer
                  .withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child:
                _isLoading
                    ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5.w,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          isEditing
                              ? 'Actualizar Presupuesto'
                              : 'Crear Presupuesto',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required ThemeData theme,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.4)),
      prefixIcon: Container(
        margin: EdgeInsets.all(8.r),
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(prefixIcon, color: theme.colorScheme.primary, size: 20.sp),
      ),
    );
  }

  Widget _buildPeriodoOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color =
        selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.4);

    return BounceTapButton(
      onTap: onTap,
      child: MorphingContainer(
        padding: EdgeInsets.all(16.r),
        color:
            selected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        borderColor: selected ? theme.colorScheme.primary : Colors.transparent,
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return MorphingContainer(
      padding: EdgeInsets.all(16.r),
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: theme.colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _guardarPresupuesto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Haptics.medium();

    // Validar monto manualmente
    if (_montoController.text.isEmpty || _montoController.text == '0.00') {
      showErrorNotification(
        context,
        message: 'Por favor ingresa un monto límite',
      );
      return;
    }

    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      showErrorNotification(context, message: 'El monto debe ser mayor a cero');
      return;
    }

    if (!_aplicaTodasCategorias && _categoriasSeleccionadas.isEmpty) {
      showErrorNotification(
        context,
        message: 'Selecciona al menos una categoría',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convertir color seleccionado a int
      final colorInt = _colorSeleccionado.value;

      if (widget.presupuesto != null) {
        // Actualizar presupuesto existente
        await _firestoreService.actualizarPresupuesto(
          presupuestoId: widget.presupuesto!.id,
          nombre: _nombreController.text.trim(),
          montoLimite: monto,
          periodo: _periodo,
          categorias: _aplicaTodasCategorias ? [] : _categoriasSeleccionadas,
          esRecurrente: _esRecurrente,
          alertaActiva: _alertaActiva,
          porcentajeAlerta: _porcentajeAlerta,
          colorAsignado: colorInt,
        );

        if (mounted) {
          showSuccessNotification(context, message: 'Presupuesto actualizado');
          Navigator.pop(context);
        }
      } else {
        // Crear nuevo presupuesto
        await _firestoreService.crearPresupuesto(
          nombre: _nombreController.text.trim(),
          montoLimite: monto,
          periodo: _periodo,
          categorias: _aplicaTodasCategorias ? [] : _categoriasSeleccionadas,
          esRecurrente: _esRecurrente,
          alertaActiva: _alertaActiva,
          porcentajeAlerta: _porcentajeAlerta,
          colorAsignado: colorInt,
        );

        if (mounted) {
          showSuccessNotification(context, message: 'Presupuesto creado');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorNotification(
          context,
          message: 'Error al guardar',
          subtitle: '$e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
