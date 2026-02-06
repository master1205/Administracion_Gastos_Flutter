import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:notificaciones/widgets/confirmation_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/componentes/heads_up_notification.dart';
import 'package:notificaciones/dynamic_form_screen.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'utils/animation_utils.dart';
import 'componentes/empty_states.dart';
import 'componentes/shimmer_widgets.dart';

class TransaccionesScreen extends StatefulWidget {
  final String? cuentaFiltro;

  const TransaccionesScreen({Key? key, this.cuentaFiltro}) : super(key: key);

  @override
  TransaccionesScreenState createState() => TransaccionesScreenState();
}

class TransaccionesScreenState extends State<TransaccionesScreen>
    with WidgetsBindingObserver {
  // Constants
  static const String _tutorialKey = 'tutorial_transacciones_shown';

  // Services & Data
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<Transaction>>? _transaccionesSubscription;
  List<Transaction> _transacciones = [];
  List<Transaction> _transaccionesFiltradas = [];
  String? _cuentaFiltroActual;
  bool _isLoading = true;
  bool _isManualRefresh = false;

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
    _loadData();
  }

  @override
  void dispose() {
    _transaccionesSubscription?.cancel();
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

  Future<void> _loadData() async {
    final startTime = DateTime.now();
    final shouldShowProgress = _isManualRefresh;

    setState(() {
      if (!_isManualRefresh) {
        _isLoading = true;
      }
    });

    try {
      // Cancelar subscription anterior si existe
      _transaccionesSubscription?.cancel();

      // Escuchar cambios en tiempo real
      _transaccionesSubscription = _firestoreService
          .obtenerTransaccionesRecientes()
          .listen((transacciones) {
            if (mounted) {
              setState(() {
                _transacciones = transacciones;
                _aplicarFiltro();
                _isLoading = false;
              });
            }
          });

      await _maybeShowTutorial();

      // Esperar mínimo 800ms para mostrar animación (solo en refresh manual)
      if (shouldShowProgress) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 800) {
          await Future.delayed(Duration(milliseconds: 800 - elapsed));
        }
        if (mounted && _isManualRefresh) {
          setState(() => _isManualRefresh = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> refreshData() async {
    setState(() => _isManualRefresh = true);
    _loadData();
  }

  void _aplicarFiltro() {
    if (_cuentaFiltroActual == null || _cuentaFiltroActual!.isEmpty) {
      _transaccionesFiltradas = _transacciones;
    } else {
      _transaccionesFiltradas =
          _transacciones.where((t) {
            return t.cuenta == _cuentaFiltroActual ||
                t.cuentaOrigen == _cuentaFiltroActual ||
                t.cuentaDestino == _cuentaFiltroActual;
          }).toList();
    }
  }

  void _limpiarFiltro() {
    setState(() {
      _cuentaFiltroActual = null;
      _aplicarFiltro();
    });
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
      colorShadow: Colors.black,
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
                gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
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
                    color: Colors.grey.shade700,
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
                            color: Colors.grey.shade600,
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
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onBack,
                              icon: Icon(Icons.arrow_back_rounded, size: 16.sp),
                              color: Colors.grey.shade700,
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
            color: !isActive && !isCurrent ? Colors.grey.shade300 : null,
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
                        style: GoogleFonts.lato(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        capitalizedDate,
                        style: GoogleFonts.openSans(
                          fontSize: 11.sp,
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
                                    style: GoogleFonts.lato(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(entry.value.abs()),
                                  style: GoogleFonts.lato(
                                    fontSize: 13.sp,
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
                              style: GoogleFonts.lato(
                                color: theme.colorScheme.secondary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
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
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
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
            onPressed: (context) => _showEditConfirmation(transaction),
            backgroundColor: Colors.blue.shade400,
            foregroundColor: Colors.white,
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
            onPressed: (context) => _showDeleteConfirmation(transaction),
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
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
                color: Colors.black.withOpacity(0.03),
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
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
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
              style: GoogleFonts.lato(
                fontSize: 15.sp,
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
      confirmColor: Colors.red.shade400,
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
            style: GoogleFonts.poppins(
              color: theme.colorScheme.secondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
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
        color: theme.colorScheme.surface.withOpacity(0.5),
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
              style: GoogleFonts.lato(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          _currencyFormat.format(amount),
          style: GoogleFonts.lato(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Chip de filtro activo
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
            if (_isLoading)
              Container(
                color: theme.colorScheme.background.withOpacity(0.8),
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
                        style: GoogleFonts.lato(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onBackground,
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
        bottom: -25.h + MediaQuery.of(context).padding.bottom,
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
