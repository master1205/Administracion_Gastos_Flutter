import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notificaciones/models/Budget.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/widgets/animations.dart';
import 'package:notificaciones/widgets/budget_widgets.dart';
import 'package:notificaciones/crear_presupuesto_screen.dart';
import 'package:notificaciones/componentes/heads_up_notification.dart';
import 'package:notificaciones/widgets/confirmation_dialog.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Presupuestos',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _firestoreService.verificarYRenovarPresupuestos();
              setState(() {});
            },
            tooltip: 'Renovar presupuestos',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelStyle: GoogleFonts.lato(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [Tab(text: 'Activos'), Tab(text: 'Todos')],
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
            padding: EdgeInsets.fromLTRB(0, 16.h, 0, 100.h),
            itemCount: presupuestos.length,
            itemBuilder: (context, index) {
              final presupuesto = presupuestos[index];
              return AnimatedListItem(
                index: index,
                enableHero: false,
                child: BudgetCardWidget(
                  budget: presupuesto,
                  onTap: () => _verDetallePresupuesto(presupuesto),
                  onEdit: () => _editarPresupuesto(presupuesto),
                  onDelete: () => _confirmarEliminarPresupuesto(presupuesto),
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
            padding: EdgeInsets.fromLTRB(0, 16.h, 0, 100.h),
            itemCount: presupuestos.length,
            itemBuilder: (context, index) {
              final presupuesto = presupuestos[index];
              return AnimatedListItem(
                index: index,
                enableHero: false,
                child: BudgetCardWidget(
                  budget: presupuesto,
                  onTap: () => _verDetallePresupuesto(presupuesto),
                  onEdit: () => _editarPresupuesto(presupuesto),
                  onDelete: () => _confirmarEliminarPresupuesto(presupuesto),
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

  void _editarPresupuesto(Budget presupuesto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearPresupuestoScreen(presupuesto: presupuesto),
      ),
    );
  }

  void _confirmarEliminarPresupuesto(Budget presupuesto) async {
    final confirmar = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar presupuesto?',
      message:
          'Se eliminará "${presupuesto.nombre}". Las transacciones no se verán afectadas.',
      confirmText: 'Eliminar',
      confirmColor: Theme.of(context).colorScheme.error,
      icon: Icons.delete_rounded,
    );

    if (confirmar == true && mounted) {
      try {
        await _firestoreService.eliminarPresupuesto(presupuesto.id);
        if (mounted) {
          showSuccessNotification(context, message: 'Presupuesto eliminado');
        }
      } catch (e) {
        if (mounted) {
          showErrorNotification(
            context,
            message: 'Error al eliminar',
            subtitle: '$e',
          );
        }
      }
    }
  }
}
