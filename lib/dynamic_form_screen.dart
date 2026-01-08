import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:flutter_multi_formatter/formatters/money_input_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/models/Transaccion.dart' as models;
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'utils/animation_utils.dart';

class TrasaccionScreen extends StatefulWidget {
  final String transactionType;
  final Color color;
  final Transaction? transaction;

  const TrasaccionScreen({
    super.key,
    required this.transactionType,
    required this.color,
    this.transaction,
  });

  @override
  State<TrasaccionScreen> createState() => _TrasaccionScreenState();
}

class _TrasaccionScreenState extends State<TrasaccionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isRegistering = false;
  bool _isInitialized = false;
  Categoria? selectedCategory;
  Account? selectedAccount;
  Account? selectedAccountFrom;
  Account? selectedAccountTo;

  String? amountError;
  String? descriptionError;
  String? categoryError;
  String? accountError;
  String? accountFromError;
  String? accountToError;

  final Map<String, IconData> categoryIconsMap = {
    'airplanemode_active_outlined': Icons.flight_outlined,
    'checkroom_outlined': Icons.checkroom_outlined,
    'pets_outlined': Icons.pets_outlined,
    'account_balance_wallet_outlined': Icons.account_balance_wallet_outlined,
    'credit_card_outlined': Icons.credit_card_outlined,
    'home_outlined': Icons.home_outlined,
    'location_city_outlined': Icons.apartment_outlined,
    'electrical_services_outlined': Icons.bolt_outlined,
    'security_outlined': Icons.shield_outlined,
    'receipt_long_outlined': Icons.receipt_long_outlined,
    'subscriptions_outlined': Icons.subscriptions_outlined,
    'attach_money_outlined': Icons.payments_outlined,
    'card_giftcard_outlined': Icons.card_giftcard_outlined,
    'trending_up_outlined': Icons.show_chart_outlined,
    'sell_outlined': Icons.sell_outlined,
    'monetization_on_outlined': Icons.account_balance_outlined,
    'redeem_outlined': Icons.redeem_outlined,
    'savings_outlined': Icons.savings_outlined,
    'restaurant_outlined': Icons.restaurant_outlined,
    'directions_car_outlined': Icons.directions_car_outlined,
    'movie_outlined': Icons.theaters_outlined,
    'school_outlined': Icons.school_outlined,
    'help_outline': Icons.category_outlined,
    'local_hospital_outlined': Icons.local_hospital_outlined,
    'shopping_cart': Icons.shopping_cart_outlined,
    'fastfood': Icons.fastfood_outlined,
    'local_grocery_store': Icons.local_grocery_store_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'sports_soccer': Icons.sports_soccer_outlined,
    'phone_android': Icons.phone_android_outlined,
    'laptop': Icons.laptop_outlined,
    'coffee': Icons.coffee_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'beach_access': Icons.beach_access_outlined,
    'hotel': Icons.hotel_outlined,
    'music_note': Icons.music_note_outlined,
    'palette': Icons.palette_outlined,
    'book': Icons.menu_book_outlined,
    'train': Icons.train_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'sports': Icons.sports_basketball_outlined,
    'celebration': Icons.celebration_outlined,
    'spa': Icons.spa_outlined,
    'local_pharmacy': Icons.local_pharmacy_outlined,
    'local_laundry_service': Icons.local_laundry_service_outlined,
    'self_improvement': Icons.self_improvement_outlined,
    'volunteer_activism': Icons.volunteer_activism_outlined,
    // Iconos adicionales sugeridos
    'medical_services_outlined': Icons.medical_services_outlined,
    'house_outlined': Icons.house_outlined,
    'water_drop_outlined': Icons.water_drop_outlined,
    'wifi_outlined': Icons.wifi_outlined,
    'tv_outlined': Icons.tv_outlined,
    'phone_outlined': Icons.phone_outlined,
    'groups_outlined': Icons.groups_outlined,
    'child_care_outlined': Icons.child_care_outlined,
    'elderly_outlined': Icons.elderly_outlined,
    'business_outlined': Icons.business_outlined,
    'work_outlined': Icons.work_outlined,
    'precision_manufacturing_outlined': Icons.precision_manufacturing_outlined,
    'agriculture_outlined': Icons.agriculture_outlined,
    'handyman_outlined': Icons.handyman_outlined,
    'currency_bitcoin_outlined': Icons.currency_bitcoin_outlined,
    'currency_exchange_outlined': Icons.currency_exchange_outlined,
    'account_balance': Icons.account_balance_outlined,
    'workspace_premium_outlined': Icons.workspace_premium_outlined,
    'casino_outlined': Icons.casino_outlined,
    'real_estate_outlined': Icons.real_estate_agent_outlined,
    'propane_tank': Icons.propane_tank_outlined,
    'emergency_outlined': Icons.emergency_outlined,
    'more_horiz': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _setupControllers();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.transaction != null && !_isInitialized) {
      _isInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);

        if (mounted) {
          setState(() {
            try {
              selectedCategory = dataProvider.categorias.firstWhere(
                (c) => c.categoria == widget.transaction!.categoria,
              );
            } catch (e) {
              selectedCategory =
                  dataProvider.categorias.isNotEmpty
                      ? dataProvider.categorias.first
                      : null;
            }

            if (widget.transactionType != 'Traspasos') {
              try {
                selectedAccount = dataProvider.cuentas.firstWhere(
                  (a) => a.nombre == widget.transaction!.cuenta,
                );
              } catch (e) {
                selectedAccount =
                    dataProvider.cuentas.isNotEmpty
                        ? dataProvider.cuentas.first
                        : null;
              }
            } else {
              try {
                selectedAccountFrom = dataProvider.cuentas.firstWhere(
                  (a) => a.nombre == widget.transaction!.cuentaOrigen,
                );
              } catch (e) {
                selectedAccountFrom =
                    dataProvider.cuentas.isNotEmpty
                        ? dataProvider.cuentas.first
                        : null;
              }

              try {
                selectedAccountTo = dataProvider.cuentas.firstWhere(
                  (a) => a.nombre == widget.transaction!.cuentaDestino,
                );
              } catch (e) {
                selectedAccountTo =
                    dataProvider.cuentas.length > 1
                        ? dataProvider.cuentas[1]
                        : dataProvider.cuentas.first;
              }
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => isLoading = true);
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => isLoading = false);
      });
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  void _setupControllers() {
    _descriptionController.addListener(() {
      final text = _descriptionController.text;
      final selection = _descriptionController.selection;
      final capitalized = text
          .split(' ')
          .map(
            (word) =>
                word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                    : '',
          )
          .join(' ');
      if (capitalized != text) {
        _descriptionController.value = TextEditingValue(
          text: capitalized,
          selection: selection,
        );
      }
    });
  }

  void _loadInitialData() {
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.monto.toString();
      _descriptionController.text = widget.transaction!.descripcion;
      selectedDate = DateTime.parse(widget.transaction!.fecha);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.color,
              onPrimary: Colors.white,
              surface:
                  themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
              onSurface: themeManager.isDarkMode ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor:
                themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  bool _validateForm() {
    setState(() {
      amountError = null;
      descriptionError = null;
      categoryError = null;
      accountError = null;
      accountFromError = null;
      accountToError = null;
    });

    bool isValid = true;

    // Validar monto
    if (_amountController.text.trim().isEmpty) {
      setState(() => amountError = 'Por favor ingresa un monto');
      isValid = false;
    } else {
      final amount = double.tryParse(
        _amountController.text.replaceAll(',', ''),
      );
      if (amount == null || amount <= 0) {
        setState(() => amountError = 'Ingresa un monto válido');
        isValid = false;
      }
    }

    // Validar descripción
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => descriptionError = 'Por favor ingresa una descripción');
      isValid = false;
    } else if (_descriptionController.text.trim().length < 3) {
      setState(
        () =>
            descriptionError =
                'La descripción debe tener al menos 3 caracteres',
      );
      isValid = false;
    }

    // Validar categoría (solo para Gastos, Ingresos, Pagos)
    if (widget.transactionType != 'Traspasos' &&
        widget.transactionType != 'Reembolsos') {
      if (selectedCategory == null) {
        setState(() => categoryError = 'Por favor selecciona una categoría');
        isValid = false;
      }
    }

    // Validar cuentas
    if (widget.transactionType != 'Traspasos') {
      if (selectedAccount == null) {
        setState(() => accountError = 'Por favor selecciona una cuenta');
        isValid = false;
      } else {
        // Validar saldo suficiente para gastos y pagos
        if (widget.transactionType == 'Gastos' ||
            widget.transactionType == 'Pagos') {
          final monto =
              double.tryParse(_amountController.text.replaceAll(',', '')) ??
              0.0;

          // En modo edición, considerar el monto anterior que ya fue restado
          double saldoDisponible = selectedAccount!.saldo;
          if (widget.transaction != null &&
              widget.transaction!.cuentaNombre == selectedAccount!.nombre) {
            // Si es edición y es la misma cuenta, sumar el monto anterior
            saldoDisponible += widget.transaction!.monto;
          }

          if (monto > saldoDisponible) {
            setState(
              () =>
                  accountError =
                      'Saldo insuficiente. Disponible: \$${saldoDisponible.toStringAsFixed(2)}',
            );
            isValid = false;
          }
        }
      }
    } else {
      if (selectedAccountFrom == null) {
        setState(
          () => accountFromError = 'Por favor selecciona la cuenta origen',
        );
        isValid = false;
      } else {
        // Validar saldo suficiente en cuenta origen para traspaso
        final monto =
            double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;

        // En modo edición, considerar el monto anterior que ya fue restado
        double saldoDisponible = selectedAccountFrom!.saldo;
        if (widget.transaction != null &&
            widget.transaction!.cuentaOrigenNombre ==
                selectedAccountFrom!.nombre) {
          // Si es edición y es la misma cuenta origen, sumar el monto anterior
          saldoDisponible += widget.transaction!.monto;
        }

        if (monto > saldoDisponible) {
          setState(
            () =>
                accountFromError =
                    'Saldo insuficiente. Disponible: \$${saldoDisponible.toStringAsFixed(2)}',
          );
          isValid = false;
        }
      }
      if (selectedAccountTo == null) {
        setState(
          () => accountToError = 'Por favor selecciona la cuenta destino',
        );
        isValid = false;
      } else if (selectedAccountFrom != null &&
          selectedAccountTo == selectedAccountFrom) {
        setState(
          () =>
              accountToError =
                  'La cuenta origen y destino no pueden ser iguales',
        );
        isValid = false;
      }
    }

    return isValid;
  }

  void _registerTransaction() async {
    if (_validateForm()) {
      setState(() => isRegistering = true);

      // Mostrar feedback inmediato
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Registrando transacción...',
                style: TextStyle(fontSize: 14.sp),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );

      try {
        final amount = double.parse(_amountController.text.replaceAll(',', ''));
        final description = _descriptionController.text;
        final date = DateFormat('yyyy-MM-dd').format(selectedDate);

        Map<String, dynamic> transactionData = {
          'idTransaccion': widget.transaction?.idTransaccion,
          'monto': amount,
          'descripcion': description,
          'fecha': date,
          'tipoTransaccion': widget.transactionType,
        };

        if (widget.transactionType == 'Traspasos') {
          transactionData['cuentaOrigen'] = selectedAccountFrom!.nombre;
          transactionData['cuentaDestino'] = selectedAccountTo!.nombre;
        } else if (widget.transactionType == 'Reembolsos') {
          transactionData['cuenta'] = selectedAccount!.nombre;
        } else {
          transactionData['categoria'] = selectedCategory!.categoria;
          transactionData['cuenta'] = selectedAccount!.nombre;
        }

        final transaccion = models.Transaction.fromJson(transactionData);
        await ApiService().registerTransaction(
          transaccion,
          cuenta:
              widget.transactionType == 'Traspasos' ? null : selectedAccount,
          cuentaOrigen:
              widget.transactionType == 'Traspasos'
                  ? selectedAccountFrom
                  : null,
          cuentaDestino:
              widget.transactionType == 'Traspasos' ? selectedAccountTo : null,
        );
        String mensaje = 'Transacción registrada exitosamente';

        if (!mounted) return;

        // Cerrar el snackbar de loading
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Mostrar mensaje de éxito rápido
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(mensaje, style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(milliseconds: 1500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );

        _resetForm();

        if (widget.transaction != null) {
          if (mounted) Navigator.of(context).pop();
        }
      } catch (e) {
        if (!mounted) return;

        // Cerrar el snackbar de loading
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        _showErrorSnackBar('Error al registrar la transacción: $e');
      } finally {
        if (mounted) setState(() => isRegistering = false);
      }
    }
  }

  void _resetForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      selectedDate = DateTime.now();
      selectedCategory = null;
      selectedAccount = null;
      selectedAccountFrom = null;
      selectedAccountTo = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(child: Text(message, style: TextStyle(fontSize: 13.sp))),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildHeader(ThemeManager themeManager) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color, widget.color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.all(6.r),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    widget.transaction != null ? 'Editar' : 'Nueva',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTransactionIcon(),
                size: 36.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              widget.transactionType,
              style: GoogleFonts.lato(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _getTransactionSubtitle(),
              style: GoogleFonts.openSans(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon() {
    switch (widget.transactionType) {
      case 'Ingresos':
        return Icons.trending_up_rounded;
      case 'Gastos':
        return Icons.trending_down_rounded;
      case 'Traspasos':
        return Icons.swap_horiz_rounded;
      case 'Reembolsos':
        return Icons.restore_rounded;
      default:
        return Icons.monetization_on_rounded;
    }
  }

  String _getTransactionSubtitle() {
    switch (widget.transactionType) {
      case 'Ingresos':
        return 'Registra tus entradas de dinero';
      case 'Gastos':
        return 'Controla tus salidas de dinero';
      case 'Traspasos':
        return 'Mueve dinero entre cuentas';
      case 'Reembolsos':
        return 'Registra devoluciones de dinero';
      default:
        return 'Registra tu transacción';
    }
  }

  Widget _buildAmountField(ThemeManager themeManager) {
    return Container(
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          MoneyInputFormatter(
            leadingSymbol: '',
            thousandSeparator: ThousandSeparator.Comma,
            mantissaLength: 2,
          ),
        ],
        style: GoogleFonts.lato(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color:
              themeManager.isDarkMode ? Colors.white : const Color(0xFF2D3436),
        ),
        decoration: InputDecoration(
          labelText: 'Monto',
          labelStyle: GoogleFonts.openSans(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(10.r),
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.7)],
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
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(ThemeManager themeManager) {
    return Container(
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.openSans(
          fontSize: 13.sp,
          color:
              themeManager.isDarkMode ? Colors.white : const Color(0xFF2D3436),
        ),
        decoration: InputDecoration(
          labelText: 'Descripción',
          labelStyle: GoogleFonts.openSans(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
          hintText: 'Ej: Compra de supermercado',
          hintStyle: GoogleFonts.openSans(
            color: Colors.grey.shade400,
            fontSize: 12.sp,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(10.r),
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor:
              themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeManager themeManager) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha',
                  style: GoogleFonts.openSans(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(selectedDate),
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        themeManager.isDarkMode
                            ? Colors.white
                            : const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.edit_calendar_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
              onPressed: () => _selectDate(context),
              padding: EdgeInsets.all(6.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(
    ThemeManager themeManager,
    List<Categoria> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Categoría',
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color:
                  themeManager.isDarkMode
                      ? Colors.white
                      : const Color(0xFF2D3436),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color:
                themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: DropdownButtonFormField<Categoria>(
            dropdownColor:
                themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
            value:
                categories.contains(selectedCategory) ? selectedCategory : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
            hint: Text(
              'Selecciona una categoría',
              style: GoogleFonts.openSans(
                color: Colors.grey.shade500,
                fontSize: 12.sp,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: widget.color,
              size: 20.sp,
            ),
            isExpanded: true,
            onChanged:
                (newCategory) => setState(() => selectedCategory = newCategory),
            items:
                categories.map((category) {
                  return DropdownMenuItem<Categoria>(
                    value: category,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color,
                                widget.color.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withOpacity(0.3),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            categoryIconsMap[category.imagen] ??
                                Icons.help_outline,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: Text(
                            category.categoria,
                            style: GoogleFonts.openSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF2D3436),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector(
    ThemeManager themeManager,
    List<Account> accounts,
    String label,
    Account? selectedValue,
    Function(Account?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color:
                  themeManager.isDarkMode
                      ? Colors.white
                      : const Color(0xFF2D3436),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color:
                themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: DropdownButtonFormField<Account>(
            dropdownColor:
                themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
            value: accounts.contains(selectedValue) ? selectedValue : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  themeManager.isDarkMode ? Colors.grey.shade800 : Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            hint: Text(
              'Selecciona una cuenta',
              style: GoogleFonts.openSans(
                color: Colors.grey.shade500,
                fontSize: 12.sp,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: widget.color,
              size: 20.sp,
            ),
            isExpanded: true,
            onChanged: onChanged,
            items:
                accounts.map((account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: Image.asset(
                            'assets/images/${account.imagen}.png',
                            width: 24.w,
                            height: 24.h,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 24.w,
                                height: 24.h,
                                decoration: BoxDecoration(
                                  color: widget.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: widget.color,
                                  size: 16.sp,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: Text(
                            account.nombre,
                            style: GoogleFonts.openSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF2D3436),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({bool enabled = true}) {
    return BounceTapButton(
      onTap: (isRegistering || !enabled) ? null : _registerTransaction,
      child: Container(
        width: double.infinity,
        height: 46.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                enabled
                    ? [widget.color, widget.color.withOpacity(0.8)]
                    : [Colors.grey.shade400, Colors.grey.shade400],
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: (enabled ? widget.color : Colors.grey.shade400)
                  .withOpacity(0.4),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isRegistering || !enabled) ? null : _registerTransaction,
            borderRadius: BorderRadius.circular(12.r),
            child: Center(
              child:
                  isRegistering
                      ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5.w,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            widget.transaction != null
                                ? 'Actualizar'
                                : 'Registrar',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context);

    // Validar que hay suficientes cuentas
    final int cuentasDisponibles = dataProvider.cuentas.length;
    final bool puedeCrearTransaccion =
        widget.transactionType == 'Traspasos'
            ? cuentasDisponibles >= 2
            : cuentasDisponibles >= 1;

    final filteredCategories =
        dataProvider.categorias.where((category) {
          return category.tipoTransaccion
              .split(',')
              .map((e) => e.trim())
              .contains(widget.transactionType);
        }).toList();

    if (selectedCategory != null &&
        !filteredCategories.contains(selectedCategory)) {
      selectedCategory = null;
    }

    if (selectedAccount != null &&
        !dataProvider.cuentas.contains(selectedAccount)) {
      selectedAccount = null;
    }

    if (selectedAccountFrom != null &&
        !dataProvider.cuentas.contains(selectedAccountFrom)) {
      selectedAccountFrom = null;
    }

    if (selectedAccountTo != null &&
        !dataProvider.cuentas.contains(selectedAccountTo)) {
      selectedAccountTo = null;
    }

    return Scaffold(
      backgroundColor:
          themeManager.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3.w,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              )
              : Column(
                children: [
                  _buildHeader(themeManager),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(14.r),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Advertencia si no hay suficientes cuentas
                                if (!puedeCrearTransaccion) ...[
                                  Container(
                                    padding: EdgeInsets.all(16.r),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      border: Border.all(
                                        color: Colors.orange.shade300,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange.shade700,
                                          size: 28.sp,
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.transactionType ==
                                                        'Traspasos'
                                                    ? 'Se necesitan al menos 2 cuentas'
                                                    : 'Se necesita al menos 1 cuenta',
                                                style: GoogleFonts.lato(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange.shade900,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                'Crea cuentas desde el menú de Cuentas para poder registrar transacciones.',
                                                style: GoogleFonts.openSans(
                                                  fontSize: 12.sp,
                                                  color: Colors.orange.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                ],
                                _buildAmountField(themeManager),
                                if (amountError != null) ...[
                                  SizedBox(height: 6.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red.shade400,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: Text(
                                            amountError!,
                                            style: GoogleFonts.openSans(
                                              fontSize: 11.sp,
                                              color: Colors.red.shade400,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 12.h),
                                _buildDescriptionField(themeManager),
                                if (descriptionError != null) ...[
                                  SizedBox(height: 6.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red.shade400,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: Text(
                                            descriptionError!,
                                            style: GoogleFonts.openSans(
                                              fontSize: 11.sp,
                                              color: Colors.red.shade400,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 12.h),
                                _buildDateSelector(themeManager),
                                SizedBox(height: 16.h),

                                if (widget.transactionType != 'Traspasos' &&
                                    widget.transactionType != 'Reembolsos') ...[
                                  _buildCategorySelector(
                                    themeManager,
                                    filteredCategories,
                                  ),
                                  if (categoryError != null) ...[
                                    SizedBox(height: 6.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red.shade400,
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              categoryError!,
                                              style: GoogleFonts.openSans(
                                                fontSize: 11.sp,
                                                color: Colors.red.shade400,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 12.h),
                                ],

                                if (widget.transactionType != 'Traspasos') ...[
                                  _buildAccountSelector(
                                    themeManager,
                                    dataProvider.cuentas,
                                    'Cuenta',
                                    selectedAccount,
                                    (account) => setState(
                                      () => selectedAccount = account,
                                    ),
                                  ),
                                  if (accountError != null) ...[
                                    SizedBox(height: 6.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red.shade400,
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              accountError!,
                                              style: GoogleFonts.openSans(
                                                fontSize: 11.sp,
                                                color: Colors.red.shade400,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],

                                if (widget.transactionType == 'Traspasos') ...[
                                  _buildAccountSelector(
                                    themeManager,
                                    dataProvider.cuentas,
                                    'Cuenta Origen',
                                    selectedAccountFrom,
                                    (account) => setState(
                                      () => selectedAccountFrom = account,
                                    ),
                                  ),
                                  if (accountFromError != null) ...[
                                    SizedBox(height: 6.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red.shade400,
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              accountFromError!,
                                              style: GoogleFonts.openSans(
                                                fontSize: 11.sp,
                                                color: Colors.red.shade400,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 12.h),
                                  _buildAccountSelector(
                                    themeManager,
                                    dataProvider.cuentas,
                                    'Cuenta Destino',
                                    selectedAccountTo,
                                    (account) => setState(
                                      () => selectedAccountTo = account,
                                    ),
                                  ),
                                  if (accountToError != null) ...[
                                    SizedBox(height: 6.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red.shade400,
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              accountToError!,
                                              style: GoogleFonts.openSans(
                                                fontSize: 11.sp,
                                                color: Colors.red.shade400,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],

                                SizedBox(height: 20.h),
                                _buildSubmitButton(
                                  enabled: puedeCrearTransaccion,
                                ),
                                SizedBox(height: 12.h),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
