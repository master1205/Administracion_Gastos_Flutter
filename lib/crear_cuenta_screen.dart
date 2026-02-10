import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'componentes/heads_up_notification.dart';
import 'models/Account.dart';
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
    final theme = Theme.of(context);
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
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            isEdit ? 'Editar Cuenta' : 'Nueva Cuenta',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        body: Column(
          children: [
            // Header con ícono
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h),
              decoration: BoxDecoration(
                color: colorTipo.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: colorTipo.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: colorTipo.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _iconos[_tipoSeleccionado]!,
                      style: TextStyle(fontSize: 40.sp),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Administra tus cuentas',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
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
                    _buildSectionTitle('Tipo de cuenta', theme),
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
                                    child: _buildTipoChip(tipo, theme),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Nombre
                    _buildSectionTitle('Nombre de la cuenta', theme),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _nombreController,
                      enabled: !isEdit,
                      textCapitalization: TextCapitalization.words,
                      decoration: _buildInputDecoration(
                        hintText: 'Ej: Cuenta Principal, Ahorros',
                        prefixIcon: Icons.account_balance_wallet,
                        theme: theme,
                        color: colorTipo,
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    SizedBox(height: 16.h),

                    // Saldo inicial
                    _buildSectionTitle(
                      isEdit ? 'Saldo actual' : 'Saldo inicial',
                      theme,
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
                          top: 10.h,
                          bottom: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: colorTipo.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.attach_money,
                                color: colorTipo,
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
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _saldoController.text.isNotEmpty
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.secondary
                                              .withOpacity(0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Beneficiario (opcional)
                    _buildSectionTitle('Beneficiario (opcional)', theme),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _beneficiarioController,
                      enabled: !isEdit,
                      textCapitalization: TextCapitalization.words,
                      decoration: _buildInputDecoration(
                        hintText: 'Nombre del titular',
                        prefixIcon: Icons.person_outline,
                        theme: theme,
                        color: colorTipo,
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
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
                              await _apiService.updateAccountBalance(
                                cuentaId: widget.cuenta!.id,
                                nuevoSaldo: saldo,
                              );
                            } else {
                              await _apiService.crearCuenta(
                                nombre: nombre,
                                tipo: _tipoSeleccionado,
                                saldoInicial: saldo,
                                beneficiario:
                                    _beneficiarioController.text.trim(),
                              );
                            }

                            if (mounted) {
                              showSuccessNotification(
                                context,
                                message:
                                    isEdit
                                        ? 'Cuenta actualizada'
                                        : 'Cuenta creada',
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
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor:
                              theme.colorScheme.onSecondaryContainer,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEdit ? 'Actualizar Cuenta' : 'Crear Cuenta',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.secondary.withOpacity(0.7),
      ),
    );
  }

  Widget _buildTipoChip(String tipo, ThemeData theme) {
    final isSelected = _tipoSeleccionado == tipo;
    final color = _colores[tipo]!;

    return GestureDetector(
      onTap: () => setState(() => _tipoSeleccionado = tipo),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withOpacity(0.1) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected
                    ? color.withOpacity(0.3)
                    : theme.colorScheme.secondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(_iconos[tipo]!, style: TextStyle(fontSize: 28.sp)),
            SizedBox(height: 4.h),
            Text(
              tipo[0].toUpperCase() + tipo.substring(1),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected
                        ? color
                        : theme.colorScheme.secondary.withOpacity(0.7),
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
    required ThemeData theme,
    required Color color,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.secondary.withOpacity(0.5),
      ),
      prefixIcon: Container(
        margin: EdgeInsets.all(10.r),
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(prefixIcon, color: color, size: 20.sp),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }
}
