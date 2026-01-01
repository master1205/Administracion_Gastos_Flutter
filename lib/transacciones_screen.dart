import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/dynamic_form_screen.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TransaccionesScreen extends StatefulWidget {
  const TransaccionesScreen({Key? key}) : super(key: key);

  @override
  TransaccionesScreenState createState() => TransaccionesScreenState();
}

class TransaccionesScreenState extends State<TransaccionesScreen>
    with WidgetsBindingObserver {
  final ApiService apiService = ApiService();
  Future<List<Transaction>>? _futureTransacciones;
  bool isLoading = true;
  bool isDeleting = false;

  // Variables para el tutorial
  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];
  final GlobalKey _dateHeaderKey = GlobalKey();
  final GlobalKey _firstTransactionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializar date formatting para es_ES
    initializeDateFormatting('es_ES', null);
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => isLoading = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => isLoading = false);
      });
    }
  }

  Future<void> showTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    // Usamos una clave única para GraficasScreen, por ejemplo "tutorial_graficas_shown"
    if (!(prefs.getBool('tutorial_transacciones_shown') ?? false)) {
      createTutorial();
      tutorialCoachMark.show(context: context);
    }
  }

  void createTutorial() {
    _initTargets();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.red,
      textSkip: "Omitir",
      paddingFocus: 10,
      opacityShadow: 0.5,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () async {
        await (await SharedPreferences.getInstance()).setBool(
          'tutorial_transacciones_shown',
          true,
        );
      },
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('tutorial_transacciones_shown', true);
        });
        return true;
      },
    );
  }

  void _initTargets() {
    targets.clear();

    // Target para la primera transacción (Editar o Eliminar)
    targets.add(
      TargetFocus(
        identify: "FirstTransaction",
        keyTarget: _firstTransactionKey,
        color: Colors.deepPurpleAccent,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurpleAccent, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "¡Atención!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Desliza la transacción para editarla o eliminarla.",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target para el encabezado de fecha
    targets.add(
      TargetFocus(
        identify: "DateHeader",
        keyTarget: _dateHeaderKey,
        color: Colors.indigo,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Transacciones del día",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Toca la fecha para ver el monto total de transacciones.",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    _futureTransacciones = apiService.fetchTransactions();
    _futureTransacciones!.then((_) {
      showTutorial();
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _deleteTransaction(String id) async {
    setState(() {
      isLoading = true;
    });
    try {
      await apiService.eliminarFilaPorIdTransaccion(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transacción eliminada exitosamente')),
      );
      refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la transacción: $e')),
      );
    } finally {
      setState(() {
        isDeleting = false;
      });
    }
  }

  void _editTransaction(Transaction transaccion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TrasaccionScreen(
              transaction: transaccion,
              transactionType: transaccion.tipoTransaccion,
              color: Colors.blue,
            ),
      ),
    ).then((_) => refreshData());
  }

  // Helper para obtener icono según tipo.
  IconData _getIconForType(String type) {
    switch (type) {
      case 'Reembolsos':
        return Icons.undo;
      case 'Pagos':
        return Icons.payment;
      case 'Traspasos':
        return Icons.compare_arrows;
      case 'Ingresos':
        return Icons.attach_money;
      case 'Gastos':
        return Icons.money_off;
      case 'Efectivo':
        return Icons.account_balance_wallet;
      default:
        return Icons.help;
    }
  }

  // Helper similar a un Chip, con diseño formal y gradiente.
  Widget buildBadge({
    required String text,
    required Color backgroundColor,
    required TextStyle textStyle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.5)),
      ),
      child: Text(text, style: textStyle),
    );
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  void _showDailyTransactions(String fecha, List<Transaction> transactions) {
    // Tipos relevantes
    final relevantTypes = [
      'Gastos',
      'Ingresos',
      'Pagos',
      'Traspasos',
      'Reembolsos',
    ];

    // Calcular el total de cada tipo
    Map<String, double> totals = {};
    for (var t in transactions) {
      if (relevantTypes.contains(t.tipoTransaccion)) {
        totals[t.tipoTransaccion] = (totals[t.tipoTransaccion] ?? 0) + t.monto;
      }
    }

    final formatter = NumberFormat('#,##0.00', 'en-US');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Total"),
          content: SingleChildScrollView(
            child: Column(
              children:
                  totals.entries.map((entry) {
                    // Obtener icono y color según el tipo
                    IconData iconData = _getIconForType(entry.key);
                    Color color;
                    switch (entry.key) {
                      case 'Reembolsos':
                        color = Colors.purple;
                        break;
                      case 'Pagos':
                        color = Colors.orange;
                        break;
                      case 'Traspasos':
                        color = Colors.blue;
                        break;
                      case 'Ingresos':
                        color = Colors.green;
                        break;
                      case 'Gastos':
                        color = Colors.red;
                        break;
                      default:
                        color = Colors.grey;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(iconData, color: color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            "\$${formatter.format(entry.value.abs())}",
                            style: TextStyle(fontSize: 14, color: color),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    final bgColor = themeManager.themeData.scaffoldBackgroundColor;

    return Container(
      decoration:
          !themeManager.isDarkMode
              ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
              : null,
      child: Scaffold(
        backgroundColor: themeManager.isDarkMode ? bgColor : Colors.transparent,
        body: Container(
          color: themeManager.isDarkMode ? bgColor : Colors.transparent,
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: refreshData,
                child: FutureBuilder<List<Transaction>>(
                  future: _futureTransacciones,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      if (snapshot.error is SocketException) {
                        return const Center(
                          child: Text('No cuentas con conexión a internet'),
                        );
                      } else {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No hay transacciones disponibles'),
                      );
                    } else {
                      // Ordenar todas las transacciones de forma descendente basado en la fecha
                      List<Transaction> sortedTransactions = List.from(
                        snapshot.data!,
                      );
                      sortedTransactions.sort(
                        (a, b) => DateTime.parse(
                          b.fecha,
                        ).compareTo(DateTime.parse(a.fecha)),
                      );

                      return ListView.separated(
                        shrinkWrap: true,
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Cambiado de NeverScrollableScrollPhysics
                        itemCount: sortedTransactions.length,
                        separatorBuilder:
                            (context, index) => const SizedBox(height: 1),
                        itemBuilder: (context, index) {
                          final transaction = sortedTransactions[index];
                          IconData tipoIcon;
                          Color tipoColor;
                          switch (transaction.tipoTransaccion) {
                            case 'Reembolsos':
                              tipoIcon = Icons.undo;
                              tipoColor = Colors.purple;
                              break;
                            case 'Pagos':
                              tipoIcon = Icons.payment;
                              tipoColor = Colors.orange;
                              break;
                            case 'Traspasos':
                              tipoIcon = Icons.compare_arrows;
                              tipoColor = Colors.blue;
                              break;
                            case 'Ingresos':
                              tipoIcon = Icons.attach_money;
                              tipoColor = Colors.green;
                              break;
                            case 'Gastos':
                              tipoIcon = Icons.money_off;
                              tipoColor = Colors.red;
                              break;
                            default:
                              tipoIcon = Icons.receipt;
                              tipoColor = Colors.grey;
                          }
                          final bool showHeader =
                              index == 0 ||
                              (sortedTransactions[index].fecha !=
                                  sortedTransactions[index - 1].fecha);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showHeader)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        // Filtra las transacciones diarias según la fecha
                                        final dailyTransactions =
                                            sortedTransactions
                                                .where(
                                                  (t) =>
                                                      t.fecha ==
                                                      transaction.fecha,
                                                )
                                                .toList();
                                        _showDailyTransactions(
                                          transaction.fecha,
                                          dailyTransactions,
                                        );
                                      },
                                      child: Builder(
                                        builder: (context) {
                                          String formattedDate = DateFormat(
                                            'EEEE, d',
                                            'es_ES',
                                          ).format(
                                            DateTime.parse(transaction.fecha),
                                          );
                                          formattedDate =
                                              formattedDate[0].toUpperCase() +
                                              formattedDate.substring(1);
                                          return Text(
                                            key:
                                                index == 0
                                                    ? _dateHeaderKey
                                                    : null,
                                            formattedDate,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color:
                                                      themeManager.isDarkMode
                                                          ? Colors.white70
                                                          : Colors
                                                              .grey
                                                              .shade700,
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              Slidable(
                                key: Key(transaction.idTransaccion),
                                startActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.25,
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) async {
                                        bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Confirmar edición",
                                              ),
                                              content: const Text(
                                                "¿Deseas editar esta transacción?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(false),
                                                  child: const Text("Cancelar"),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(true),
                                                  child: const Text("Editar"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (confirm == true) {
                                          _editTransaction(transaction);
                                        }
                                      },
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit,
                                      label: 'Editar',
                                    ),
                                  ],
                                ),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.25,
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) async {
                                        bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Confirmar eliminación",
                                              ),
                                              content: const Text(
                                                "¿Deseas eliminar esta transacción?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(false),
                                                  child: const Text("Cancelar"),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(true),
                                                  child: const Text(
                                                    "Eliminar",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (confirm == true) {
                                          _deleteTransaction(
                                            transaction.idTransaccion,
                                          );
                                        }
                                      },
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Eliminar',
                                    ),
                                  ],
                                ),
                                // Aquí se elimina la Card para dejar solamente el AnimatedContainer
                                child: AnimatedContainer(
                                  key: index == 0 ? _firstTransactionKey : null,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient:
                                        themeManager.isDarkMode
                                            ? null
                                            : LinearGradient(
                                              colors: [
                                                tipoColor.withOpacity(0.3),
                                                tipoColor.withOpacity(0.1),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                    color:
                                        themeManager.isDarkMode
                                            ? tipoColor.withOpacity(0.15)
                                            : null,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            themeManager.isDarkMode
                                                ? Colors.white10
                                                : Colors.grey.shade200,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        tipoIcon,
                                        color:
                                            themeManager.isDarkMode
                                                ? Colors.white70
                                                : tipoColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      transaction.descripcion,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: () {
                                          List<Widget> badges = [];
                                          final badgeTextStyle = theme
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: tipoColor,
                                              );
                                          if (transaction.tipoTransaccion ==
                                              'Traspasos') {
                                            badges.add(
                                              buildBadge(
                                                text: transaction.cuentaOrigen,
                                                backgroundColor: tipoColor,
                                                textStyle: badgeTextStyle!,
                                              ),
                                            );
                                            badges.add(
                                              const SizedBox(width: 4),
                                            );
                                            badges.add(
                                              buildBadge(
                                                text: transaction.cuentaDestino,
                                                backgroundColor: tipoColor,
                                                textStyle: badgeTextStyle,
                                              ),
                                            );
                                          } else if (transaction
                                                  .tipoTransaccion ==
                                              'Reembolsos') {
                                            badges.add(
                                              buildBadge(
                                                text: transaction.cuenta,
                                                backgroundColor: tipoColor,
                                                textStyle: badgeTextStyle!,
                                              ),
                                            );
                                          } else if (transaction
                                                      .tipoTransaccion ==
                                                  'Gastos' ||
                                              transaction.tipoTransaccion ==
                                                  'Pagos' ||
                                              transaction.tipoTransaccion ==
                                                  'Ingresos') {
                                            if (transaction.categoria
                                                    .toLowerCase() ==
                                                'semanal') {
                                              badges.add(
                                                buildBadge(
                                                  text: transaction.categoria,
                                                  backgroundColor: tipoColor,
                                                  textStyle: badgeTextStyle!,
                                                ),
                                              );
                                            } else {
                                              badges.add(
                                                buildBadge(
                                                  text: transaction.categoria,
                                                  backgroundColor: tipoColor,
                                                  textStyle: badgeTextStyle!,
                                                ),
                                              );
                                              badges.add(
                                                const SizedBox(width: 4),
                                              );
                                              badges.add(
                                                buildBadge(
                                                  text: transaction.cuenta,
                                                  backgroundColor: tipoColor,
                                                  textStyle: badgeTextStyle,
                                                ),
                                              );
                                            }
                                          } else {
                                            badges.add(
                                              Text(
                                                "Tipo: ${transaction.tipoTransaccion}",
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: tipoColor,
                                                    ),
                                              ),
                                            );
                                          }
                                          return badges;
                                        }(),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          NumberFormat.currency(
                                            symbol: '\$ ',
                                          ).format(transaction.monto.abs()),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: tipoColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              if (isLoading)
                Container(
                  color: bgColor.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
