import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:flutter_multi_formatter/formatters/money_input_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'models/Account.dart';
import 'data_provider.dart';
import 'theme_provider.dart';
import 'api_service.dart';

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
              ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3.w,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4facfe),
                  ),
                ),
              )
              : cuentas.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: () async {
                  await dataProvider.loadData();
                },
                color: const Color(0xFF4facfe),
                child: ListView(
                  padding: EdgeInsets.all(16.r),
                  children: [
                    _buildResumenTotal(cuentas, themeManager),
                    SizedBox(height: 20.h),
                    ...cuentas.map(
                      (cuenta) => _buildCuentaCard(cuenta, themeManager),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoCrearCuenta(context),
        backgroundColor: const Color(0xFF4facfe),
        child: Icon(Icons.add, size: 28.sp),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 100.sp,
            color: Colors.grey.shade400,
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

  Future<void> _confirmarEliminarCuenta(Account cuenta) async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 340.w,
              padding: EdgeInsets.all(28.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFef4444).withOpacity(0.2),
                          const Color(0xFFdc2626).withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      size: 40.sp,
                      color: const Color(0xFFef4444),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '¿Eliminar cuenta?',
                    style: GoogleFonts.lato(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color:
                          themeManager.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFef4444).withOpacity(0.3),
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
          ),
    );

    if (confirmar == true) {
      setState(() => isLoading = true);
      try {
        final apiService = ApiService();
        await apiService.eliminarCuenta(cuenta.id);

        // Firebase notifica automáticamente vía Stream, no necesitamos recargar manualmente

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                  SizedBox(width: 10.w),
                  Text('Cuenta eliminada exitosamente'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _mostrarDialogoEditarSaldo(Account cuenta) {
    final TextEditingController saldoController = TextEditingController(
      text: cuenta.saldo.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final themeManager = Provider.of<ThemeManager>(context, listen: false);

        return AlertDialog(
          backgroundColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 360.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con gradiente
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Editar Saldo',
                        style: GoogleFonts.lato(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        cuenta.nombre,
                        style: GoogleFonts.openSans(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form content
                Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667eea).withOpacity(0.1),
                                const Color(0xFF764ba2).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(0xFF667eea).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Saldo Actual',
                                style: GoogleFonts.openSans(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _currencyFormat.format(cuenta.saldo),
                                style: GoogleFonts.lato(
                                  fontSize: 28.sp,
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
                        SizedBox(height: 24.h),
                        TextFormField(
                          controller: saldoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            MoneyInputFormatter(
                              leadingSymbol: '',
                              thousandSeparator: ThousandSeparator.Comma,
                              mantissaLength: 2,
                            ),
                          ],
                          autofocus: true,
                          style: GoogleFonts.lato(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF667eea),
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'Nuevo Saldo',
                            labelStyle: GoogleFonts.openSans(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                            prefixText: '\$ ',
                            prefixStyle: GoogleFonts.lato(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF667eea),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF667eea),
                                width: 2.5,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                themeManager.isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 20.h,
                              horizontal: 16.w,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa un monto';
                            }
                            final cleanValue = value.trim().replaceAll(',', '');
                            final double? monto = double.tryParse(cleanValue);
                            if (monto == null) {
                              return 'Monto inválido';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 2,
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
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF667eea,
                                      ).withOpacity(0.4),
                                      blurRadius: 12.r,
                                      offset: Offset(0, 6.h),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      Navigator.pop(context);
                                      final cleanValue = saldoController.text
                                          .trim()
                                          .replaceAll(',', '');
                                      await _actualizarSaldo(
                                        cuenta,
                                        double.parse(cleanValue),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Actualizar',
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _actualizarSaldo(Account cuenta, double nuevoSaldo) async {
    setState(() => isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.updateAccountBalance(
        cuentaId: cuenta.id,
        nuevoSaldo: nuevoSaldo,
      );

      // Firebase notifica automáticamente vía Stream, no necesitamos recargar manualmente

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Saldo actualizado exitosamente',
                    style: GoogleFonts.openSans(fontSize: 13.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Error al actualizar: $e',
                    style: GoogleFonts.openSans(fontSize: 13.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Diálogo para crear una nueva cuenta
  Future<void> _mostrarDialogoCrearCuenta(BuildContext context) async {
    final nombreController = TextEditingController();
    final saldoController = TextEditingController(text: '0');
    final beneficiarioController = TextEditingController();
    String tipoSeleccionado = 'efectivo';

    final tipos = ['efectivo', 'banco', 'tarjeta'];
    final iconos = {'efectivo': '💵', 'banco': '🏦', 'tarjeta': '💳'};

    return showDialog(
      context: context,
      builder: (context) {
        final themeManager = Provider.of<ThemeManager>(context, listen: false);

        return StatefulBuilder(
          builder:
              (context, setDialogState) => AlertDialog(
                backgroundColor:
                    themeManager.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                contentPadding: EdgeInsets.zero,
                content: Container(
                  width: 380.w,
                  constraints: BoxConstraints(maxHeight: 600.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con gradiente
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.r),
                            topRight: Radius.circular(24.r),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_card_rounded,
                                color: Colors.white,
                                size: 32.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Nueva Cuenta',
                              style: GoogleFonts.lato(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Completa la información',
                              style: GoogleFonts.openSans(
                                fontSize: 13.sp,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form content con Flexible para permitir scroll
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(24.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre de la cuenta
                              Text(
                                'Nombre de la cuenta',
                                style: GoogleFonts.lato(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: nombreController,
                                style: GoogleFonts.openSans(
                                  fontSize: 15.sp,
                                  color:
                                      themeManager.isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ej: Efectivo, Banco BBVA',
                                  hintStyle: GoogleFonts.openSans(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 20.sp,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF667eea),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor:
                                      themeManager.isDarkMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade50,
                                ),
                                textCapitalization: TextCapitalization.words,
                              ),
                              SizedBox(height: 20.h),

                              // Tipo de cuenta con cards
                              Text(
                                'Tipo de cuenta',
                                style: GoogleFonts.lato(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children:
                                    tipos.map((tipo) {
                                      final isSelected =
                                          tipoSeleccionado == tipo;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap:
                                              () => setDialogState(
                                                () => tipoSeleccionado = tipo,
                                              ),
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 4.w,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 14.h,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  isSelected
                                                      ? const LinearGradient(
                                                        colors: [
                                                          Color(0xFF667eea),
                                                          Color(0xFF764ba2),
                                                        ],
                                                      )
                                                      : null,
                                              color:
                                                  isSelected
                                                      ? null
                                                      : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? Colors.transparent
                                                        : Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  iconos[tipo]!,
                                                  style: TextStyle(
                                                    fontSize: 26.sp,
                                                  ),
                                                ),
                                                SizedBox(height: 6.h),
                                                Text(
                                                  tipo.toUpperCase(),
                                                  style: GoogleFonts.lato(
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors
                                                                .grey
                                                                .shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              SizedBox(height: 20.h),

                              // Beneficiario
                              Text(
                                'Beneficiario (opcional)',
                                style: GoogleFonts.lato(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: beneficiarioController,
                                style: GoogleFonts.openSans(
                                  fontSize: 15.sp,
                                  color:
                                      themeManager.isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ej: Juan Pérez',
                                  hintStyle: GoogleFonts.openSans(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    size: 20.sp,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF667eea),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor:
                                      themeManager.isDarkMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade50,
                                ),
                                textCapitalization: TextCapitalization.words,
                              ),
                              SizedBox(height: 20.h),

                              // Saldo inicial
                              Text(
                                'Saldo inicial',
                                style: GoogleFonts.lato(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: saldoController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  MoneyInputFormatter(
                                    leadingSymbol: '',
                                    thousandSeparator: ThousandSeparator.Comma,
                                    mantissaLength: 2,
                                  ),
                                ],
                                style: GoogleFonts.lato(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF667eea),
                                ),
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  prefixStyle: GoogleFonts.lato(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF667eea),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF667eea),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor:
                                      themeManager.isDarkMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade50,
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Botones de acción
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14.h,
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
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
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF667eea),
                                            Color(0xFF764ba2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF667eea,
                                            ).withOpacity(0.4),
                                            blurRadius: 12.r,
                                            offset: Offset(0, 6.h),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (nombreController.text
                                              .trim()
                                              .isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Ingresa un nombre para la cuenta',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.fixed,
                                              ),
                                            );
                                            return;
                                          }

                                          // Guardar el context del Scaffold antes de cerrar el diálogo
                                          final scaffoldContext = this.context;

                                          Navigator.pop(context);

                                          // Mostrar loading
                                          showDialog(
                                            context: scaffoldContext,
                                            barrierDismissible: false,
                                            builder:
                                                (loadingContext) => Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                          );

                                          try {
                                            final apiService = ApiService();
                                            final cleanValue = saldoController
                                                .text
                                                .replaceAll(',', '');
                                            final saldo =
                                                double.tryParse(cleanValue) ??
                                                0.0;

                                            // Generar número de tarjeta aleatorio (últimos 4 dígitos)
                                            final random =
                                                DateTime.now()
                                                    .millisecondsSinceEpoch %
                                                10000;
                                            final numeroTarjeta =
                                                '****${random.toString().padLeft(4, '0')}';

                                            await apiService.crearCuenta(
                                              nombre:
                                                  nombreController.text.trim(),
                                              tipo: tipoSeleccionado,
                                              saldoInicial: saldo,
                                              imagen: iconos[tipoSeleccionado]!,
                                              beneficiario:
                                                  beneficiarioController.text
                                                      .trim(),
                                              numeroTarjeta: numeroTarjeta,
                                            );

                                            // Firebase notifica automáticamente vía Stream, no necesitamos recargar manualmente

                                            if (mounted) {
                                              Navigator.of(
                                                scaffoldContext,
                                              ).pop(); // Cerrar loading
                                              ScaffoldMessenger.of(
                                                scaffoldContext,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.check_circle,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 10.w),
                                                      Text(
                                                        'Cuenta creada exitosamente',
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.fixed,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              Navigator.of(
                                                scaffoldContext,
                                              ).pop(); // Cerrar loading
                                              ScaffoldMessenger.of(
                                                scaffoldContext,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.fixed,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 14.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline,
                                              size: 20.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Crear Cuenta',
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
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }
}
