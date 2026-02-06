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
          'Cuentas',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
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
                color: Colors.black.withOpacity(0.1),
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
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Agrega tu primera cuenta para\ncomenzar a administrar tu dinero',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
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

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Text(
                    'Saldo Total',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: theme.colorScheme.secondary.withOpacity(0.7),
                      size: 14.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${cuentas.length} cuenta${cuentas.length != 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: theme.colorScheme.secondary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            _currencyFormat.format(saldoTotal),
            style: GoogleFonts.poppins(
              color: theme.colorScheme.primary,
              fontSize: 32.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.secondary.withOpacity(0.6),
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Toca una cuenta para editar',
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
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
    final saldoColor =
        cuenta.saldo >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDialogoEditarSaldo(cuenta),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(18.r),
            child: Row(
              children: [
                // Imagen/Icono de la cuenta
                Container(
                  width: 54.w,
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: Image.asset(
                      'assets/images/${cuenta.imagen}.png',
                      width: 54.w,
                      height: 54.h,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.account_balance_wallet_rounded,
                          color: theme.colorScheme.primary,
                          size: 26.sp,
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
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      if (cuenta.beneficiario != null &&
                          cuenta.beneficiario!.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 13.sp,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.6,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                cuenta.beneficiario!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                      ],
                      if (cuenta.numeroTarjeta != null &&
                          cuenta.numeroTarjeta!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 13.sp,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.5,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '•••• ${cuenta.numeroTarjeta!.substring(cuenta.numeroTarjeta!.length - 4)}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11.sp,
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.6,
                                ),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Saldo y acciones
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(cuenta.saldo),
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: saldoColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón editar
                        InkWell(
                          onTap: () => _mostrarDialogoEditarSaldo(cuenta),
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 20.sp,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        // Botón eliminar
                        InkWell(
                          onTap: () => _confirmarEliminarCuenta(cuenta),
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 20.sp,
                              color: const Color(0xFFEF4444).withOpacity(0.7),
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
        ),
      ),
    );
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
              color: theme.colorScheme.background,
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
                          style: GoogleFonts.lato(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
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
                        style: GoogleFonts.openSans(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
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
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Entendido',
                            style: GoogleFonts.lato(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
      confirmColor: Colors.red.shade400,
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
