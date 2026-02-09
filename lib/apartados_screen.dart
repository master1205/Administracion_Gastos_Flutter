import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/Apartado.dart';
import 'services/firestore_service.dart';
import 'widgets/animations.dart';
import 'widgets/animated_card.dart';
import 'widgets/budget_widgets.dart';
import 'widgets/shimmer_loading.dart';
import 'crear_apartado_screen.dart';
import 'apartado_detalle_screen.dart';
import 'componentes/heads_up_notification.dart';

class ApartadosScreen extends StatefulWidget {
  const ApartadosScreen({Key? key}) : super(key: key);

  @override
  State<ApartadosScreen> createState() => _ApartadosScreenState();
}

class _ApartadosScreenState extends State<ApartadosScreen>
    with TickerProviderStateMixin {
  final ValueNotifier<List<Apartado>> _apartadosNotifier =
      ValueNotifier<List<Apartado>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  bool _isManualRefresh = false;
  StreamSubscription<List<Apartado>>? _apartadosSubscription;
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _apartadosSubscription?.cancel();
    _apartadosNotifier.dispose();
    _isLoadingNotifier.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _cargarDatos() {
    _apartadosSubscription?.cancel();
    _apartadosSubscription = _firestoreService.obtenerApartados().listen(
      (apartados) {
        // Ordenar por progreso descendente
        apartados.sort((a, b) => b.progreso.compareTo(a.progreso));
        _apartadosNotifier.value = apartados;
        _isLoadingNotifier.value = false;
      },
      onError: (e) {
        debugPrint('Error cargando apartados: $e');
        _isLoadingNotifier.value = false;
      },
    );
  }

  Future<void> refreshData() async {
    setState(() => _isManualRefresh = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isManualRefresh = false);
  }

  void _crearApartado() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearApartadoScreen()),
    );
    if (result == true && mounted) {
      showSuccessNotification(
        context,
        message: 'Apartado creado',
        subtitle: 'Se agregó un nuevo apartado',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Apartados',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: ValueListenableBuilder<List<Apartado>>(
            valueListenable: _apartadosNotifier,
            builder: (context, apartados, _) {
              final countAbonando =
                  apartados
                      .where((a) => a.estado == 'activo' || a.estaVencido)
                      .length;
              final countListos =
                  apartados.where((a) => a.estado == 'completado').length;
              final countPagados =
                  apartados.where((a) => a.estado == 'pagado').length;

              return TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                  0.5,
                ),
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  _buildTab('Abonando', countAbonando, theme),
                  _buildTab('Listos', countListos, theme),
                  _buildTab('Pagados', countPagados, theme),
                ],
              );
            },
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

              return ValueListenableBuilder<List<Apartado>>(
                valueListenable: _apartadosNotifier,
                builder: (context, apartados, child) {
                  final abonando =
                      apartados
                          .where((a) => a.estado == 'activo' || a.estaVencido)
                          .toList();
                  final listos =
                      apartados.where((a) => a.estado == 'completado').toList();
                  final pagados =
                      apartados.where((a) => a.estado == 'pagado').toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabContent(
                        abonando,
                        'Sin apartados activos',
                        'Crea un apartado para empezar a abonar',
                      ),
                      _buildTabContent(
                        listos,
                        'Sin apartados listos',
                        'Los apartados completados aparecerán aquí',
                      ),
                      _buildTabContent(
                        pagados,
                        'Sin apartados pagados',
                        'Los apartados pagados aparecerán aquí',
                      ),
                    ],
                  );
                },
              );
            },
          ),
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
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
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
        fab: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: _crearApartado,
              splashColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count, ThemeData theme) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.lato(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent(
    List<Apartado> apartados,
    String emptyTitle,
    String emptySubtitle,
  ) {
    final theme = Theme.of(context);

    if (apartados.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 56.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
              SizedBox(height: 16.h),
              Text(
                emptyTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calcular resumen
    final totalApartado = apartados.fold<double>(
      0,
      (sum, a) => sum + a.montoApartado,
    );
    final totalMeta = apartados.fold<double>(0, (sum, a) => sum + a.montoTotal);

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.r,
        right: 16.r,
        top: 8.r,
        bottom: 70.h + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: apartados.length + 1, // +1 for summary
      itemBuilder: (context, index) {
        if (index == 0) {
          return FadeIn(
            duration: const Duration(milliseconds: 200),
            child: _buildSummaryHeader(
              apartados.length,
              totalApartado,
              totalMeta,
            ),
          );
        }
        final apartado = apartados[index - 1];
        return FadeIn(
          duration: Duration(milliseconds: 250 + (index * 40)),
          child: _buildApartadoCard(apartado),
        );
      },
    );
  }

  Widget _buildSummaryHeader(int count, double apartado, double total) {
    final theme = Theme.of(context);
    final progreso = total > 0 ? (apartado / total * 100) : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h, top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count apartado${count != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_currencyFormat.format(apartado)} de ${_currencyFormat.format(total)}',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44.w,
            height: 44.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progreso / 100,
                  strokeWidth: 4.w,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '${progreso.toStringAsFixed(0)}%',
                  style: GoogleFonts.lato(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApartadoCard(Apartado apartado) {
    final theme = Theme.of(context);
    final colorHex = int.parse('FF${apartado.color}', radix: 16);
    final color = Color(colorHex);
    final isPagado = apartado.estado == 'pagado';
    final cardColor = isPagado ? Colors.grey : color;

    // Estado badge
    String estadoLabel = '';
    IconData? estadoIcon;
    Color estadoBgColor = Colors.white.withOpacity(0.25);
    if (apartado.estado == 'completado') {
      estadoLabel = 'Listo';
      estadoIcon = Icons.check_circle_rounded;
    } else if (isPagado) {
      estadoLabel = 'Pagado';
      estadoIcon = Icons.done_all_rounded;
    } else if (apartado.estaVencido) {
      estadoLabel = 'Vencido';
      estadoIcon = Icons.warning_rounded;
      estadoBgColor = Colors.red.withOpacity(0.3);
    }

    // Urgencia: próximos 7 días
    final diasRestantes =
        apartado.fechaLimite.difference(DateTime.now()).inDays;
    final esUrgente =
        !isPagado &&
        apartado.estado == 'activo' &&
        diasRestantes >= 0 &&
        diasRestantes <= 7;

    return AnimatedCard(
      color: cardColor,
      randomOffset: apartado.nombre.length,
      horizontalMargin: 0,
      borderRadius: 16.r,
      borderColor:
          esUrgente ? Colors.red.withOpacity(0.5) : color.withOpacity(0.2),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApartadoDetalleScreen(apartado: apartado),
          ),
        );
      },
      headerContent: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _getIconData(apartado.icono),
              size: 18.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        apartado.nombre,
                        style: GoogleFonts.lato(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (apartado.esRecurrente) ...[
                      SizedBox(width: 5.w),
                      Icon(
                        Icons.repeat_rounded,
                        size: 13.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ],
                ),
                if (apartado.cuentaNombre != null &&
                    apartado.cuentaNombre!.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    apartado.cuentaNombre!,
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      color: Colors.white.withOpacity(0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (estadoLabel.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: estadoBgColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (estadoIcon != null) ...[
                    Icon(estadoIcon, size: 12.sp, color: Colors.white),
                    SizedBox(width: 3.w),
                  ],
                  Text(
                    estadoLabel,
                    style: GoogleFonts.lato(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (esUrgente)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '$diasRestantes d',
                    style: GoogleFonts.lato(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.fromLTRB(16.r, 12.r, 16.r, 14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar with percentage
            Row(
              children: [
                Expanded(
                  child: BudgetProgressBar(
                    progreso: apartado.progreso,
                    color: cardColor,
                    height: 10.h,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${apartado.progreso.toStringAsFixed(0)}%',
                  style: GoogleFonts.lato(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Montos + info
            Row(
              children: [
                // Apartado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apartado',
                        style: GoogleFonts.lato(
                          fontSize: 10.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(apartado.montoApartado),
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.lato(
                          fontSize: 10.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(apartado.montoTotal),
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 11.sp,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.45,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '${apartado.pagosRealizados}/${apartado.numeroPagos}',
                            style: GoogleFonts.lato(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            DateFormat(
                              'dd MMM',
                              'es',
                            ).format(apartado.fechaLimite),
                            style: GoogleFonts.lato(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
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
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final codePoint = int.tryParse(iconName);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return Icons.account_balance_wallet;
  }
}
