import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'componentes/heads_up_notification.dart';
import 'models/Account.dart';
import 'theme_provider.dart';
import 'widgets/discard_changes_dialog.dart';
import 'widgets/select_amount.dart';

class CrearCuentaScreen extends StatefulWidget {
  final Account? cuenta;

  const CrearCuentaScreen({Key? key, this.cuenta}) : super(key: key);

  @override
  State<CrearCuentaScreen> createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State<CrearCuentaScreen> {
  final _nombreController = TextEditingController();
  final _saldoController = TextEditingController();
  final _beneficiarioController = TextEditingController();
  final _apiService = ApiService();

  String _tipoSeleccionado = 'efectivo';

  // Estado inicial para detectar cambios
  late String _initialNombre;
  late String _initialSaldo;
  late String _initialBeneficiario;
  late String _initialTipo;

  final Map<String, String> _iconos = {
    'efectivo': '💵',
    'banco': '🏦',
    'tarjeta': '💳',
  };

  final Map<String, Color> _colores = {
    'efectivo': const Color(0xFF43A047),
    'banco': const Color(0xFF1E88E5),
    'tarjeta': const Color(0xFFE53935),
  };

  @override
  void initState() {
    super.initState();
    if (widget.cuenta != null) {
      _nombreController.text = widget.cuenta!.nombre;
      _saldoController.text = widget.cuenta!.saldo.toString();
      _beneficiarioController.text = widget.cuenta!.beneficiario ?? '';
      _tipoSeleccionado = widget.cuenta!.tipo ?? 'efectivo';
    } else {
      _saldoController.text = '0';
    }
    _saveInitialState();
  }

  void _saveInitialState() {
    _initialNombre = _nombreController.text;
    _initialSaldo = _saldoController.text;
    _initialBeneficiario = _beneficiarioController.text;
    _initialTipo = _tipoSeleccionado;
  }

  bool _hasChanges() {
    return _nombreController.text != _initialNombre ||
        _saldoController.text.replaceAll(',', '') !=
            _initialSaldo.replaceAll(',', '') ||
        _beneficiarioController.text != _initialBeneficiario ||
        _tipoSeleccionado != _initialTipo;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges()) {
      return await DiscardChangesDialog.show(context);
    }
    return true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _saldoController.dispose();
    _beneficiarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;
    final isEdit = widget.cuenta != null;
    final colorTipo = _colores[_tipoSeleccionado]!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: colorTipo,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            isEdit ? 'Editar Cuenta' : 'Nueva Cuenta',
            style: GoogleFonts.lato(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          children: [
            // Header con ícono
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: colorTipo,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _iconos[_tipoSeleccionado]!,
                      style: TextStyle(fontSize: 48.sp),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Administra tus cuentas',
                    style: GoogleFonts.lato(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20.r,
                  right: 20.r,
                  top: 20.r,
                  bottom: 20.r + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo de cuenta
                    _buildSectionTitle('Tipo de cuenta', isDark),
                    SizedBox(height: 12.h),
                    IgnorePointer(
                      ignoring: isEdit,
                      child: Opacity(
                        opacity: isEdit ? 0.5 : 1.0,
                        child: Row(
                          children:
                              _iconos.keys.map((tipo) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                    ),
                                    child: _buildTipoChip(tipo, isDark),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Nombre
                    _buildSectionTitle('Nombre de la cuenta', isDark),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _nombreController,
                      enabled: !isEdit,
                      textCapitalization: TextCapitalization.words,
                      decoration: _buildInputDecoration(
                        hintText: 'Ej: Cuenta Principal, Ahorros',
                        prefixIcon: Icons.account_balance_wallet,
                        isDark: isDark,
                        color: colorTipo,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Saldo inicial
                    _buildSectionTitle(
                      isEdit ? 'Saldo actual' : 'Saldo inicial',
                      isDark,
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () async {
                        final currentAmount =
                            _saldoController.text.isNotEmpty
                                ? double.tryParse(
                                      _saldoController.text.replaceAll(',', ''),
                                    ) ??
                                    0.0
                                : 0.0;

                        final result = await showSelectAmountBottomSheet(
                          context,
                          title: 'Ingresa el saldo inicial',
                          initialAmount: currentAmount,
                          allowZero: true,
                          currencySymbol: '\$',
                        );

                        if (result != null) {
                          setState(() {
                            _saldoController.text = result.toStringAsFixed(2);
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 8.w,
                          right: 16.w,
                          top: 8.h,
                          bottom: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: colorTipo.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorTipo,
                                    colorTipo.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorTipo.withOpacity(0.3),
                                    blurRadius: 4.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.attach_money,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                _saldoController.text.isNotEmpty
                                    ? NumberFormat.currency(
                                      locale: 'es_MX',
                                      symbol: '\$',
                                      decimalDigits: 2,
                                    ).format(
                                      double.tryParse(
                                            _saldoController.text.replaceAll(
                                              ',',
                                              '',
                                            ),
                                          ) ??
                                          0.0,
                                    )
                                    : '\$ 0.00',
                                style: GoogleFonts.lato(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _saldoController.text.isNotEmpty
                                          ? (isDark
                                              ? Colors.white
                                              : Colors.black87)
                                          : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Beneficiario (opcional)
                    _buildSectionTitle('Beneficiario (opcional)', isDark),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _beneficiarioController,
                      enabled: !isEdit,
                      textCapitalization: TextCapitalization.words,
                      decoration: _buildInputDecoration(
                        hintText: 'Nombre del titular',
                        prefixIcon: Icons.person_outline,
                        isDark: isDark,
                        color: colorTipo,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 12.h),
          child: ElevatedButton(
            onPressed: () async {
              final nombre = _nombreController.text.trim();
              if (nombre.isEmpty) {
                showErrorNotification(
                  context,
                  message: 'El nombre es requerido',
                );
                return;
              }

              try {
                final saldo =
                    double.tryParse(
                      _saldoController.text.replaceAll(',', ''),
                    ) ??
                    0.0;

                if (isEdit) {
                  // Por ahora solo creamos cuentas nuevas
                  // La edición requiere implementación adicional en el backend
                  // Editar cuenta existente - solo actualizar saldo
                  await _apiService.updateAccountBalance(
                    cuentaId: widget.cuenta!.id,
                    nuevoSaldo: saldo,
                  );
                } else {
                  // Crear nueva cuenta
                  await _apiService.crearCuenta(
                    nombre: nombre,
                    tipo: _tipoSeleccionado,
                    saldoInicial: saldo,
                    beneficiario: _beneficiarioController.text.trim(),
                  );
                }

                if (mounted) {
                  showSuccessNotification(
                    context,
                    message: isEdit ? 'Cuenta actualizada' : 'Cuenta creada',
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  showErrorNotification(
                    context,
                    message: 'Error',
                    subtitle: e.toString(),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorTipo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
            ),
            child: Text(
              isEdit ? 'Actualizar Cuenta' : 'Crear Cuenta',
              style: GoogleFonts.lato(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTipoChip(String tipo, bool isDark) {
    final isSelected = _tipoSeleccionado == tipo;
    final color = _colores[tipo]!;

    return GestureDetector(
      onTap: () => setState(() => _tipoSeleccionado = tipo),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withOpacity(0.15)
                  : (isDark ? Colors.grey.shade800 : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected
                    ? color
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(_iconos[tipo]!, style: TextStyle(fontSize: 28.sp)),
            SizedBox(height: 4.h),
            Text(
              tipo[0].toUpperCase() + tipo.substring(1),
              style: GoogleFonts.lato(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected
                        ? color
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    required Color color,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.openSans(
        color: Colors.grey.shade400,
        fontSize: 12.sp,
      ),
      prefixIcon: Container(
        margin: EdgeInsets.all(10.r),
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Icon(prefixIcon, color: Colors.white, size: 20.sp),
      ),
      filled: true,
      fillColor: isDark ? Colors.grey.shade800 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }
}
