import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'data_provider.dart';
import 'utils/haptic_utils.dart';
import 'models/Meta.dart';
import 'models/api_response.dart';
import 'widgets/animations.dart';
import 'widgets/animated_card.dart';
import 'widgets/budget_widgets.dart';
import 'crear_meta_screen.dart';
import 'meta_detalle_screen.dart';
import 'componentes/heads_up_notification.dart';

class MetasScreen extends StatefulWidget {
  final Color? headerColor;

  const MetasScreen({super.key, this.headerColor});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen>
    with TickerProviderStateMixin {
  bool _isManualRefresh = false;
  late TabController _tabController;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    setState(() => _isManualRefresh = true);
    // DataProvider streams se actualizan automáticamente
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isManualRefresh = false);
    });
  }

  Future<void> _crearMeta() async {
    Haptics.light();
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
                          style: Theme.of(context).textTheme.titleSmall,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Builder(
            builder: (context) {
              final metas = Provider.of<DataProvider>(context).metas;
              final countActivas = metas.where((m) => !m.completada).length;
              final countCompletadas = metas.where((m) => m.completada).length;

              return TabBar(
                controller: _tabController,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.labelMedium,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                  0.5,
                ),
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  _buildTab('Activas', countActivas, theme),
                  _buildTab('Completadas', countCompletadas, theme),
                ],
              );
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              final metas = Provider.of<DataProvider>(context).metas;
              final activas = metas.where((m) => !m.completada).toList();
              final completadas = metas.where((m) => m.completada).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(
                    activas,
                    'Sin metas activas',
                    'Crea tu primera meta de ahorro',
                  ),
                  _buildTabContent(
                    completadas,
                    'Sin metas completadas',
                    'Las metas completadas aparecerán aquí',
                  ),
                ],
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
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _crearMeta,
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
                style: theme.textTheme.labelSmall?.copyWith(
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
    List<Meta> metas,
    String emptyTitle,
    String emptySubtitle,
  ) {
    final theme = Theme.of(context);

    if (metas.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.savings_outlined,
                size: 56.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
              SizedBox(height: 16.h),
              Text(
                emptyTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calcular resumen
    final totalAhorrado = metas.fold<double>(
      0,
      (sum, m) => sum + m.montoActual,
    );
    final totalObjetivo = metas.fold<double>(
      0,
      (sum, m) => sum + m.montoObjetivo,
    );

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.r,
        right: 16.r,
        top: 8.r,
        bottom: 70.h + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: metas.length + 1, // +1 for summary
      itemBuilder: (context, index) {
        if (index == 0) {
          return FadeIn(
            duration: const Duration(milliseconds: 200),
            child: _buildSummaryHeader(
              metas.length,
              totalAhorrado,
              totalObjetivo,
            ),
          );
        }
        final meta = metas[index - 1];
        return FadeIn(
          duration: Duration(milliseconds: 250 + (index * 40)),
          child: _buildMetaCard(meta),
        );
      },
    );
  }

  Widget _buildSummaryHeader(int count, double ahorrado, double objetivo) {
    final theme = Theme.of(context);
    final progreso = objetivo > 0 ? (ahorrado / objetivo * 100) : 0.0;

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
                  '$count meta${count != 1 ? 's' : ''}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_currencyFormat.format(ahorrado)} de ${_currencyFormat.format(objetivo)}',
                  style: theme.textTheme.bodySmall?.copyWith(
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
                  style: theme.textTheme.labelSmall?.copyWith(
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

  Widget _buildMetaCard(Meta meta) {
    final theme = Theme.of(context);
    final colorHex = int.parse('FF${meta.color}', radix: 16);
    final color = Color(colorHex);

    // Urgencia: próximos 7 días
    final diasRestantes = meta.diasRestantes;
    final esUrgente =
        !meta.completada && diasRestantes >= 0 && diasRestantes <= 7;

    // Status badge
    String estadoLabel = '';
    IconData? estadoIcon;
    Color estadoBgColor = Colors.white.withOpacity(0.25);
    if (meta.completada) {
      estadoLabel = 'Completada';
      estadoIcon = Icons.check_circle_rounded;
    } else if (meta.estaProxima) {
      estadoLabel = 'Casi listo';
      estadoIcon = Icons.local_fire_department_rounded;
      estadoBgColor = Colors.amber.withOpacity(0.3);
    }

    return AnimatedCard(
      color: meta.completada ? Colors.green : color,
      randomOffset: meta.nombre.length,
      horizontalMargin: 0,
      borderRadius: 16.r,
      borderColor:
          esUrgente ? Colors.red.withOpacity(0.5) : color.withOpacity(0.2),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MetaDetalleScreen(meta: meta),
          ),
        );
      },
      headerContent: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _getIconData(meta.icono),
              size: 18.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.nombre,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.descripcion.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    meta.descripcion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (meta.cuentaNombre != null &&
                    meta.cuentaNombre!.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    meta.cuentaNombre!,
                    style: theme.textTheme.bodySmall?.copyWith(
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
                    style: theme.textTheme.labelSmall?.copyWith(
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
                    style: theme.textTheme.labelSmall?.copyWith(
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
                    progreso: meta.progreso,
                    color: color,
                    height: 10.h,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${meta.progreso.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
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
                // Ahorrado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahorrado',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(meta.montoActual),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Objetivo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Objetivo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _currencyFormat.format(meta.montoObjetivo),
                        style: theme.textTheme.bodyMedium?.copyWith(
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
                            Icons.flag_rounded,
                            size: 11.sp,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.45,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            _formatDate(meta.fechaObjetivo),
                            style: theme.textTheme.bodySmall?.copyWith(
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
                            Icons.timer_rounded,
                            size: 10.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            meta.diasRestantes > 0
                                ? '${meta.diasRestantes} días'
                                : 'Vencida',
                            style: theme.textTheme.labelSmall?.copyWith(
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
      return DateFormat('dd MMM', 'es').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
