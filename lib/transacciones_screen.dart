import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/dynamic_form_screen.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TransaccionesScreen extends StatefulWidget {
  const TransaccionesScreen({Key? key}) : super(key: key);

  @override
  TransaccionesScreenState createState() => TransaccionesScreenState();
}

class TransaccionesScreenState extends State<TransaccionesScreen>
    with WidgetsBindingObserver {
  // Constants
  static const String _tutorialKey = 'tutorial_transacciones_shown';

  // Services & Data
  final ApiService _apiService = ApiService();
  Future<List<Transaction>>? _futureTransacciones;
  bool _isLoading = true;

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
    WidgetsBinding.instance.addObserver(this);
    _initializeDateFormatting();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  // Initialization
  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_ES', null);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _futureTransacciones = _apiService.fetchTransactions();
    });

    try {
      await _futureTransacciones!;
      await _maybeShowTutorial();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> refreshData() async {
    await _loadData();
  }

  // Tutorial Methods
  Future<void> _maybeShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final dashboardTutorialShown =
        prefs.getBool('tutorial_dashboard_shown') ?? false;
    final transaccionesTutorialShown = prefs.getBool(_tutorialKey) ?? false;

    if (dashboardTutorialShown && !transaccionesTutorialShown) {
      Future.delayed(const Duration(milliseconds: 800), () {
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
          duration: const Duration(milliseconds: 300),
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
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.eliminarFilaPorIdTransaccion(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 18.sp,
                ), // ✅ REDUCIDO de 20
                SizedBox(width: 10.w),
                Text(response.msgE),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(14.r), // ✅ REDUCIDO de 16
          ),
        );
      }
      await refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 18.sp),
                SizedBox(width: 10.w),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(14.r),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    ).then((_) => refreshData());
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
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ), // ✅ REDUCIDO de 24
            child: Container(
              constraints: BoxConstraints(maxWidth: 280.w), // ✅ REDUCIDO de 350
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r), // ✅ REDUCIDO de 20
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
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
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          ), // ✅ REDUCIDO de 28
                        ),
                        SizedBox(height: 10.h), // ✅ REDUCIDO de 12
                        Text(
                          'Resumen del Día',
                          style: TextStyle(
                            fontSize: 17.sp, // ✅ REDUCIDO de 20
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h), // ✅ REDUCIDO de 6
                        Text(
                          capitalizedDate,
                          style: TextStyle(
                            fontSize: 11.sp, // ✅ REDUCIDO de 12
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.r), // ✅ REDUCIDO de 20
                    child: Column(
                      children:
                          totals.entries.map((entry) {
                            final (icon, color) = _getIconAndColorForType(
                              entry.key,
                            );
                            return Container(
                              margin: EdgeInsets.only(
                                bottom: 8.h,
                              ), // ✅ REDUCIDO de 10
                              padding: EdgeInsets.all(11.r), // ✅ REDUCIDO de 14
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1.w,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      7.r,
                                    ), // ✅ REDUCIDO de 9
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [color, color.withOpacity(0.7)],
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ), // ✅ REDUCIDO de 18
                                  ),
                                  SizedBox(width: 11.w), // ✅ REDUCIDO de 14
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ), // ✅ REDUCIDO de 14
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(entry.value.abs()),
                                    style: GoogleFonts.lato(
                                      fontSize: 13.sp, // ✅ REDUCIDO de 14
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
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      0,
                      16.w,
                      16.h,
                    ), // ✅ REDUCIDO de 20
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 11.h,
                            ), // ✅ REDUCIDO de 12
                            child: Center(
                              child: Text(
                                'Cerrar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp, // ✅ REDUCIDO de 14
                                  fontWeight: FontWeight.bold,
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
          ),
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
    final themeManager = Provider.of<ThemeManager>(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r), // ✅ REDUCIDO de 28
            decoration: BoxDecoration(
              color:
                  themeManager.isDarkMode
                      ? Colors.grey.shade800.withOpacity(0.3)
                      : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 60.sp,
              color: Colors.grey.shade400,
            ), // ✅ REDUCIDO de 70
          ),
          SizedBox(height: 16.h), // ✅ REDUCIDO de 20
          Text(
            'No hay transacciones',
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ), // ✅ REDUCIDO de 18
          ),
          SizedBox(height: 5.h), // ✅ REDUCIDO de 6
          Text(
            'Comienza agregando tu primera transacción',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
            ), // ✅ REDUCIDO de 13
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String fecha, List<Transaction> dailyTransactions) {
    final themeManager = Provider.of<ThemeManager>(context);
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
        margin: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ), // ✅ REDUCIDO de 14/10
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 7.h,
        ), // ✅ REDUCIDO de 14/9
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                themeManager.isDarkMode
                    ? [Colors.grey.shade800, Colors.grey.shade900]
                    : [
                      const Color(0xFF667eea).withOpacity(0.1),
                      const Color(0xFF764ba2).withOpacity(0.1),
                    ],
          ),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color:
                themeManager.isDarkMode
                    ? Colors.grey.shade700
                    : const Color(0xFF667eea).withOpacity(0.3),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r), // ✅ REDUCIDO de 7
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 13.sp,
                color: Colors.white,
              ), // ✅ REDUCIDO de 14
            ),
            SizedBox(width: 9.w), // ✅ REDUCIDO de 10
            Expanded(
              child: Text(
                formattedDate,
                style: GoogleFonts.lato(
                  fontSize: 12.sp, // ✅ REDUCIDO de 13
                  fontWeight: FontWeight.bold,
                  color:
                      themeManager.isDarkMode
                          ? Colors.white
                          : const Color(0xFF2D3436),
                ),
              ),
            ),
            Icon(
              Icons.info_outline_rounded,
              size: 15.sp, // ✅ REDUCIDO de 16
              color:
                  themeManager.isDarkMode
                      ? Colors.grey.shade400
                      : const Color(0xFF667eea),
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
            backgroundColor: Colors.blue,
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
            backgroundColor: Colors.red,
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
      child: Container(
        key: isFirst ? _firstTransactionKey : null,
        margin: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 4.h,
        ), // ✅ REDUCIDO de 14/5
        decoration: BoxDecoration(
          color:
              themeManager.isDarkMode
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color:
                  themeManager.isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : color.withOpacity(0.1),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ), // ✅ REDUCIDO de 14/10
          leading: Container(
            padding: EdgeInsets.all(9.r), // ✅ REDUCIDO de 11
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.sp,
            ), // ✅ REDUCIDO de 22
          ),
          title: Text(
            transaction.descripcion,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 13.sp, // ✅ REDUCIDO de 14
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6.h), // ✅ REDUCIDO de 7
            child: Wrap(
              spacing: 4.w, // ✅ REDUCIDO de 5
              runSpacing: 2.h, // ✅ REDUCIDO de 3
              children: _buildTransactionBadges(transaction, color),
            ),
          ),
          trailing: Text(
            _currencyFormat.format(transaction.monto.abs()),
            style: GoogleFonts.lato(
              fontSize: 13.sp, // ✅ REDUCIDO de 14
              fontWeight: FontWeight.bold,
              color: color,
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
        break;
      case 'Reembolsos':
        badges.add(
          _buildBadge(
            text: transaction.cuenta,
            backgroundColor: color,
            textStyle: badgeTextStyle,
          ),
        );
        break;
      case 'Gastos':
      case 'Pagos':
      case 'Ingresos':
        badges.add(
          _buildBadge(
            text: transaction.categoria,
            backgroundColor: color,
            textStyle: badgeTextStyle,
          ),
        );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => _buildConfirmationDialog(
            title: 'Editar Transacción',
            message: '¿Deseas editar esta transacción?',
            confirmText: 'Editar',
            confirmColor: Colors.blue,
            icon: Icons.edit_rounded,
          ),
    );

    if (confirmed == true) {
      _editTransaction(transaction);
    }
  }

  Future<void> _showDeleteConfirmation(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => _buildConfirmationDialog(
            title: 'Eliminar Transacción',
            message:
                '¿Estás seguro de eliminar esta transacción? Esta acción no se puede deshacer.',
            confirmText: 'Eliminar',
            confirmColor: Colors.red,
            icon: Icons.delete_rounded,
          ),
    );

    if (confirmed == true) {
      await _deleteTransaction(transaction.idTransaccion);
    }
  }

  Widget _buildConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 280.w), // ✅ REDUCIDO de 350
        padding: EdgeInsets.all(16.r), // ✅ REDUCIDO de 20
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.r), // ✅ REDUCIDO de 14
              decoration: BoxDecoration(
                color: confirmColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30.sp,
                color: confirmColor,
              ), // ✅ REDUCIDO de 36
            ),
            SizedBox(height: 13.h), // ✅ REDUCIDO de 16
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ), // ✅ REDUCIDO de 18
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h), // ✅ REDUCIDO de 10
            Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ), // ✅ REDUCIDO de 13
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h), // ✅ REDUCIDO de 20
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                      ), // ✅ REDUCIDO de 12
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text('Cancelar', style: TextStyle(fontSize: 13.sp)),
                  ),
                ),
                SizedBox(width: 8.w), // ✅ REDUCIDO de 10
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [confirmColor, confirmColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(true),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Center(
                            child: Text(
                              confirmText,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final bgColor =
        themeManager.isDarkMode
            ? themeManager.themeData.scaffoldBackgroundColor
            : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: refreshData,
            color: const Color(0xFF667eea),
            strokeWidth: 2.3.w, // ✅ REDUCIDO de 2.5
            child: FutureBuilder<List<Transaction>>(
              future: _futureTransacciones,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData &&
                    !_isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeManager.isDarkMode
                                ? Colors.white
                                : const Color(0xFF667eea),
                          ),
                          strokeWidth: 2.5.w,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Cargando transacciones...',
                          style: TextStyle(
                            color:
                                themeManager.isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  if (snapshot.error is SocketException) {
                    return _buildErrorState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Sin conexión',
                      message: 'Verifica tu conexión a internet',
                    );
                  }
                  return _buildErrorState(
                    icon: Icons.error_outline_rounded,
                    title: 'Error',
                    message: snapshot.error.toString(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final sortedTransactions = List<Transaction>.from(
                  snapshot.data!,
                )..sort(
                  (a, b) => DateTime.parse(
                    b.fecha,
                  ).compareTo(DateTime.parse(a.fecha)),
                );

                final Map<String, List<Transaction>> groupedTransactions = {};
                for (var transaction in sortedTransactions) {
                  groupedTransactions
                      .putIfAbsent(transaction.fecha, () => [])
                      .add(transaction);
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                  ), // ✅ REDUCIDO de 14
                  itemCount:
                      sortedTransactions.length +
                      groupedTransactions.keys.length,
                  itemBuilder: (context, index) {
                    int transactionIndex = 0;
                    int dateHeaderCount = 0;

                    for (var date in groupedTransactions.keys) {
                      if (index == transactionIndex) {
                        final dailyTransactions = groupedTransactions[date]!;
                        return _buildDateHeader(date, dailyTransactions);
                      }
                      transactionIndex++;

                      final transactions = groupedTransactions[date]!;
                      if (index < transactionIndex + transactions.length) {
                        final localIndex = index - transactionIndex;
                        final transaction = transactions[localIndex];
                        final isFirst = dateHeaderCount == 0 && localIndex == 0;
                        return _buildTransactionCard(
                          transaction,
                          isFirst,
                          themeManager,
                        );
                      }
                      transactionIndex += transactions.length;
                      dateHeaderCount++;
                    }

                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          if (_isLoading)
            Container(
              color: bgColor.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeManager.isDarkMode
                            ? Colors.white
                            : const Color(0xFF667eea),
                      ),
                      strokeWidth: 2.5.w,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Actualizando...',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp, // ✅ REDUCIDO de 14
                        fontWeight: FontWeight.w600,
                        color:
                            themeManager.isDarkMode
                                ? Colors.white
                                : const Color(0xFF2D3436),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r), // ✅ REDUCIDO de 28
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60.sp,
              color: Colors.red.shade400,
            ), // ✅ REDUCIDO de 70
          ),
          SizedBox(height: 16.h), // ✅ REDUCIDO de 20
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 16.sp, // ✅ REDUCIDO de 18
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 5.h), // ✅ REDUCIDO de 6
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w), // ✅ REDUCIDO de 35
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ), // ✅ REDUCIDO de 13
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
