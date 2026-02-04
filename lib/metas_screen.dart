import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notificaciones/widgets/confirmation_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'models/Meta.dart';
import 'models/Account.dart';
import 'models/api_response.dart';
import 'theme_provider.dart';
import 'services/firestore_service.dart';
import 'widgets/select_amount.dart';
import 'widgets/discard_changes_dialog.dart';
import 'widgets/animations.dart';
import 'crear_meta_screen.dart';
import 'widgets/shimmer_loading.dart';
import 'componentes/heads_up_notification.dart';

class MetasScreen extends StatefulWidget {
  final Color? headerColor;

  const MetasScreen({Key? key, this.headerColor}) : super(key: key);

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  final ValueNotifier<List<Meta>> _metasNotifier = ValueNotifier<List<Meta>>(
    [],
  );
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  bool _isManualRefresh = false;
  List<Account> cuentas = [];
  StreamSubscription<List<Meta>>? _metasSubscription;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _metasSubscription?.cancel();
    _metasNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    _isLoadingNotifier.value = true;

    // Configurar el Stream de Firebase
    _metasSubscription?.cancel();
    _metasSubscription = _firestoreService.obtenerMetas().listen((metas) {
      if (mounted) {
        _metasNotifier.value = metas;
        _isLoadingNotifier.value = false;
        if (_isManualRefresh) {
          setState(() => _isManualRefresh = false);
        }
      }
    });
  }

  Future<void> refreshData() async {
    setState(() => _isManualRefresh = true);
    // El Stream se actualizará automáticamente
  }

  Future<void> _crearMeta() async {
    final resultado = await Navigator.push<Meta>(
      context,
      MaterialPageRoute(builder: (context) => CrearMetaScreen()),
    );

    if (resultado != null) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => PopScope(
              canPop: false,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(
                          'Creando cuenta y meta...',
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      );

      try {
        final apiService = ApiService();

        // 1. Crear cuenta de ahorro asociada
        final cuentaId = await apiService.crearCuenta(
          nombre: 'Ahorro ${resultado.nombre}',
          imagen: "ahorro",
          beneficiario: 'Meta de ahorro',
          saldoInicial: resultado.montoActual,
        );

        if (cuentaId.isEmpty) {
          throw ApiException('No se pudo crear la cuenta');
        }

        // 2. Crear meta con la cuenta asociada
        final metaConCuenta = resultado.copyWith(cuentaId: cuentaId);
        await apiService.saveMeta(metaConCuenta);

        // Firebase Stream actualizará automáticamente la lista

        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          showSuccessNotification(
            context,
            message: 'Meta creada exitosamente',
            subtitle: '1 meta',
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          showErrorNotification(
            context,
            message: 'Error al crear meta',
            subtitle: e.message,
          );
        }
      }
    }
  }

  Future<void> _editarMeta(int index) async {
    final resultado = await Navigator.push<Meta>(
      context,
      MaterialPageRoute(
        builder:
            (context) => CrearMetaScreen(meta: _metasNotifier.value[index]),
      ),
    );

    if (resultado != null) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => PopScope(
              canPop: false,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(
                          'Guardando cambios...',
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      );

      try {
        final apiService = ApiService();
        await apiService.saveMeta(resultado);

        // Firebase Stream actualizará automáticamente la lista

        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          showSuccessNotification(
            context,
            message: 'Meta actualizada',
            subtitle: '1 meta',
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          showErrorNotification(
            context,
            message: 'Error al actualizar meta',
            subtitle: e.message,
          );
        }
      }
    }
  }

  Future<void> _eliminarMeta(int index) async {
    final confirmar = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar meta?',
      message:
          'Se eliminará "${_metasNotifier.value[index].nombre}" y su cuenta de ahorro asociada. Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      confirmColor: Colors.red.shade400,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmar == true) {
      // Mostrar indicador de carga
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(
                          'Eliminando meta y cuenta...',
                          style: GoogleFonts.openSans(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        );
      }

      try {
        final apiService = ApiService();
        await apiService.deleteMeta(_metasNotifier.value[index].id);

        // Firebase Stream actualizará automáticamente la lista

        // Cerrar diálogo de carga
        if (mounted) Navigator.pop(context);

        if (mounted) {
          showSuccessNotification(
            context,
            message: 'Meta eliminada',
            subtitle: '1 meta',
          );
        }
      } on ApiException catch (e) {
        // Cerrar diálogo de carga
        if (mounted) Navigator.pop(context);

        if (mounted) {
          showErrorNotification(
            context,
            message: 'Error al eliminar meta',
            subtitle: e.message,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            size: 22.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Metas',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, child) {
              if (isLoading) {
                return ShimmerList(
                  shimmerItem: MetaCardShimmer(),
                  itemCount: 3,
                );
              }

              return ValueListenableBuilder<List<Meta>>(
                valueListenable: _metasNotifier,
                builder: (context, metas, child) {
                  if (metas.isEmpty) {
                    return _buildEmptyState(themeManager);
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16.r,
                      right: 16.r,
                      top: 16.r,
                      bottom:
                          16.r + MediaQuery.of(context).padding.bottom + 80.h,
                    ),
                    itemCount: metas.length,
                    itemBuilder: (context, index) {
                      return FadeIn(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: _buildMetaCard(
                          metas[index],
                          index,
                          themeManager,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          // Indicador sutil de recarga (solo refresh manual)
          if (_isManualRefresh)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Container(
                      height: 3.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667eea).withOpacity(0.0),
                            const Color(0xFF667eea),
                            const Color(0xFF764ba2),
                            const Color(0xFF764ba2).withOpacity(0.0),
                          ],
                        ),
                      ),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: AnimateFABDelayed(
        fab: FloatingActionButton(
          onPressed: _crearMeta,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                color: theme.colorScheme.primary,
                size: 26.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeManager themeManager) {
    final theme = Theme.of(context);
    return Center(
      child: SlideFadeTransition(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleIn(
                child: Container(
                  padding: EdgeInsets.all(28.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    size: 64.sp,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                'Sin metas',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Crea tu primera meta de ahorro\ny empieza a cumplir tus sueños',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: theme.colorScheme.secondary.withOpacity(0.6),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaCard(Meta meta, int index, ThemeManager themeManager) {
    final theme = Theme.of(context);
    final colorHex = int.parse('FF${meta.color}', radix: 16);
    final color = Color(colorHex);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header sin gradiente
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        _getIconData(meta.icono),
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
                            meta.nombre,
                            style: GoogleFonts.poppins(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (meta.descripcion.isNotEmpty)
                            Text(
                              meta.descripcion,
                              style: GoogleFonts.poppins(
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.7,
                                ),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: meta.progreso / 100,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6.h,
                  ),
                ),
                SizedBox(height: 10.h),
                // Montos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${NumberFormat('#,##0.00', 'es').format(meta.montoActual)} / \$${NumberFormat('#,##0.00', 'es').format(meta.montoObjetivo)}',
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.secondary.withOpacity(0.8),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${meta.progreso.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Información y botones
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                // Chips de fecha inline
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withOpacity(
                              0.15,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13.sp,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.6,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Inicio',
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.5,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _formatDate(meta.fechaInicio),
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withOpacity(
                              0.15,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 13.sp,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.6,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Objetivo',
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.5,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _formatDate(meta.fechaObjetivo),
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (meta.diasRestantes > 0) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 14.sp,
                          color: const Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${meta.diasRestantes} días restantes',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                // Botones minimalistas
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _editarMeta(index),
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        child: Icon(
                          Icons.edit_outlined,
                          color: theme.colorScheme.secondary.withOpacity(0.6),
                          size: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    InkWell(
                      onTap: () => _eliminarMeta(index),
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: const Color(0xFFEF4444).withOpacity(0.7),
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'car':
        return Icons.directions_car;
      case 'travel':
        return Icons.flight;
      case 'education':
        return Icons.school;
      case 'emergency':
        return Icons.local_hospital;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.savings;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

// Dialog para crear/editar meta
class _CrearMetaDialog extends StatefulWidget {
  const _CrearMetaDialog();

  @override
  State<_CrearMetaDialog> createState() => _CrearMetaDialogState();
}

class _CrearMetaDialogState extends State<_CrearMetaDialog> {
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
    _nombreController = TextEditingController(text: '');
    _descripcionController = TextEditingController(text: '');
    _montoController = TextEditingController(text: '');

    // Guardar estado inicial
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
      child: Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom > 0
                  ? MediaQuery.of(context).viewInsets.bottom
                  : MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              // Header simple
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: colorSeleccionado.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: colorSeleccionado,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: colorSeleccionado.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconoActual(),
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nueva Meta',
                            style: GoogleFonts.lato(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Define tu objetivo de ahorro',
                            style: GoogleFonts.openSans(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final shouldPop = await _onWillPop();
                        if (shouldPop && mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(Icons.close, size: 24.sp),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.r),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        Text(
                          'Nombre de la meta',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            hintText: 'Ej: Casa nueva, Auto, Vacaciones',
                            prefixIcon: Icon(
                              Icons.label_outline,
                              color: colorSeleccionado,
                            ),
                            filled: true,
                            fillColor: colorSeleccionado.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: colorSeleccionado,
                                width: 2,
                              ),
                            ),
                          ),
                          validator:
                              (v) =>
                                  v?.isEmpty == true ? 'Campo requerido' : null,
                        ),
                        SizedBox(height: 16.h),

                        // Descripción
                        Text(
                          'Descripción (opcional)',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _descripcionController,
                          decoration: InputDecoration(
                            hintText: 'Añade más detalles sobre tu meta',
                            prefixIcon: Icon(
                              Icons.description_outlined,
                              color: colorSeleccionado,
                            ),
                            filled: true,
                            fillColor: colorSeleccionado.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: colorSeleccionado,
                                width: 2,
                              ),
                            ),
                          ),
                          maxLines: 2,
                        ),
                        SizedBox(height: 16.h),

                        // Monto objetivo
                        Text(
                          'Monto objetivo',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
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
                                _montoController.text = result.toStringAsFixed(
                                  2,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: colorSeleccionado.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: colorSeleccionado.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: colorSeleccionado.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '\$',
                                    style: GoogleFonts.lato(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: colorSeleccionado,
                                    ),
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
                                                _montoController.text
                                                    .replaceAll(',', ''),
                                              ) ??
                                              0.0,
                                        )
                                        : '\$0.00',
                                    style: GoogleFonts.lato(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.edit_rounded,
                                  color: colorSeleccionado,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Fecha objetivo
                        Text(
                          'Fecha objetivo',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        InkWell(
                          onTap: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: _fechaObjetivo,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                Duration(days: 3650),
                              ),
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
                              color: colorSeleccionado.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12.r),
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
                        Text(
                          'Ícono',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
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
                                        () =>
                                            _iconoSeleccionado = icono['name'],
                                      ),
                                  child: Container(
                                    width: 60.w,
                                    height: 60.h,
                                    decoration: BoxDecoration(
                                      color:
                                          seleccionado
                                              ? colorSeleccionado.withOpacity(
                                                0.1,
                                              )
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color:
                                            seleccionado
                                                ? colorSeleccionado
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icono['icon'],
                                          size: 28.sp,
                                          color:
                                              seleccionado
                                                  ? colorSeleccionado
                                                  : Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 20.h),

                        // Selector de color
                        Text(
                          'Color',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
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
                                            _colorSeleccionado =
                                                color['color']!,
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
                      ],
                    ),
                  ),
                ),
              ),

              // Footer con botones
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final cleanMonto = _montoController.text.replaceAll(
                              ',',
                              '',
                            );
                            final meta = Meta(
                              id:
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              nombre: _nombreController.text,
                              descripcion: _descripcionController.text,
                              montoObjetivo: double.parse(cleanMonto),
                              montoActual: 0,
                              fechaInicio: DateTime.now().toIso8601String(),
                              fechaObjetivo: _fechaObjetivo.toIso8601String(),
                              icono: _iconoSeleccionado,
                              color: _colorSeleccionado,
                              completada: false,
                              cuentaId: null,
                              cuentaNombre: null,
                              numeroCuenta: null,
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
                          elevation: 2,
                        ),
                        child: Text(
                          'Guardar Meta',
                          style: GoogleFonts.lato(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
