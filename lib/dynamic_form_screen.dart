import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:flutter_multi_formatter/formatters/money_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Categoria.dart';
import 'package:notificaciones/models/Transaccion.dart';
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
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isRegistering = false;
  Categoria? selectedCategory;
  Account? selectedAccount;
  Account? selectedAccountFrom;
  Account? selectedAccountTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.monto.toString();
      _descriptionController.text = widget.transaction!.descripcion;
      selectedDate = DateTime.parse(widget.transaction!.fecha);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        isLoading = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  void _registerTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isRegistering = true);
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

      try {
        String mensaje = await ApiService().registerTransaction(
          transactionData,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensaje)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar la transacción: $e')),
        );
      } finally {
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          isRegistering = false;
          selectedDate = DateTime.now();
          selectedCategory = null;
          selectedAccount = null;
          selectedAccountFrom = null;
          selectedAccountTo = null;
        });
        if (widget.transaction != null) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Map<String, IconData> categoryIconsMap = {
    'airplanemode_active_outlined': Icons.airplanemode_active_outlined,
    'checkroom_outlined': Icons.checkroom_outlined,
    'pets_outlined': Icons.pets_outlined,
    'account_balance_wallet_outlined': Icons.account_balance_wallet_outlined,
    'credit_card_outlined': Icons.credit_card_outlined,
    'home_outlined': Icons.home_outlined,
    'location_city_outlined': Icons.location_city_outlined,
    'electrical_services_outlined': Icons.electrical_services_outlined,
    'security_outlined': Icons.security_outlined,
    'receipt_long_outlined': Icons.receipt_long_outlined,
    'subscriptions_outlined': Icons.subscriptions_outlined,
    'attach_money_outlined': Icons.attach_money_outlined,
    'card_giftcard_outlined': Icons.card_giftcard_outlined,
    'trending_up_outlined': Icons.trending_up_outlined,
    'sell_outlined': Icons.sell_outlined,
    'monetization_on_outlined': Icons.monetization_on_outlined,
    'redeem_outlined': Icons.redeem_outlined,
    'savings_outlined': Icons.savings_outlined,
    'restaurant_outlined': Icons.restaurant_outlined,
    'directions_car_outlined': Icons.directions_car_outlined,
    'movie_outlined': Icons.movie_outlined,
    'school_outlined': Icons.school_outlined,
    'help_outline': Icons.help_outline,
    'local_hospital_outlined': Icons.local_hospital_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);

    if (widget.transaction != null && selectedCategory == null) {
      selectedCategory = dataProvider.categorias.firstWhere(
        (categoria) => categoria.categoria == widget.transaction!.categoria,
        orElse: () => dataProvider.categorias.first,
      );
    }
    if (widget.transaction != null && selectedAccount == null) {
      selectedAccount = dataProvider.cuentas.firstWhere(
        (account) => account.nombre == widget.transaction!.cuenta,
        orElse: () => dataProvider.cuentas.first,
      );
    }
    if (widget.transaction != null && selectedAccountFrom == null) {
      selectedAccountFrom = dataProvider.cuentas.firstWhere(
        (account) => account.nombre == widget.transaction!.cuentaOrigen,
        orElse: () => dataProvider.cuentas.first,
      );
    }
    if (widget.transaction != null && selectedAccountTo == null) {
      selectedAccountTo = dataProvider.cuentas.firstWhere(
        (account) => account.nombre == widget.transaction!.cuentaDestino,
        orElse: () => dataProvider.cuentas.first,
      );
    }

    final filteredCategories =
        dataProvider.categorias.where((category) {
          return category.tipoTransaccion
              .split(',')
              .map((e) => e.trim())
              .contains(widget.transactionType);
        }).toList();

    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration:
          !isDarkMode
              ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
              : null,
      child: Scaffold(
        backgroundColor:
            isDarkMode ? theme.scaffoldBackgroundColor : Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: theme.iconTheme,
          title: Text(
            'Registrar ${widget.transactionType}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.transactionType,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Monto',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: theme.iconTheme.color,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            MoneyInputFormatter(
                              leadingSymbol: '',
                              thousandSeparator: ThousandSeparator.Comma,
                              mantissaLength: 2,
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un monto';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.description,
                              color: theme.iconTheme.color,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa una descripción';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            ElevatedButton(
                              onPressed: () => _selectDate(context),
                              child: const Text('Seleccionar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (widget.transactionType != 'Traspasos' &&
                            widget.transactionType != 'Reembolsos') ...[
                          Text(
                            'Categoría',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Categoria>(
                            dropdownColor: theme.cardColor,
                            value: selectedCategory,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (newCategory) {
                              setState(() => selectedCategory = newCategory);
                            },
                            items:
                                filteredCategories.map((category) {
                                  return DropdownMenuItem<Categoria>(
                                    value: category,
                                    child: Row(
                                      children: [
                                        Icon(
                                          categoryIconsMap[category.imagen] ??
                                              Icons.hourglass_empty_outlined,
                                          size: 30,
                                          color: widget.color,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          category.categoria,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor selecciona una categoría';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (widget.transactionType != 'Traspasos') ...[
                          Text(
                            'Cuenta',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Account>(
                            dropdownColor: theme.cardColor,
                            value: selectedAccount,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (newAccount) {
                              setState(() => selectedAccount = newAccount);
                            },
                            items:
                                dataProvider.cuentas.map((account) {
                                  return DropdownMenuItem<Account>(
                                    value: account,
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/${account.imagen}.png',
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          account.nombre,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor selecciona una cuenta';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (widget.transactionType == 'Traspasos') ...[
                          Text(
                            'Cuenta Origen',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Account>(
                            dropdownColor: theme.cardColor,
                            value: selectedAccountFrom,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (newAccount) {
                              setState(() => selectedAccountFrom = newAccount);
                            },
                            items:
                                dataProvider.cuentas.map((account) {
                                  return DropdownMenuItem<Account>(
                                    value: account,
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/${account.imagen}.png',
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          account.nombre,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor selecciona la cuenta origen';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cuenta Destino',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Account>(
                            dropdownColor: theme.cardColor,
                            value: selectedAccountTo,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (newAccount) {
                              setState(() => selectedAccountTo = newAccount);
                            },
                            items:
                                dataProvider.cuentas.map((account) {
                                  return DropdownMenuItem<Account>(
                                    value: account,
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/${account.imagen}.png',
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          account.nombre,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor selecciona la cuenta destino';
                              }
                              if (selectedAccountFrom != null &&
                                  value == selectedAccountFrom) {
                                return 'La cuenta origen y la cuenta destino no pueden ser la misma';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _registerTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.color,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              isRegistering
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Registrar ${widget.transactionType}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
