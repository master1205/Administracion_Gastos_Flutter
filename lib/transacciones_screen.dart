import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:notificaciones/widgets/confirmation_dialog.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/componentes/heads_up_notification.dart';
import 'package:notificaciones/dynamic_form_screen.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/theme_provider.dart';
import 'utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'utils/animation_utils.dart';
import 'componentes/empty_states.dart';
import 'componentes/shimmer_widgets.dart';

class TransaccionesScreen extends StatefulWidget {
  final String? cuentaFiltro;
  final VoidCallback? onStateChanged;

  const TransaccionesScreen({Key? key, this.cuentaFiltro, this.onStateChanged})
    : super(key: key);

  @override
  TransaccionesScreenState createState() => TransaccionesScreenState();
}

class TransaccionesScreenState extends State<TransaccionesScreen>
    with WidgetsBindingObserver {
  // Constants
  static const String _tutorialKey = 'tutorial_transacciones_shown';

  // Services & Data
  final ApiService _apiService = ApiService();
  List<Transaction> _transaccionesFiltradas = [];
  String? _cuentaFiltroActual;
  bool _isLoading = false;
  bool _isManualRefresh = false;

  // ── Búsqueda y filtros avanzados ──
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filtroTipo;
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearch = false;

  // ── API pública para home_screen AppBar ──
  bool get showSearch => _showSearch;
  bool get hasSearchQuery => _searchQuery.isNotEmpty;
  int get activeAdvancedFilterCount => _activeAdvancedFilterCount;

  void toggleSearch() {
    Haptics.light();
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
    widget.onStateChanged?.call();
  }

  void openAdvancedFilters() {
    Haptics.light();
    _showAdvancedFilters(Theme.of(context));
  }

  // Filtros avanzados
  DateTimeRange? _filtroFechas;
  double? _montoMin;
  double? _montoMax;
  Set<String> _filtroCategoriasSet = {};
  String? _filtroCuentaAvanzada;

  // Formatters
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  // Tutorial
  late TutorialCoachMark _tutorialCoachMark;
  final List<TargetFocus> _targets = [];
  final GlobalKey _dateHeaderKey = GlobalKey();
  final GlobalKey _firstTransactionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cuentaFiltroActual = widget.cuentaFiltro;
    WidgetsBinding.instance.addObserver(this);
    _initializeDateFormatting();
    _maybeShowTutorial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Los Streams de Firebase se actualizan automáticamente
  }

  // Initialization
  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_ES', null);
  }

  Future<void> refreshData() async {
    setState(() => _isManualRefresh = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isManualRefresh = false);
  }

  void _aplicarFiltro() {
    var transacciones =
        Provider.of<DataProvider>(context, listen: false).transacciones;

    // Filtro por cuenta (desde otra pantalla)
    if (_cuentaFiltroActual != null && _cuentaFiltroActual!.isNotEmpty) {
      transacciones =
          transacciones.where((t) {
            return t.cuenta == _cuentaFiltroActual ||
                t.cuentaOrigen == _cuentaFiltroActual ||
                t.cuentaDestino == _cuentaFiltroActual;
          }).toList();
    }

    // Filtro por tipo de transacción
    if (_filtroTipo != null) {
      transacciones =
          transacciones.where((t) => t.tipoTransaccion == _filtroTipo).toList();
    }

    // Búsqueda por texto (descripción, categoría o cuenta)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      transacciones =
          transacciones.where((t) {
            return t.descripcion.toLowerCase().contains(query) ||
                t.categoria.toLowerCase().contains(query) ||
                t.cuenta.toLowerCase().contains(query);
          }).toList();
    }

    // Filtro por rango de fechas
    if (_filtroFechas != null) {
      final inicioFiltro = DateTime(
        _filtroFechas!.start.year,
        _filtroFechas!.start.month,
        _filtroFechas!.start.day,
      );
      final finFiltro = DateTime(
        _filtroFechas!.end.year,
        _filtroFechas!.end.month,
        _filtroFechas!.end.day,
        23,
        59,
        59,
      );
      transacciones =
          transacciones.where((t) {
            final fecha = DateTime.tryParse(t.fecha);
            if (fecha == null) return false;
            return !fecha.isBefore(inicioFiltro) && !fecha.isAfter(finFiltro);
          }).toList();
    }

    // Filtro por rango de montos
    if (_montoMin != null) {
      transacciones =
          transacciones.where((t) => t.monto >= _montoMin!).toList();
    }
    if (_montoMax != null) {
      transacciones =
          transacciones.where((t) => t.monto <= _montoMax!).toList();
    }

    // Filtro por categorías seleccionadas
    if (_filtroCategoriasSet.isNotEmpty) {
      transacciones =
          transacciones
              .where((t) => _filtroCategoriasSet.contains(t.categoria))
              .toList();
    }

    // Filtro por cuenta avanzada
    if (_filtroCuentaAvanzada != null) {
      transacciones =
          transacciones.where((t) {
            return t.cuenta == _filtroCuentaAvanzada ||
                t.cuentaOrigen == _filtroCuentaAvanzada ||
                t.cuentaDestino == _filtroCuentaAvanzada;
          }).toList();
    }

    _transaccionesFiltradas = transacciones;
  }

  int get _activeAdvancedFilterCount {
    int count = 0;
    if (_filtroTipo != null) count++;
    if (_filtroFechas != null) count++;
    if (_montoMin != null || _montoMax != null) count++;
    if (_filtroCategoriasSet.isNotEmpty) count++;
    if (_filtroCuentaAvanzada != null) count++;
    return count;
  }

  bool get _hasAnyFilter {
    return _searchQuery.isNotEmpty ||
        _filtroTipo != null ||
        _cuentaFiltroActual != null ||
        _filtroFechas != null ||
        _montoMin != null ||
        _montoMax != null ||
        _filtroCategoriasSet.isNotEmpty ||
        _filtroCuentaAvanzada != null;
  }

  void _limpiarFiltro() {
    setState(() {
      _cuentaFiltroActual = null;
      _filtroTipo = null;
      _searchQuery = '';
      _searchController.clear();
      _searchFocusNode.unfocus();
      _filtroFechas = null;
      _montoMin = null;
      _montoMax = null;
      _filtroCategoriasSet = {};
      _filtroCuentaAvanzada = null;
      _aplicarFiltro();
    });
    widget.onStateChanged?.call();
    // Si se abrió con filtro desde otra pantalla, regresar
    if (widget.cuentaFiltro != null) {
      Navigator.of(context).pop();
    }
  }

  // Tutorial Methods
  Future<void> _maybeShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final dashboardTutorialShown =
        prefs.getBool('tutorial_dashboard_shown') ?? false;
    final transaccionesTutorialShown = prefs.getBool(_tutorialKey) ?? false;

    if (dashboardTutorialShown && !transaccionesTutorialShown) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _createTutorial();
          _tutorialCoachMark.show(context: context);
        }
      });
    }
  }

  void _createTutorial() {
    _initTargets();
    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Theme.of(context).colorScheme.shadow,
      textSkip: "",
      paddingFocus: 10,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_tutorialKey, true);
      },
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool(_tutorialKey, true);
        });
        return true;
      },
    );
  }

  void _initTargets() {
    _targets.clear();
    _targets.addAll([_createDateHeaderTarget(), _createSlideActionTarget()]);
  }

  TargetFocus _createDateHeaderTarget() {
    return TargetFocus(
      identify: "DateHeader",
      keyTarget: _dateHeaderKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r), // ✅ REDUCIDO de 20
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "📅 Resumen por Fecha",
                description:
                    "Toca el encabezado de fecha para ver el resumen total de transacciones del día agrupadas por tipo.",
                icon: Icons.calendar_today_rounded,
                gradientColors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                currentStep: 1,
                totalSteps: 2,
                onNext: controller.next,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createSlideActionTarget() {
    return TargetFocus(
      identify: "SlideAction",
      keyTarget: _firstTransactionKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 16,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "✏️ Editar o Eliminar",
                description:
                    "Desliza cualquier transacción hacia la izquierda para editarla o hacia la derecha para eliminarla.",
                icon: Icons.swipe_rounded,
                gradientColors: const [Color(0xFFf093fb), Color(0xFFF5576c)],
                currentStep: 2,
                totalSteps: 2,
                onNext: controller.next,
                onBack: controller.previous,
                isLastStep: true,
              ),
        ),
      ],
    );
  }

  Widget _buildModernTutorialCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required int currentStep,
    required int totalSteps,
    VoidCallback? onNext,
    VoidCallback? onBack,
    VoidCallback? onSkip,
    bool isLastStep = false,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: 280.w), // ✅ REDUCIDO de 350
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r), // ✅ REDUCIDO de 24
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 20
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r), // ✅ REDUCIDO de 12
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 26.sp,
                    color: Colors.white,
                  ), // ✅ REDUCIDO de 32
                ),
                SizedBox(height: 8.h), // ✅ REDUCIDO de 12
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp, // ✅ REDUCIDO de 20
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 20
            child: Column(
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp, // ✅ REDUCIDO de 14
                    height: 1.3,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h), // ✅ REDUCIDO de 16
                _buildProgressIndicator(
                  currentStep,
                  totalSteps,
                  gradientColors,
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isLastStep && onSkip != null)
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          minimumSize: Size(50.w, 32.h),
                        ),
                        child: Text(
                          'Omitir',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12.sp, // ✅ REDUCIDO de 14
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        if (onBack != null)
                          Container(
                            margin: EdgeInsets.only(right: 6.w),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onBack,
                              icon: Icon(Icons.arrow_back_rounded, size: 16.sp),
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                              padding: EdgeInsets.all(6.r),
                              constraints: BoxConstraints(
                                minWidth: 30.w,
                                minHeight: 30.h,
                              ),
                            ),
                          ),
                        if (onNext != null)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors.first.withOpacity(0.4),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 3.h),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onNext,
                                borderRadius: BorderRadius.circular(18.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isLastStep
                                            ? '¡Entendido!'
                                            : 'Siguiente',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        isLastStep
                                            ? Icons.check_rounded
                                            : Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 14.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildProgressIndicator(
    int currentStep,
    int totalSteps,
    List<Color> gradientColors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: isCurrent ? 20.w : 5.w,
          height: 5.h,
          decoration: BoxDecoration(
            gradient:
                isActive || isCurrent
                    ? LinearGradient(colors: gradientColors)
                    : null,
            color:
                !isActive && !isCurrent
                    ? Theme.of(context).colorScheme.outlineVariant
                    : null,
            borderRadius: BorderRadius.circular(2.5.r),
          ),
        );
      }),
    );
  }

  // Transaction Actions
  Future<void> _deleteTransaction(String id) async {
    try {
      await _apiService.eliminarFilaPorIdTransaccion(id);
      if (mounted) {
        showSuccessNotification(
          context,
          message: 'Transacción eliminada exitosamente',
        );
      }
      // ✅ Stream de Firebase actualiza automáticamente la UI
    } catch (e) {
      if (mounted) {
        showErrorNotification(
          context,
          message: 'Error al eliminar',
          subtitle: e.toString(),
        );
      }
    }
  }

  void _editTransaction(Transaction transaccion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TrasaccionScreen(
              transaction: transaccion,
              transactionType: transaccion.tipoTransaccion,
              color: _getColorForType(transaccion.tipoTransaccion),
            ),
      ),
    );
  }

  // Helpers
  (IconData, Color) _getIconAndColorForType(String type) {
    return switch (type) {
      'Reembolsos' => (Icons.restore_rounded, Colors.purple),
      'Pagos' => (Icons.monetization_on_rounded, Colors.orange),
      'Traspasos' => (Icons.swap_horiz_rounded, Colors.blue),
      'Ingresos' => (Icons.trending_up_rounded, Colors.green),
      'Gastos' => (Icons.trending_down_rounded, Colors.red),
      _ => (Icons.receipt_rounded, Colors.grey),
    };
  }

  Color _getColorForType(String type) {
    return _getIconAndColorForType(type).$2;
  }

  // Daily Summary Dialog
  void _showDailyTransactions(String fecha, List<Transaction> transactions) {
    final relevantTypes = [
      'Gastos',
      'Ingresos',
      'Pagos',
      'Traspasos',
      'Reembolsos',
    ];

    Map<String, double> totals = {};
    for (var t in transactions) {
      if (relevantTypes.contains(t.tipoTransaccion)) {
        totals[t.tipoTransaccion] = (totals[t.tipoTransaccion] ?? 0) + t.monto;
      }
    }

    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'es_ES',
    ).format(DateTime.parse(fecha));
    final capitalizedDate =
        formattedDate[0].toUpperCase() + formattedDate.substring(1);

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          backgroundColor: theme.colorScheme.surface,
          child: Container(
            constraints: BoxConstraints(maxWidth: 280.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: theme.colorScheme.primary,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Resumen del Día',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        capitalizedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children:
                        totals.entries.map((entry) {
                          final (icon, color) = _getIconAndColorForType(
                            entry.key,
                          );
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(11.r),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: color.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(7.r),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(icon, color: color, size: 16.sp),
                                ),
                                SizedBox(width: 11.w),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(entry.value.abs()),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 11.h),
                          child: Center(
                            child: Text(
                              'Cerrar',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // UI Builders
  Widget _buildBadge({
    required String text,
    required Color backgroundColor,
    required TextStyle textStyle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.w,
        vertical: 2.h,
      ), // ✅ REDUCIDO de 7/3
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: backgroundColor.withOpacity(0.3), width: 1.w),
      ),
      child: Text(text, style: textStyle),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    if (_hasAnyFilter) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48.sp,
                  color: theme.colorScheme.primary.withOpacity(0.4),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Sin resultados',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No se encontraron transacciones para "$_searchQuery"'
                    : _activeAdvancedFilterCount > 0
                    ? 'Ninguna transacción coincide con los filtros aplicados'
                    : 'No hay transacciones con estos filtros',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              TextButton(
                onPressed: _limpiarFiltro,
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 10.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 16.sp,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Limpiar filtros',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
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

    return EmptyTransactionsState(
      onAddTransaction: () {
        showSuccessNotification(
          context,
          message: 'Navegar a agregar transacción',
        );
      },
    );
  }

  Widget _buildDateHeader(String fecha, List<Transaction> dailyTransactions) {
    final theme = Theme.of(context);
    String formattedDate = DateFormat(
      'EEEE, d MMMM',
      'es_ES',
    ).format(DateTime.parse(fecha));
    formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);

    final isFirstHeader = _dateHeaderKey.currentContext == null;

    return GestureDetector(
      key: isFirstHeader ? _dateHeaderKey : null,
      onTap: () => _showDailyTransactions(fecha, dailyTransactions),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 14.sp,
                color: theme.colorScheme.secondary,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                formattedDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.info_outline_rounded,
              size: 16.sp,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    bool isFirst,
    ThemeManager themeManager,
  ) {
    final (icon, color) = _getIconAndColorForType(transaction.tipoTransaccion);

    return Slidable(
      key: Key(transaction.idTransaccion),
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) {
              Haptics.light();
              _showEditConfirmation(transaction);
            },
            backgroundColor: Colors.blue.shade400,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: Icons.edit_rounded,
            label: 'Editar',
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14.r),
              bottomLeft: Radius.circular(14.r),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) {
              Haptics.heavy();
              _showDeleteConfirmation(transaction);
            },
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete_rounded,
            label: 'Eliminar',
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(14.r),
              bottomRight: Radius.circular(14.r),
            ),
          ),
        ],
      ),
      child: BounceTapButton(
        child: Container(
          key: isFirst ? _firstTransactionKey : null,
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.03),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            leading: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            title: Text(
              transaction.descripcion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Wrap(
                spacing: 4.w,
                runSpacing: 2.h,
                children: _buildTransactionBadges(transaction, color),
              ),
            ),
            trailing: Text(
              _currencyFormat.format(transaction.monto.abs()),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransactionBadges(Transaction transaction, Color color) {
    final badges = <Widget>[];
    final badgeTextStyle = TextStyle(
      fontSize: 9.sp, // ✅ REDUCIDO de 10
      fontWeight: FontWeight.w600,
      color: color,
    );

    switch (transaction.tipoTransaccion) {
      case 'Traspasos':
        if (transaction.cuentaOrigen.isNotEmpty &&
            transaction.cuentaDestino.isNotEmpty) {
          badges.addAll([
            _buildBadge(
              text: transaction.cuentaOrigen,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 10.sp,
              color: color,
            ), // ✅ REDUCIDO de 11
            _buildBadge(
              text: transaction.cuentaDestino,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
          ]);
        }
        break;
      case 'Reembolsos':
        if (transaction.cuenta.isNotEmpty) {
          badges.add(
            _buildBadge(
              text: transaction.cuenta,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
          );
        }
        break;
      case 'Gastos':
      case 'Pagos':
      case 'Ingresos':
        if (transaction.categoria.isNotEmpty) {
          badges.add(
            _buildBadge(
              text: transaction.categoria,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
          );
        }
        if (transaction.cuenta.isNotEmpty) {
          badges.add(
            _buildBadge(
              text: transaction.cuenta,
              backgroundColor: color,
              textStyle: badgeTextStyle,
            ),
          );
        }
        break;
    }

    return badges;
  }

  // Confirmation Dialogs
  Future<void> _showEditConfirmation(Transaction transaction) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Editar Transacción',
      message: '¿Deseas editar esta transacción?',
      confirmText: 'Editar',
      confirmColor: Theme.of(context).colorScheme.secondary,
      icon: Icons.edit_rounded,
    );

    if (confirmed == true) {
      _editTransaction(transaction);
    }
  }

  Future<void> _showDeleteConfirmation(Transaction transaction) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Eliminar Transacción',
      message:
          '¿Estás seguro de eliminar esta transacción? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      confirmColor: Theme.of(context).colorScheme.error,
      icon: Icons.delete_rounded,
    );

    if (confirmed == true) {
      await _deleteTransaction(transaction.idTransaccion);
    }
  }

  Widget _buildFiltroCuentaChip() {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_rounded,
            color: theme.colorScheme.secondary,
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            'Cuenta: $_cuentaFiltroActual',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _limpiarFiltro,
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.secondary,
                size: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenTotales() {
    final theme = Theme.of(context);

    double gastos = 0.0;
    double ingresos = 0.0;
    double traspasos = 0.0;

    for (var t in _transaccionesFiltradas) {
      switch (t.tipoTransaccion) {
        case 'Gastos':
        case 'Pagos':
          gastos += t.monto;
          break;
        case 'Ingresos':
        case 'Reembolsos':
          ingresos += t.monto;
          break;
        case 'Traspasos':
          traspasos += t.monto;
          break;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (ingresos > 0)
            _buildTotalChip(
              'Ingresos',
              ingresos,
              Colors.green,
              Icons.trending_up_rounded,
            ),
          if (gastos > 0)
            _buildTotalChip(
              'Gastos',
              gastos,
              Colors.red,
              Icons.trending_down_rounded,
            ),
          if (traspasos > 0)
            _buildTotalChip(
              'Traspasos',
              traspasos,
              Colors.blue,
              Icons.swap_horiz_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildTotalChip(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          _currencyFormat.format(amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Barra de búsqueda animada ──
  Widget _buildSearchBar(ThemeData theme) {
    final bool hasText = _searchQuery.isNotEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child:
          _showSearch
              ? Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar transacciones...',
                      hintStyle: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: 12.w, right: 8.w),
                        child: Icon(
                          Icons.search_rounded,
                          size: 20.sp,
                          color:
                              hasText
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(
                                    0.4,
                                  ),
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 20.h,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          Haptics.light();
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _showSearch = false;
                            _searchFocusNode.unfocus();
                          });
                          widget.onStateChanged?.call();
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: Container(
                            width: 28.w,
                            height: 28.h,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16.sp,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                      suffixIconConstraints: BoxConstraints(
                        minWidth: 36.w,
                        minHeight: 28.h,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 12.h,
                      ),
                    ),
                    onChanged: (value) {
                      final hadQuery = _searchQuery.isNotEmpty;
                      setState(() => _searchQuery = value);
                      if (hadQuery != value.isNotEmpty) {
                        widget.onStateChanged?.call();
                      }
                    },
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  // ── Chips de filtros activos ──
  Widget _buildActiveFilterChips(ThemeData theme) {
    final chips = <Widget>[];

    if (_filtroTipo != null) {
      const tipoColores = {
        'Gastos': Colors.red,
        'Ingresos': Colors.green,
        'Pagos': Colors.orange,
        'Traspasos': Colors.blue,
        'Reembolsos': Colors.purple,
      };
      chips.add(
        _buildFilterChipTag(
          theme,
          Icons.label_rounded,
          _filtroTipo!,
          tipoColores[_filtroTipo] ?? theme.colorScheme.primary,
          () => setState(() {
            _filtroTipo = null;
          }),
        ),
      );
    }

    if (_filtroFechas != null) {
      final fmt = DateFormat('d MMM', 'es_ES');
      chips.add(
        _buildFilterChipTag(
          theme,
          Icons.date_range_rounded,
          '${fmt.format(_filtroFechas!.start)} – ${fmt.format(_filtroFechas!.end)}',
          theme.colorScheme.primary,
          () => setState(() {
            _filtroFechas = null;
          }),
        ),
      );
    }

    if (_montoMin != null || _montoMax != null) {
      String label;
      if (_montoMin != null && _montoMax != null) {
        label =
            '\$${_montoMin!.toStringAsFixed(0)} – \$${_montoMax!.toStringAsFixed(0)}';
      } else if (_montoMin != null) {
        label = '≥ \$${_montoMin!.toStringAsFixed(0)}';
      } else {
        label = '≤ \$${_montoMax!.toStringAsFixed(0)}';
      }
      chips.add(
        _buildFilterChipTag(
          theme,
          Icons.attach_money_rounded,
          label,
          Colors.teal,
          () => setState(() {
            _montoMin = null;
            _montoMax = null;
          }),
        ),
      );
    }

    if (_filtroCategoriasSet.isNotEmpty) {
      final label =
          _filtroCategoriasSet.length == 1
              ? _filtroCategoriasSet.first
              : '${_filtroCategoriasSet.length} categorías';
      chips.add(
        _buildFilterChipTag(
          theme,
          Icons.category_rounded,
          label,
          Colors.deepPurple,
          () => setState(() {
            _filtroCategoriasSet = {};
          }),
        ),
      );
    }

    if (_filtroCuentaAvanzada != null) {
      chips.add(
        _buildFilterChipTag(
          theme,
          Icons.account_balance_wallet_rounded,
          _filtroCuentaAvanzada!,
          Colors.indigo,
          () => setState(() {
            _filtroCuentaAvanzada = null;
          }),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: chips.length + 1, // +1 for "clear all"
        separatorBuilder: (_, __) => SizedBox(width: 6.w),
        itemBuilder: (context, i) {
          if (i == chips.length) {
            // Botón limpiar todo
            return GestureDetector(
              onTap: () {
                Haptics.medium();
                setState(() {
                  _filtroTipo = null;
                  _filtroFechas = null;
                  _montoMin = null;
                  _montoMax = null;
                  _filtroCategoriasSet = {};
                  _filtroCuentaAvanzada = null;
                });
                widget.onStateChanged?.call();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.clear_all_rounded,
                      size: 14.sp,
                      color: theme.colorScheme.error.withOpacity(0.7),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Limpiar',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return chips[i];
        },
      ),
    );
  }

  Widget _buildFilterChipTag(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 5.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 130.w),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () {
              Haptics.light();
              onRemove();
              widget.onStateChanged?.call();
            },
            child: Icon(
              Icons.close_rounded,
              size: 14.sp,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Sheet de filtros avanzados ──
  void _showAdvancedFilters(ThemeData theme) {
    // Controladores temporales para el bottom sheet
    final minController = TextEditingController(
      text: _montoMin?.toStringAsFixed(0) ?? '',
    );
    final maxController = TextEditingController(
      text: _montoMax?.toStringAsFixed(0) ?? '',
    );
    DateTimeRange? tempFechas = _filtroFechas;
    Set<String> tempCategorias = Set.from(_filtroCategoriasSet);
    String? tempCuenta = _filtroCuentaAvanzada;
    String? tempTipo = _filtroTipo;

    final dp = Provider.of<DataProvider>(context, listen: false);
    // Obtener categorías y cuentas únicas de las transacciones
    final allCategorias =
        dp.transacciones
            .map((t) => t.categoria)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final allCuentas = dp.cuentas.map((c) => c.nombre).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            final fmtFull = DateFormat('d MMM yyyy', 'es_ES');

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 8.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 22.sp,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Filtros avanzados',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempTipo = null;
                              tempFechas = null;
                              minController.clear();
                              maxController.clear();
                              tempCategorias.clear();
                              tempCuenta = null;
                            });
                          },
                          child: Text(
                            'Limpiar',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                  // Scrollable filters
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── TIPO DE TRANSACCIÓN ───
                          _buildFilterSectionHeader(
                            theme,
                            Icons.label_rounded,
                            'Tipo de transacción',
                            Colors.blueGrey,
                          ),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children:
                                [
                                  (
                                    'Gastos',
                                    Icons.trending_down_rounded,
                                    Colors.red,
                                  ),
                                  (
                                    'Ingresos',
                                    Icons.trending_up_rounded,
                                    Colors.green,
                                  ),
                                  (
                                    'Pagos',
                                    Icons.monetization_on_rounded,
                                    Colors.orange,
                                  ),
                                  (
                                    'Traspasos',
                                    Icons.swap_horiz_rounded,
                                    Colors.blue,
                                  ),
                                  (
                                    'Reembolsos',
                                    Icons.restore_rounded,
                                    Colors.purple,
                                  ),
                                ].map((item) {
                                  final (label, icon, color) = item;
                                  final selected = tempTipo == label;
                                  return GestureDetector(
                                    onTap: () {
                                      Haptics.light();
                                      setModalState(() {
                                        tempTipo = selected ? null : label;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selected
                                                ? (color as Color).withOpacity(
                                                  0.12,
                                                )
                                                : theme
                                                    .colorScheme
                                                    .surfaceVariant
                                                    .withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color:
                                              selected
                                                  ? (color as Color)
                                                      .withOpacity(0.4)
                                                  : Colors.transparent,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (selected)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: 5.w,
                                              ),
                                              child: Icon(
                                                Icons.check_rounded,
                                                size: 14.sp,
                                                color: color as Color,
                                              ),
                                            ),
                                          Icon(
                                            icon,
                                            size: 15.sp,
                                            color:
                                                selected
                                                    ? color as Color
                                                    : theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.5),
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            label,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight:
                                                      selected
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                  color:
                                                      selected
                                                          ? color as Color
                                                          : theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.7),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          SizedBox(height: 20.h),
                          // ─── RANGO DE FECHAS ───
                          _buildFilterSectionHeader(
                            theme,
                            Icons.date_range_rounded,
                            'Rango de fechas',
                            theme.colorScheme.primary,
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: ctx,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: tempFechas,
                                locale: const Locale('es', 'ES'),
                                builder: (context, child) {
                                  return Theme(
                                    data: theme.copyWith(
                                      colorScheme: theme.colorScheme.copyWith(
                                        primary: theme.colorScheme.primary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() => tempFechas = picked);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    tempFechas != null
                                        ? theme.colorScheme.primary.withOpacity(
                                          0.08,
                                        )
                                        : theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color:
                                      tempFechas != null
                                          ? theme.colorScheme.primary
                                              .withOpacity(0.3)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16.sp,
                                    color:
                                        tempFechas != null
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.4),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      tempFechas != null
                                          ? '${fmtFull.format(tempFechas!.start)}  →  ${fmtFull.format(tempFechas!.end)}'
                                          : 'Seleccionar rango de fechas',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color:
                                                tempFechas != null
                                                    ? theme.colorScheme.primary
                                                    : theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.45),
                                            fontWeight:
                                                tempFechas != null
                                                    ? FontWeight.w500
                                                    : FontWeight.w400,
                                          ),
                                    ),
                                  ),
                                  if (tempFechas != null)
                                    GestureDetector(
                                      onTap:
                                          () => setModalState(
                                            () => tempFechas = null,
                                          ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18.sp,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // ─── RANGO DE MONTOS ───
                          _buildFilterSectionHeader(
                            theme,
                            Icons.attach_money_rounded,
                            'Rango de montos',
                            Colors.teal,
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAmountField(
                                  theme,
                                  minController,
                                  'Mínimo',
                                  '\$0',
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                child: Text(
                                  '–',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildAmountField(
                                  theme,
                                  maxController,
                                  'Máximo',
                                  '\$∞',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),

                          // ─── CUENTA ───
                          if (allCuentas.isNotEmpty) ...[
                            _buildFilterSectionHeader(
                              theme,
                              Icons.account_balance_wallet_rounded,
                              'Cuenta',
                              Colors.indigo,
                            ),
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children:
                                  allCuentas.map((cuenta) {
                                    final selected = tempCuenta == cuenta;
                                    return GestureDetector(
                                      onTap: () {
                                        Haptics.light();
                                        setModalState(() {
                                          tempCuenta = selected ? null : cuenta;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              selected
                                                  ? Colors.indigo.withOpacity(
                                                    0.12,
                                                  )
                                                  : theme
                                                      .colorScheme
                                                      .surfaceVariant
                                                      .withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          border: Border.all(
                                            color:
                                                selected
                                                    ? Colors.indigo.withOpacity(
                                                      0.4,
                                                    )
                                                    : Colors.transparent,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (selected)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  right: 5.w,
                                                ),
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  size: 14.sp,
                                                  color: Colors.indigo,
                                                ),
                                              ),
                                            Text(
                                              cuenta,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        selected
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                    color:
                                                        selected
                                                            ? Colors.indigo
                                                            : theme
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            SizedBox(height: 20.h),
                          ],

                          // ─── CATEGORÍAS ───
                          if (allCategorias.isNotEmpty) ...[
                            _buildFilterSectionHeader(
                              theme,
                              Icons.category_rounded,
                              'Categorías ${tempCategorias.isNotEmpty ? '(${tempCategorias.length})' : ''}',
                              Colors.deepPurple,
                            ),
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children:
                                  allCategorias.map((cat) {
                                    final selected = tempCategorias.contains(
                                      cat,
                                    );
                                    return GestureDetector(
                                      onTap: () {
                                        Haptics.light();
                                        setModalState(() {
                                          if (selected) {
                                            tempCategorias.remove(cat);
                                          } else {
                                            tempCategorias.add(cat);
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              selected
                                                  ? Colors.deepPurple
                                                      .withOpacity(0.12)
                                                  : theme
                                                      .colorScheme
                                                      .surfaceVariant
                                                      .withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          border: Border.all(
                                            color:
                                                selected
                                                    ? Colors.deepPurple
                                                        .withOpacity(0.4)
                                                    : Colors.transparent,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (selected)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  right: 5.w,
                                                ),
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  size: 14.sp,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                            Text(
                                              cat,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        selected
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                    color:
                                                        selected
                                                            ? Colors.deepPurple
                                                            : theme
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),
                  // Apply button
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      8.h,
                      20.w,
                      MediaQuery.of(ctx).padding.bottom + 16.h,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Haptics.medium();
                          setState(() {
                            _filtroTipo = tempTipo;
                            _filtroFechas = tempFechas;
                            _montoMin = double.tryParse(minController.text);
                            _montoMax = double.tryParse(maxController.text);
                            _filtroCategoriasSet = tempCategorias;
                            _filtroCuentaAvanzada = tempCuenta;
                          });
                          Navigator.pop(ctx);
                          widget.onStateChanged?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Aplicar filtros',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSectionHeader(
    ThemeData theme,
    IconData icon,
    String title,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: color),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField(
    ThemeData theme,
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        hintText: hint,
        hintStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.teal.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        prefixText: '\$ ',
        prefixStyle: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Escuchar cambios del DataProvider
    Provider.of<DataProvider>(context);
    // Aplicar filtro con datos frescos
    _aplicarFiltro();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Barra de búsqueda (aparece con animación) ──
                _buildSearchBar(theme),
                // ── Chips de filtros avanzados activos ──
                if (_activeAdvancedFilterCount > 0) ...[
                  SizedBox(height: 4.h),
                  _buildActiveFilterChips(theme),
                ],
                // Contador de resultados cuando hay filtros activos
                if (_hasAnyFilter && _transaccionesFiltradas.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 2.h),
                    child: Row(
                      children: [
                        Text(
                          '${_transaccionesFiltradas.length} resultado${_transaccionesFiltradas.length == 1 ? '' : 's'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Chip de filtro por cuenta (desde otra pantalla)
                if (_cuentaFiltroActual != null) _buildFiltroCuentaChip(),
                // Resumen de totales
                if (_cuentaFiltroActual != null &&
                    _transaccionesFiltradas.isNotEmpty) ...{
                  _buildResumenTotales(),
                  SizedBox(height: 8.h),
                },
                // Lista de transacciones
                Expanded(
                  child:
                      _isLoading
                          ? const TransactionListShimmer(itemCount: 8)
                          : _transaccionesFiltradas.isEmpty
                          ? _buildEmptyState()
                          : _buildTransactionsList(_transaccionesFiltradas),
                ),
              ],
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
                              theme.colorScheme.primary.withOpacity(0.0),
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                              theme.colorScheme.secondary.withOpacity(0.0),
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
            if (_isLoading)
              Container(
                color: theme.colorScheme.surfaceContainer,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        strokeWidth: 2.5.w,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Actualizando...',
                        style: theme.textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    final sortedTransactions = List<Transaction>.from(transactions)..sort(
      (a, b) => DateTime.parse(b.fecha).compareTo(DateTime.parse(a.fecha)),
    );

    final Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in sortedTransactions) {
      groupedTransactions
          .putIfAbsent(transaction.fecha, () => [])
          .add(transaction);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: 12.h,
        bottom: max(0.0, MediaQuery.of(context).padding.bottom - 25.h),
      ),
      itemCount: sortedTransactions.length + groupedTransactions.keys.length,
      itemBuilder: (context, index) {
        int transactionIndex = 0;
        int dateHeaderCount = 0;

        for (var date in groupedTransactions.keys) {
          if (index == transactionIndex) {
            final dailyTransactions = groupedTransactions[date]!;
            return AnimationUtils.slideFromBottom(
              _buildDateHeader(date, dailyTransactions),
              delay: dateHeaderCount * 50,
            );
          }
          transactionIndex++;

          final transactions = groupedTransactions[date]!;
          if (index < transactionIndex + transactions.length) {
            final localIndex = index - transactionIndex;
            final transaction = transactions[localIndex];
            final isFirst = dateHeaderCount == 0 && localIndex == 0;
            return AnimationUtils.staggeredAnimation(
              index: index,
              type: AnimationType.slideFromBottom,
              child: _buildTransactionCard(transaction, isFirst, themeManager),
            );
          }
          transactionIndex += transactions.length;
          dateHeaderCount++;
        }

        return const SizedBox.shrink();
      },
    );
  }
}
