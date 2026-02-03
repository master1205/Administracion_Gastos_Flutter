import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return Scaffold(
      backgroundColor:
          themeManager.isDarkMode
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Administrar Cuentas',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20.sp),
          onPressed: () => Navigator.pop(context),
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
                  bottom: 16.r + MediaQuery.of(context).padding.bottom + 80.h,
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
        fab: FloatingActionButton(
          onPressed: () => _mostrarDialogoCrearCuenta(context),
          backgroundColor:
              themeManager.isDarkMode
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF6366F1),
          shape: const CircleBorder(),
          elevation: 6,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28.sp),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SlideFadeTransition(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleIn(
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 100.sp,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No hay cuentas registradas',
              style: GoogleFonts.lato(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Contacta al administrador para agregar cuentas',
              style: GoogleFonts.openSans(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenTotal(List<Account> cuentas, ThemeManager themeManager) {
    final saldoTotal = cuentas.fold<double>(
      0,
      (sum, cuenta) => sum + cuenta.saldo,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(28.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.credit_card, color: Colors.white, size: 14.sp),
                    SizedBox(width: 6.w),
                    Text(
                      '${cuentas.length} cuenta${cuentas.length != 1 ? 's' : ''}',
                      style: GoogleFonts.lato(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'SALDO TOTAL',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _currencyFormat.format(saldoTotal),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 36.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  'Toca una cuenta para editar su saldo',
                  style: GoogleFonts.openSans(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11.sp,
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
    final saldoColor =
        cuenta.saldo >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color:
              themeManager.isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                themeManager.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8.r,
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
                  width: 68.w,
                  height: 68.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(0.15),
                        const Color(0xFF8B5CF6).withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.asset(
                      'assets/images/${cuenta.imagen}.png',
                      width: 64.w,
                      height: 64.h,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF667eea),
                          size: 32.sp,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // Información de la cuenta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuenta.nombre,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color:
                              themeManager.isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                          letterSpacing: -0.3,
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
                              size: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                cuenta.beneficiario!,
                                style: GoogleFonts.openSans(
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade600,
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
                              size: 14.sp,
                              color: Colors.grey.shade500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '•••• ${cuenta.numeroTarjeta!.substring(cuenta.numeroTarjeta!.length - 4)}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 12.sp,
                                color: Colors.grey.shade500,
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
                      style: GoogleFonts.inter(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        color: saldoColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón editar
                        GestureDetector(
                          onTap: () => _mostrarDialogoEditarSaldo(cuenta),
                          child: Container(
                            padding: EdgeInsets.all(9.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.12),
                                  const Color(0xFF8B5CF6).withOpacity(0.12),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 17.sp,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // Botón eliminar
                        GestureDetector(
                          onTap: () => _confirmarEliminarCuenta(cuenta),
                          child: Container(
                            padding: EdgeInsets.all(9.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.delete_rounded,
                              size: 17.sp,
                              color: const Color(0xFFEF4444),
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
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                            color:
                                themeManager.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
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

    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          '¿Eliminar cuenta?',
                          style: GoogleFonts.lato(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color:
                                themeManager.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
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
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_forever_rounded,
                          size: 48.sp,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFef4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(
                              0xFFef4444,
                            ).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              cuenta.nombre,
                              style: GoogleFonts.lato(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFef4444),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _currencyFormat.format(cuenta.saldo),
                              style: GoogleFonts.lato(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color:
                                    themeManager.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Esta acción es permanente y no se puede deshacer',
                        style: GoogleFonts.openSans(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 28.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.lato(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFef4444),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline, size: 18.sp),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Eliminar',
                                    style: GoogleFonts.lato(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
          ),
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
