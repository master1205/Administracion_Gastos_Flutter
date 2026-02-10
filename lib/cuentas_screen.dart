import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notificaciones/widgets/confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'componentes/heads_up_notification.dart';
import 'models/Account.dart';
import 'data_provider.dart';
import 'theme_provider.dart';
import 'api_service.dart';
import 'services/firestore_service.dart';
import 'utils/haptic_utils.dart';
import 'widgets/animations.dart';
import 'crear_cuenta_screen.dart';
import 'widgets/shimmer_loading.dart';

class CuentasScreen extends StatefulWidget {
  const CuentasScreen({Key? key}) : super(key: key);

  @override
  State<CuentasScreen> createState() => _CuentasScreenState();
}

class _CuentasScreenState extends State<CuentasScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final cuentas = dataProvider.cuentas;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
            size: 22.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Mis Cuentas',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body:
          isLoading
              ? ShimmerList(shimmerItem: CuentaCardShimmer(), itemCount: 3)
              : cuentas.isEmpty
              ? _buildEmptyState()
              : ListView(
                padding: EdgeInsets.only(
                  left: 16.r,
                  right: 16.r,
                  top: 16.r,
                  bottom: 70.h + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  FadeIn(
                    duration: Duration(milliseconds: 300),
                    child: _buildResumenTotal(cuentas, themeManager),
                  ),
                  SizedBox(height: 20.h),
                  ...cuentas.asMap().entries.map(
                    (entry) => FadeIn(
                      duration: Duration(milliseconds: 350 + (entry.key * 50)),
                      child: _buildCuentaCard(entry.value, themeManager),
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
              onTap: () => _mostrarDialogoCrearCuenta(context),
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

  Widget _buildEmptyState() {
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
                    Icons.account_balance_wallet_outlined,
                    size: 64.sp,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                'Sin cuentas',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Agrega tu primera cuenta para\ncomenzar a administrar tu dinero',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
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

  Widget _buildResumenTotal(List<Account> cuentas, ThemeManager themeManager) {
    final theme = Theme.of(context);
    final saldoTotal = cuentas.fold<double>(
      0,
      (sum, cuenta) => sum + cuenta.saldo,
    );
    final retenidoTotal = cuentas.fold<double>(
      0,
      (sum, cuenta) => sum + cuenta.saldoRetenido,
    );
    final disponibleTotal = saldoTotal - retenidoTotal;
    final retainedPercent = saldoTotal > 0 ? retenidoTotal / saldoTotal : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.secondary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22.r, 22.r, 22.r, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: theme.colorScheme.primary,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance Total',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _currencyFormat.format(saldoTotal),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${cuentas.length} cuenta${cuentas.length != 1 ? 's' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (retenidoTotal > 0) ...[
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 22.r),
              child: Column(
                children: [
                  // Barra visual de distribución
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: SizedBox(
                      height: 8.h,
                      child: Row(
                        children: [
                          Expanded(
                            flex: ((1 - retainedPercent) * 100).round().clamp(
                              1,
                              100,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF10B981),
                                    const Color(0xFF10B981).withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: (retainedPercent * 100).round().clamp(1, 100),
                            child: Container(
                              color: const Color(0xFFFF9800).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryMiniCard(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Disponible',
                          amount: disponibleTotal,
                          color: const Color(0xFF10B981),
                          theme: theme,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _buildSummaryMiniCard(
                          icon: Icons.lock_outline_rounded,
                          label: 'Apartado',
                          amount: retenidoTotal,
                          color: const Color(0xFFFF9800),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 18.h),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.8),
                  ),
                ),
                Text(
                  _currencyFormat.format(amount),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuentaCard(Account cuenta, ThemeManager themeManager) {
    final theme = Theme.of(context);
    final saldoDisponible = cuenta.saldoDisponible;
    final accentColor = _getAccountColor(cuenta);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.03),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDialogoEditarSaldo(cuenta),
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18.r, 18.r, 18.r, 14.r),
                child: Row(
                  children: [
                    // Imagen de la cuenta con borde de acento
                    Container(
                      width: 52.w,
                      height: 52.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.asset(
                          'assets/images/${cuenta.imagen}.png',
                          width: 52.w,
                          height: 52.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: accentColor.withOpacity(0.08),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: accentColor,
                                size: 24.sp,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // Información de la cuenta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cuenta.nombre,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              if (cuenta.numeroTarjeta != null &&
                                  cuenta.numeroTarjeta!.isNotEmpty) ...[
                                Icon(
                                  Icons.credit_card_rounded,
                                  size: 12.sp,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.35),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '•••• ${cuenta.numeroTarjeta!.substring(cuenta.numeroTarjeta!.length - 4)}',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 11.sp,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                              if (cuenta.beneficiario != null &&
                                  cuenta.beneficiario!.isNotEmpty) ...[
                                if (cuenta.numeroTarjeta != null &&
                                    cuenta.numeroTarjeta!.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                    ),
                                    child: Text(
                                      '·',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.25),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    cuenta.beneficiario!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Saldo principal
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(cuenta.saldo),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                cuenta.saldo >= 0
                                    ? theme.colorScheme.onSurface
                                    : const Color(0xFFEF4444),
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (cuenta.saldoRetenido > 0)
                          Text(
                            'Disp: ${_currencyFormat.format(saldoDisponible)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  saldoDisponible >= 0
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Barra inferior con apartado + acciones
              Container(
                padding: EdgeInsets.fromLTRB(18.r, 0, 10.r, 10.r),
                child: Row(
                  children: [
                    if (cuenta.saldoRetenido > 0) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 12.sp,
                              color: const Color(0xFFFF9800),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Apartado: ${_currencyFormat.format(cuenta.saldoRetenido)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Botón editar
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      onTap: () => _mostrarDialogoEditarSaldo(cuenta),
                    ),
                    SizedBox(width: 2.w),
                    // Botón eliminar
                    _buildActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFEF4444).withOpacity(0.5),
                      onTap: () => _confirmarEliminarCuenta(cuenta),
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Haptics.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.all(8.r),
        child: Icon(icon, size: 20.sp, color: color),
      ),
    );
  }

  Color _getAccountColor(Account cuenta) {
    // Asignar colores según el nombre de la imagen o un hash del nombre
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFF4facfe),
      const Color(0xFFf093fb),
      const Color(0xFF30cfd0),
      const Color(0xFFfa709a),
      const Color(0xFF5f27cd),
      const Color(0xFF10B981),
      const Color(0xFFfeca57),
    ];
    return colors[cuenta.nombre.hashCode.abs() % colors.length];
  }

  Future<void> _mostrarDialogoCuentaAsociadaAMeta() async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf59e0b).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFf59e0b),
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Cuenta asociada a meta',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(28.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf59e0b).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 48.sp,
                          color: const Color(0xFFf59e0b),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Esta cuenta está asociada a una meta de ahorro. Puedes editarla o eliminarla desde la pantalla de Metas.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFf59e0b),
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Entendido',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
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
    );
  }

  Future<void> _confirmarEliminarCuenta(Account cuenta) async {
    // Verificar si la cuenta está asociada a una meta
    final firestoreService = FirestoreService();
    final estaAsociada = await firestoreService.cuentaEstaAsociadaAMeta(
      cuenta.id,
    );

    if (estaAsociada) {
      await _mostrarDialogoCuentaAsociadaAMeta();
      return;
    }

    final confirmar = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar cuenta?',
      message:
          'Se eliminará "${cuenta.nombre}" con saldo ${_currencyFormat.format(cuenta.saldo)}. Esta acción es permanente y no se puede deshacer.',
      confirmText: 'Eliminar',
      confirmColor: Theme.of(context).colorScheme.error,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmar == true) {
      setState(() => isLoading = true);
      try {
        final apiService = ApiService();
        await apiService.eliminarCuenta(cuenta.id);

        // Firebase notifica automáticamente vía Stream, no necesitamos recargar manualmente

        if (mounted) {
          showSuccessNotification(
            context,
            message: 'Cuenta eliminada exitosamente',
          );
        }
      } catch (e) {
        if (mounted) {
          showErrorNotification(
            context,
            message: 'Error al eliminar',
            subtitle: e.toString(),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Future<void> _mostrarDialogoEditarSaldo(Account cuenta) async {
    // Verificar si la cuenta está asociada a una meta
    final firestoreService = FirestoreService();
    final estaAsociada = await firestoreService.cuentaEstaAsociadaAMeta(
      cuenta.id,
    );

    if (estaAsociada) {
      await _mostrarDialogoCuentaAsociadaAMeta();
      return;
    }

    // Si no está asociada, permitir editar
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearCuentaScreen(cuenta: cuenta),
      ),
    );
  }

  // Diálogo para crear una nueva cuenta
  Future<void> _mostrarDialogoCrearCuenta(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CrearCuentaScreen()),
    );
  }
}
