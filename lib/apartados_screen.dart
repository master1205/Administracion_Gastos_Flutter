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
import 'widgets/confirmation_dialog.dart';
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

  void _editarApartado(Apartado apartado) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearApartadoScreen(apartado: apartado),
      ),
    );
    if (result == true && mounted) {
      showSuccessNotification(
        context,
        message: 'Apartado actualizado',
        subtitle: apartado.nombre,
      );
    }
  }

  void _eliminarApartado(Apartado apartado) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar apartado?',
      message: 'Se eliminará "${apartado.nombre}" y todos sus abonos.',
      confirmText: 'Eliminar',
      confirmColor: Colors.red,
      icon: Icons.delete_rounded,
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await _firestoreService.eliminarApartado(apartado.id);

        if (mounted) Navigator.pop(context);

        if (mounted) {
          showSuccessNotification(
            context,
            message: 'Apartado eliminado',
            subtitle: apartado.nombre,
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          showErrorNotification(
            context,
            message: 'Error al eliminar',
            subtitle: e.toString(),
          );
        }
      }
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
        bottom: TabBar(
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
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Abonando'),
            Tab(text: 'Listos'),
            Tab(text: 'Pagados'),
          ],
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

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.r,
        right: 16.r,
        top: 16.r,
        bottom: 70.h + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: apartados.length,
      itemBuilder: (context, index) {
        return FadeIn(
          duration: Duration(milliseconds: 300 + (index * 50)),
          child: _buildApartadoCard(apartados[index]),
        );
      },
    );
  }

  Widget _buildApartadoCard(Apartado apartado) {
    final theme = Theme.of(context);
    final colorHex = int.parse('FF${apartado.color}', radix: 16);
    final color = Color(colorHex);

    // Color de estado
    String estadoLabel = '';
    IconData? estadoIcon;
    if (apartado.estado == 'completado') {
      estadoLabel = 'Listo para pagar';
      estadoIcon = Icons.check_circle_rounded;
    } else if (apartado.estado == 'pagado') {
      estadoLabel = 'Pagado';
      estadoIcon = Icons.done_all_rounded;
    } else if (apartado.estaVencido) {
      estadoLabel = 'Vencido';
      estadoIcon = Icons.warning_rounded;
    }

    return AnimatedCard(
      color: apartado.estado == 'pagado' ? Colors.grey : color,
      randomOffset: apartado.nombre.length,
      horizontalMargin: 0,
      borderRadius: 16.r,
      borderColor: color.withOpacity(0.2),
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
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _getIconData(apartado.icono),
              size: 20.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (apartado.esRecurrente) ...[
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.repeat_rounded,
                        size: 14.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ],
                ),
                if (apartado.descripcion.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    apartado.descripcion,
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.9),
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
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (estadoIcon != null) ...[
                    Icon(estadoIcon, size: 13.sp, color: Colors.white),
                    SizedBox(width: 4.w),
                  ],
                  Text(
                    estadoLabel,
                    style: GoogleFonts.lato(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bodyContent: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BudgetProgressBar(
              progreso: apartado.progreso,
              color: apartado.estado == 'pagado' ? Colors.grey : color,
              height: 12.h,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apartado',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(apartado.montoApartado),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${apartado.progreso.toStringAsFixed(0)}%',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _currencyFormat.format(apartado.montoTotal),
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Divider(height: 1.h, thickness: 1),
            SizedBox(height: 12.h),
            // Info chips
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.payments_rounded,
                    label:
                        '${apartado.pagosRealizados}/${apartado.numeroPagos} abonos',
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat(
                      'dd MMM yyyy',
                      'es',
                    ).format(apartado.fechaLimite),
                  ),
                ),
              ],
            ),
            if (apartado.estado == 'activo' && apartado.pagosRestantes > 0) ...[
              SizedBox(height: 8.h),
              _buildInfoChip(
                icon: Icons.attach_money_rounded,
                label:
                    'Próximo abono: ${_currencyFormat.format(apartado.montoPorPago)}',
                chipColor: theme.colorScheme.primary,
              ),
            ],
            // Botones de acción
            SizedBox(height: 16.h),
            Row(
              children: [
                if (apartado.estado == 'activo') ...[
                  Expanded(
                    child: InkWell(
                      onTap: () => _editarApartado(apartado),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 20.sp,
                              color: color,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Editar',
                              style: GoogleFonts.lato(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                ],
                Expanded(
                  child: InkWell(
                    onTap: () => _eliminarApartado(apartado),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 20.sp,
                            color: theme.colorScheme.error,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Eliminar',
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? chipColor,
  }) {
    final theme = Theme.of(context);
    final c = chipColor ?? theme.colorScheme.onSurface.withOpacity(0.6);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: c),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: c,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
