import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de advertencia
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 48.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  '¿Eliminar meta?',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Se eliminará "${_metasNotifier.value[index].nombre}" y su cuenta de ahorro asociada.',
                  style: GoogleFonts.openSans(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Esta acción no se puede deshacer',
                  style: GoogleFonts.openSans(
                    fontSize: 13.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Eliminar',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

    return Scaffold(
      backgroundColor:
          themeManager.isDarkMode
              ? const Color(0xFF121212)
              : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Metas de Ahorro',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: widget.headerColor ?? const Color(0xFF4CAF50),
        elevation: 0,
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
          backgroundColor:
              themeManager.isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFF667eea),
          shape: const CircleBorder(),
          elevation: 4,
          child: Icon(Icons.add, color: Colors.white, size: 28.sp),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeManager themeManager) {
    return Center(
      child: SlideFadeTransition(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleIn(
              child: Container(
                padding: EdgeInsets.all(40.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF667eea).withOpacity(0.1),
                      Color(0xFF764ba2).withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.savings_outlined,
                  size: 80.sp,
                  color: Color(0xFF667eea),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Sin metas por ahora',
              style: GoogleFonts.lato(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: themeManager.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                '¡Crea tu primera meta de ahorro y empieza a cumplir tus sueños!',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 14.sp,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: _crearMeta,
              icon: Icon(Icons.add_circle_outline),
              label: Text(
                'Crear Primera Meta',
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard(Meta meta, int index, ThemeManager themeManager) {
    final colorHex = int.parse('FF${meta.color}', radix: 16);
    final color = Color(colorHex);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header compacto con gradiente
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        _getIconData(meta.icono),
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.nombre,
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (meta.descripcion.isNotEmpty)
                            Text(
                              meta.descripcion,
                              style: GoogleFonts.openSans(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13.sp,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: meta.progreso / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8.h,
                  ),
                ),
                SizedBox(height: 8.h),
                // Montos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${NumberFormat('#,##0.00', 'es').format(meta.montoActual)} / \$${NumberFormat('#,##0.00', 'es').format(meta.montoObjetivo)}',
                      style: GoogleFonts.openSans(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${meta.progreso.toStringAsFixed(0)}%',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
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
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              themeManager.isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14.sp,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Inicio',
                              style: GoogleFonts.openSans(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _formatDate(meta.fechaInicio),
                              style: GoogleFonts.lato(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              themeManager.isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 14.sp,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Objetivo',
                              style: GoogleFonts.openSans(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _formatDate(meta.fechaObjetivo),
                              style: GoogleFonts.lato(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
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
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16.sp,
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${meta.diasRestantes} días restantes',
                          style: GoogleFonts.openSans(
                            fontSize: 13.sp,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                // Botones con íconos simples
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _editarMeta(index),
                      icon: Icon(Icons.edit, color: Colors.blue, size: 24.sp),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      onPressed: () => _eliminarMeta(index),
                      icon: Icon(Icons.delete, color: Colors.red, size: 24.sp),
                      tooltip: 'Eliminar',
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
