import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/componentes/heads_up_notification.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/models/Transaccion.dart' as models;
import 'package:notificaciones/models/Transaccion.dart';

import 'package:notificaciones/theme_provider.dart';
import 'package:notificaciones/widgets/select_amount.dart';
import 'package:notificaciones/widgets/discard_changes_dialog.dart';
import 'package:provider/provider.dart';

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

  // Categorías cargadas desde DataProvider
  List<Categoria> _categorias = [];

  String? amountError;
  String? descriptionError;
  String? categoryError;
  String? accountError;
  String? accountFromError;
  String? accountToError;

  // Caché para categorías filtradas
  List<Categoria>? _filteredCategoriesCache;
  String? _lastFilteredType;

  // Variables para detectar cambios
  late String _initialAmount;
  late String _initialDescription;
  late DateTime _initialDate;
  late Categoria? _initialCategory;
  late Account? _initialAccount;
  late Account? _initialAccountFrom;
  late Account? _initialAccountTo;

  // Convertir el código del icono guardado en IconData
  IconData _getIconFromString(String iconString) {
    // Si es un número (codePoint), crear el icono directamente
    final codePoint = int.tryParse(iconString);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    // Fallback para iconos antiguos guardados como strings
    // Solo algunos iconos comunes para compatibilidad
    final Map<String, IconData> fallbackMap = {
      'shopping_cart': Icons.shopping_cart,
      'restaurant': Icons.restaurant,
      'local_gas_station': Icons.local_gas_station,
      'home': Icons.home,
      'work': Icons.work,
      'attach_money': Icons.attach_money,
      'category': Icons.category,
    };

    return fallbackMap[iconString] ?? Icons.category;
  }

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
            // ❌ REMOVIDO: La categoría ahora se selecciona en _loadInitialData()
            // después de cargar desde Firebase

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
    // Los Streams de Firebase se actualizan automáticamente
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

  List<Categoria> _getFilteredCategories() {
    // Mapear el tipo de transacción al formato de Firebase
    String tipoFiltro = widget.transactionType;
    if (tipoFiltro == 'Gastos') tipoFiltro = 'Gasto';
    if (tipoFiltro == 'Pagos') tipoFiltro = 'Pago';
    if (tipoFiltro == 'Ingresos') tipoFiltro = 'Ingreso';

    // Usar caché si el tipo no ha cambiado
    if (_lastFilteredType == tipoFiltro && _filteredCategoriesCache != null) {
      return _filteredCategoriesCache!;
    }

    _lastFilteredType = tipoFiltro;
    _filteredCategoriesCache =
        _categorias.where((category) {
          return category.tipoTransaccion
              .split(',')
              .map((e) => e.trim())
              .contains(tipoFiltro);
        }).toList();

    return _filteredCategoriesCache!;
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

  void _loadInitialData() async {
    // Cargar categorías desde DataProvider
    final dp = Provider.of<DataProvider>(context, listen: false);
    final categoriasData = dp.categorias;
    setState(() {
      _categorias =
          categoriasData.map((cat) => Categoria.fromJson(cat)).toList();

      // Invalidar caché de categorías filtradas
      _filteredCategoriesCache = null;
      _lastFilteredType = null;

      // ✅ Seleccionar categoría inicial DESPUÉS de cargar las categorías
      if (widget.transaction != null &&
          selectedCategory == null &&
          _categorias.isNotEmpty) {
        try {
          selectedCategory = _categorias.firstWhere(
            (c) => c.categoria == widget.transaction!.categoria,
          );
        } catch (e) {
          selectedCategory = _categorias.first;
        }
      }

      // Guardar estado inicial después de cargar datos
      _saveInitialState();
    });

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.monto.toString();
      _descriptionController.text = widget.transaction!.descripcion;
      selectedDate = DateTime.parse(widget.transaction!.fecha);
    } else {
      // Guardar estado inicial para nuevo registro
      _saveInitialState();
    }
  }

  void _saveInitialState() {
    _initialAmount = _amountController.text;
    _initialDescription = _descriptionController.text;
    _initialDate = selectedDate;
    _initialCategory = selectedCategory;
    _initialAccount = selectedAccount;
    _initialAccountFrom = selectedAccountFrom;
    _initialAccountTo = selectedAccountTo;
  }

  bool _hasChanges() {
    return _amountController.text != _initialAmount ||
        _descriptionController.text != _initialDescription ||
        selectedDate != _initialDate ||
        selectedCategory != _initialCategory ||
        selectedAccount != _initialAccount ||
        selectedAccountFrom != _initialAccountFrom ||
        selectedAccountTo != _initialAccountTo;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges()) {
      return await DiscardChangesDialog.show(context);
    }
    return true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            dialogBackgroundColor: theme.colorScheme.surface,
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
          double saldoDisponible = selectedAccount!.saldoDisponible;
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
        double saldoDisponible = selectedAccountFrom!.saldoDisponible;
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
        String mensaje =
            widget.transaction != null
                ? 'Transacción editada correctamente'
                : 'Transacción registrada exitosamente';

        if (!mounted) return;

        showSuccessNotification(context, message: mensaje);

        _resetForm();

        if (widget.transaction != null) {
          if (mounted) Navigator.of(context).pop();
        }
      } catch (e) {
        if (!mounted) return;

        showErrorNotification(
          context,
          message: 'Error al registrar la transacción',
          subtitle: e.toString(),
        );
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
    // Actualizar el estado inicial para evitar que detecte cambios después de resetear
    _saveInitialState();
  }

  Widget _buildHeader(ThemeManager themeManager) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.primary,
                      size: 20.sp,
                    ),
                    onPressed: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && mounted) {
                        Navigator.of(context).pop();
                      }
                    },
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
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.transaction != null ? 'Editar' : 'Nueva',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
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
                color: theme.colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getTransactionIcon(),
                size: 36.sp,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              widget.transactionType,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _getTransactionSubtitle(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary.withOpacity(0.7),
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

  Widget _buildSectionTitle(String title, ThemeManager themeManager) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAmountField(ThemeManager themeManager) {
    final theme = Theme.of(context);
    final currentAmount =
        _amountController.text.isNotEmpty
            ? double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0
            : 0.0;

    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    final displayText =
        currentAmount > 0 ? formatter.format(currentAmount) : '';

    return GestureDetector(
      onTap: () async {
        final result = await showSelectAmountBottomSheet(
          context,
          title: 'Ingresa el monto',
          initialAmount: currentAmount,
          allowZero: false,
          currencySymbol: '\$',
        );

        if (result != null) {
          setState(() {
            _amountController.text = result.toStringAsFixed(2);
            amountError = null;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.attach_money_rounded,
                  color: theme.colorScheme.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  displayText.isNotEmpty ? displayText : '\$0.00',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        displayText.isNotEmpty
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.secondary.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(ThemeManager themeManager) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _descriptionController,
        textCapitalization: TextCapitalization.words,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Ej: Compra de supermercado',
          hintStyle: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.secondary.withOpacity(0.4),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(10.r),
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.description_rounded,
              color: theme.colorScheme.primary,
              size: 20.sp,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeManager themeManager) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: theme.colorScheme.primary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_calendar_rounded,
              color: theme.colorScheme.primary,
              size: 20.sp,
            ),
            onPressed: () => _selectDate(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(
    ThemeManager themeManager,
    List<Categoria> categories,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Categoría',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<Categoria>(
            dropdownColor: theme.colorScheme.surface,
            value:
                categories.contains(selectedCategory) ? selectedCategory : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
            hint: Text(
              'Selecciona una categoría',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary.withOpacity(0.5),
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurface,
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
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            _getIconFromString(category.imagen),
                            size: 14.sp,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: Text(
                            category.categoria,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<Account>(
            dropdownColor: theme.colorScheme.surface,
            value: accounts.contains(selectedValue) ? selectedValue : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            hint: Text(
              'Selecciona una cuenta',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary.withOpacity(0.5),
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurface,
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
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: Image.asset(
                              'assets/images/${account.imagen}.png',
                              width: 20.w,
                              height: 20.h,
                              color: theme.colorScheme.primary,
                              colorBlendMode: BlendMode.srcIn,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.account_balance_wallet,
                                  color: theme.colorScheme.primary,
                                  size: 20.sp,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Flexible(
                          child: Text(
                            account.nombre,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: FilledButton.tonal(
        onPressed: (isRegistering || !enabled) ? null : _registerTransaction,
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          disabledBackgroundColor: cs.secondaryContainer.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child:
            isRegistering
                ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    color: cs.onSecondaryContainer,
                    strokeWidth: 2.5.w,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      widget.transaction != null ? 'Actualizar' : 'Registrar',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    // Validar que hay suficientes cuentas
    final int cuentasDisponibles = dataProvider.cuentas.length;
    final bool puedeCrearTransaccion =
        widget.transactionType == 'Traspasos'
            ? cuentasDisponibles >= 2
            : cuentasDisponibles >= 1;

    // Usar método optimizado con caché
    final filteredCategories = _getFilteredCategories();

    // Validar selecciones (mover a un método separado si es necesario en el futuro)
    // Nota: Estas validaciones son necesarias pero deberían evitarse modificar estado aquí
    // En una optimización futura, considerar usar un ValueNotifier o similar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        bool needsUpdate = false;

        if (selectedCategory != null &&
            !filteredCategories.contains(selectedCategory)) {
          selectedCategory = null;
          needsUpdate = true;
        }

        if (selectedAccount != null &&
            !dataProvider.cuentas.contains(selectedAccount)) {
          selectedAccount = null;
          needsUpdate = true;
        }

        if (selectedAccountFrom != null &&
            !dataProvider.cuentas.contains(selectedAccountFrom)) {
          selectedAccountFrom = null;
          needsUpdate = true;
        }

        if (selectedAccountTo != null &&
            !dataProvider.cuentas.contains(selectedAccountTo)) {
          selectedAccountTo = null;
          needsUpdate = true;
        }

        if (needsUpdate) {
          setState(() {});
        }
      }
    });

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3.w,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
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
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
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
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors
                                                                .orange
                                                                .shade900,
                                                      ),
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  'Crea cuentas desde el menú de Cuentas para poder registrar transacciones.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            Colors
                                                                .orange
                                                                .shade800,
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
                                  _buildSectionTitle('Monto', themeManager),
                                  SizedBox(height: 8.h),
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
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
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
                                  _buildSectionTitle(
                                    'Descripción',
                                    themeManager,
                                  ),
                                  SizedBox(height: 8.h),
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
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
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
                                  _buildSectionTitle('Fecha', themeManager),
                                  SizedBox(height: 8.h),
                                  _buildDateSelector(themeManager),
                                  SizedBox(height: 16.h),

                                  if (widget.transactionType != 'Traspasos' &&
                                      widget.transactionType !=
                                          'Reembolsos') ...[
                                    // Advertencia si no hay categorías disponibles
                                    if (filteredCategories.isEmpty) ...[
                                      Container(
                                        padding: EdgeInsets.all(16.r),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          border: Border.all(
                                            color: Colors.orange.shade300,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
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
                                                    'No hay categorías disponibles',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors
                                                                  .orange
                                                                  .shade900,
                                                        ),
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    'Crea categorías desde el menú de Categorías para poder registrar ${widget.transactionType.toLowerCase()}.',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Colors
                                                                  .orange
                                                                  .shade800,
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
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
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

                                  if (widget.transactionType !=
                                      'Traspasos') ...[
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
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
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

                                  if (widget.transactionType ==
                                      'Traspasos') ...[
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
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
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
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}
