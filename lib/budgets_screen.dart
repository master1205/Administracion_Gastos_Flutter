import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/models/Budget.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/widgets/animations.dart';
import 'package:notificaciones/widgets/budget_widgets.dart';
import 'package:notificaciones/crear_presupuesto_screen.dart';
import 'package:notificaciones/presupuesto_detalle_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  String? _filtroCategoria;
  String? _filtroPeriodo; // 'semanal' | 'mensual'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Verificar y renovar presupuestos al inicio
    _firestoreService.verificarYRenovarPresupuestos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Presupuestos',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: StreamBuilder<List<Budget>>(
            stream: _firestoreService.obtenerTodosPresupuestos(),
            builder: (context, snapshot) {
              final all = snapshot.data ?? [];
              final countActivos = all.where((b) => b.estaActivo).length;
              final countTodos = all.length;

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
                  _buildTab('Activos', countActivos, theme),
                  _buildTab('Todos', countTodos, theme),
                ],
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPresupuestosActivos(), _buildTodosPresupuestos()],
      ),
      floatingActionButton: AnimateFABDelayed(
        fab: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _crearNuevoPresupuesto,
              customBorder: const CircleBorder(),
              splashColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  color: theme.colorScheme.primary,
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

  Widget _buildSummaryHeader(List<Budget> presupuestos) {
    final theme = Theme.of(context);
    final totalGastado = presupuestos.fold<double>(
      0,
      (sum, b) => sum + b.montoGastado,
    );
    final totalLimite = presupuestos.fold<double>(
      0,
      (sum, b) => sum + b.montoLimite,
    );
    final progreso = totalLimite > 0 ? (totalGastado / totalLimite * 100) : 0.0;

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
                  '${presupuestos.length} presupuesto${presupuestos.length != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_currencyFormat.format(totalGastado)} de ${_currencyFormat.format(totalLimite)}',
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
                  value: (progreso / 100).clamp(0.0, 1.0),
                  strokeWidth: 4.w,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progreso > 100
                        ? Colors.red
                        : progreso >= 80
                        ? Colors.orange
                        : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '${progreso.toStringAsFixed(0)}%',
                  style: GoogleFonts.lato(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color:
                        progreso > 100 ? Colors.red : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresupuestosActivos() {
    return StreamBuilder<List<Budget>>(
      stream: _firestoreService.obtenerPresupuestosActivos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64.sp,
                  color: Theme.of(context).colorScheme.error.withOpacity(0.6),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Error al cargar presupuestos',
                  style: GoogleFonts.lato(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.lato(fontSize: 12.sp, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final presupuestos = _aplicarFiltros(snapshot.data ?? []);

        if (presupuestos.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title:
                _filtroCategoria != null || _filtroPeriodo != null
                    ? 'No hay presupuestos con estos filtros'
                    : 'No hay presupuestos activos',
            subtitle:
                _filtroCategoria != null || _filtroPeriodo != null
                    ? 'Prueba ajustando los filtros'
                    : 'Crea tu primer presupuesto para controlar tus gastos',
          );
        }

        // Ordenar por prioridad: excedidos, en alerta, normales
        presupuestos.sort((a, b) {
          if (a.excedido && !b.excedido) return -1;
          if (!a.excedido && b.excedido) return 1;
          if (a.enAlerta && !b.enAlerta) return -1;
          if (!a.enAlerta && b.enAlerta) return 1;
          return b.progreso.compareTo(a.progreso);
        });

        return CustomRefreshIndicator(
          onRefresh: () async {
            await _firestoreService.verificarYRenovarPresupuestos();
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16.r, 8.h, 16.r, 100.h),
            itemCount: presupuestos.length + 1, // +1 for summary
            itemBuilder: (context, index) {
              if (index == 0) {
                return FadeIn(
                  duration: const Duration(milliseconds: 200),
                  child: _buildSummaryHeader(presupuestos),
                );
              }
              final presupuesto = presupuestos[index - 1];
              return FadeIn(
                duration: Duration(milliseconds: 250 + (index * 40)),
                child: BudgetCardWidget(
                  budget: presupuesto,
                  isCompact: true,
                  onTap: () => _verDetallePresupuesto(presupuesto),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTodosPresupuestos() {
    return StreamBuilder<List<Budget>>(
      stream: _firestoreService.obtenerTodosPresupuestos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.lato(fontSize: 14.sp),
            ),
          );
        }

        final presupuestos = _aplicarFiltros(snapshot.data ?? []);

        if (presupuestos.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.history_rounded,
            title: 'No hay presupuestos',
            subtitle: 'Los presupuestos creados aparecerán aquí',
          );
        }

        // Ordenar por fecha de creación (más recientes primero)
        presupuestos.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });

        return CustomRefreshIndicator(
          onRefresh: () async {
            await _firestoreService.verificarYRenovarPresupuestos();
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16.r, 8.h, 16.r, 100.h),
            itemCount: presupuestos.length + 1, // +1 for summary
            itemBuilder: (context, index) {
              if (index == 0) {
                return FadeIn(
                  duration: const Duration(milliseconds: 200),
                  child: _buildSummaryHeader(presupuestos),
                );
              }
              final presupuesto = presupuestos[index - 1];
              return FadeIn(
                duration: Duration(milliseconds: 250 + (index * 40)),
                child: BudgetCardWidget(
                  budget: presupuesto,
                  isCompact: true,
                  onTap: () => _verDetallePresupuesto(presupuesto),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Budget> _aplicarFiltros(List<Budget> presupuestos) {
    var filtrados = presupuestos;

    if (_filtroPeriodo != null) {
      filtrados = filtrados.where((p) => p.periodo == _filtroPeriodo).toList();
    }

    if (_filtroCategoria != null) {
      filtrados =
          filtrados.where((p) {
            if (p.aplicaTodasCategorias) return true;
            return p.categorias.contains(_filtroCategoria);
          }).toList();
    }

    return filtrados;
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  20.h,
                  20.w,
                  MediaQuery.of(context).viewInsets.bottom + 20.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtros',
                          style: GoogleFonts.poppins(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _filtroCategoria = null;
                              _filtroPeriodo = null;
                            });
                            setState(() {});
                          },
                          child: Text(
                            'Limpiar',
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Filtro período
                    Text(
                      'Período',
                      style: GoogleFonts.lato(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      children: [
                        AnimatedFilterChip(
                          label: 'Semanal',
                          selected: _filtroPeriodo == 'semanal',
                          onSelected: (selected) {
                            setModalState(() {
                              _filtroPeriodo = selected ? 'semanal' : null;
                            });
                            setState(() {});
                          },
                        ),
                        AnimatedFilterChip(
                          label: 'Mensual',
                          selected: _filtroPeriodo == 'mensual',
                          onSelected: (selected) {
                            setModalState(() {
                              _filtroPeriodo = selected ? 'mensual' : null;
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Botón aplicar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Aplicar filtros',
                          style: GoogleFonts.lato(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _crearNuevoPresupuesto() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearPresupuestoScreen()),
    );
  }

  void _verDetallePresupuesto(Budget presupuesto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PresupuestoDetalleScreen(presupuesto: presupuesto),
      ),
    );
  }
}
