import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      (sum, cuenta) => sum + (cuenta.saldo ?? 0),
    );

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4facfe).withOpacity(0.3),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Total',
                      style: GoogleFonts.openSans(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _currencyFormat.format(saldoTotal),
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDialogoEditarSaldo(cuenta),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4facfe).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset(
                      'assets/images/${cuenta.imagen}.png',
                      width: 56.w,
                      height: 56.h,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.account_balance_wallet,
                          color: const Color(0xFF4facfe),
                          size: 28.sp,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuenta.nombre,
                        style: GoogleFonts.lato(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              themeManager.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (cuenta.beneficiario != null) ...[
                        Text(
                          cuenta.beneficiario!,
                          style: GoogleFonts.openSans(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],
                      if (cuenta.numeroTarjeta != null)
                        Text(
                          '**** ${cuenta.numeroTarjeta!.substring(cuenta.numeroTarjeta!.length - 4)}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 11.sp,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(cuenta.saldo ?? 0),
                      style: GoogleFonts.lato(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4facfe),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4facfe).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 12.sp,
                            color: const Color(0xFF4facfe),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Editar',
                            style: GoogleFonts.openSans(
                              fontSize: 10.sp,
                              color: const Color(0xFF4facfe),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  void _mostrarDialogoEditarSaldo(Account cuenta) {
    final TextEditingController saldoController = TextEditingController(
      text: (cuenta.saldo ?? 0).toStringAsFixed(2),
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
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF4facfe).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: const Color(0xFF4facfe),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar Saldo',
                      style: GoogleFonts.lato(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            themeManager.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    Text(
                      cuenta.nombre,
                      style: GoogleFonts.openSans(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.blue.shade200, width: 1.w),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Ingresa el nuevo saldo de la cuenta',
                          style: GoogleFonts.openSans(
                            fontSize: 11.sp,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: saldoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  style: GoogleFonts.lato(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color:
                        themeManager.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nuevo Saldo',
                    labelStyle: GoogleFonts.openSans(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(10.r),
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.attach_money_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF4facfe),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        themeManager.isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un monto';
                    }
                    final double? monto = double.tryParse(value.trim());
                    if (monto == null) {
                      return 'Monto inválido';
                    }
                    if (monto < 0) {
                      return 'El monto no puede ser negativo';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.openSans(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _actualizarSaldo(
                    cuenta,
                    double.parse(saldoController.text.trim()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4facfe),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                'Actualizar',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _actualizarSaldo(Account cuenta, double nuevoSaldo) async {
    setState(() => isLoading = true);
    try {
      final apiService = ApiService();
      final response = await apiService.updateAccountBalance(
        idCuenta: cuenta.idCuenta!,
        nuevoSaldo: nuevoSaldo,
      );

      if (mounted) {
        // Recargar datos
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.loadData();

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
                    response.msgE,
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
}
