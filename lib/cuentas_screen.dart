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
          themeManager.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Administrar Cuentas',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: const Color(0xFF4facfe),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.sp),
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
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFF4facfe),
          shape: const CircleBorder(),
          child: Icon(Icons.add, color: Colors.white, size: 28.sp),
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
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
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
            'Saldo Total',
            style: GoogleFonts.openSans(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _currencyFormat.format(saldoTotal),
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
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
        cuenta.saldo >= 0 ? const Color(0xFF10b981) : const Color(0xFFef4444);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color:
              themeManager.isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
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
                  width: 64.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea).withOpacity(0.2),
                        const Color(0xFF764ba2).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
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
                        style: GoogleFonts.lato(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              themeManager.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
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
                      style: GoogleFonts.lato(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: saldoColor,
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
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16.sp,
                              color: const Color(0xFF667eea),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Botón eliminar
                        GestureDetector(
                          onTap: () => _confirmarEliminarCuenta(cuenta),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFef4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16.sp,
                              color: const Color(0xFFef4444),
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
