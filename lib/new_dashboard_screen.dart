import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/data_provider.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:notificaciones/models/Transaccion.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class NewDashboardScreen extends StatefulWidget {
  final void Function(int)? onTabChange;
  const NewDashboardScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  NewDashboardScreenState createState() => NewDashboardScreenState();
}

class NewDashboardScreenState extends State<NewDashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // GlobalKeys para el tutorial
  final GlobalKey _balanceCardKey = GlobalKey();
  final GlobalKey _accountsCarouselKey = GlobalKey();
  final GlobalKey _verTodoKey = GlobalKey();
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  List<Account> accounts = [];
  Map<String, dynamic>? _balanceData;
  List<Transaction> transactions = [];

  late PageController _pageController;
  bool _isLoading = false;

  // Variables para el tutorial
  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController(viewportFraction: 0.8);

    setState(() => _isLoading = true);
    Future.wait([_fetchAccounts(), _fetchSaldos(), _fetchTransactions()]).then((
      _,
    ) {
      maybeShowDashboardTutorial();
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  void maybeShowDashboardTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    // Si ya se completó el tutorial de HomeScreen y aún no se mostró el del Dashboard:
    if ((prefs.getBool('tutorial_home_shown') ?? false) &&
        !(prefs.getBool('tutorial_dashboard_shown') ?? false)) {
      showTutorial(); // Llama a tu método para crear y mostrar el tutorial
      await prefs.setBool('tutorial_dashboard_shown', true);
    } else if (!(prefs.getBool('tutorial_home_shown') ?? false)) {
      // Espera y vuelve a verificar en 2 segundos
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) maybeShowDashboardTutorial();
      });
    }
  }

  void showTutorial() {
    createTutorial();
    tutorialCoachMark.show(context: context);
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
      onSkip: () {
        return true;
      },
    );
  }

  void _initTargets() {
    targets.clear();

    // Target para la Tarjeta de Balance
    targets.add(
      TargetFocus(
        identify: "BalanceCard",
        keyTarget: _balanceCardKey,
        color: Colors.deepPurpleAccent,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurpleAccent, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Balance Total",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Observa tu saldo acumulado, ingresos y gastos en un solo vistazo.",
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

    // Target para el Carrusel de Cuentas
    targets.add(
      TargetFocus(
        identify: "AccountsCarousel",
        keyTarget: _accountsCarouselKey,
        color: Colors.indigoAccent,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.indigoAccent, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cuentas",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Desliza para ver cada cuenta y su saldo, mantén el control de tu dinero.",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        controller.previous();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target para el botón "Ver Todo"
    targets.add(
      TargetFocus(
        identify: "VerTodoButton",
        keyTarget: _verTodoKey,
        color: Colors.teal,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Ver todas las transacciones",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Presiona aquí para consultar el historial completo de transacciones.",
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

  Future<void> _fetchAccounts() async {
    try {
      final fetchedAccounts =
          await Provider.of<DataProvider>(
            context,
            listen: false,
          ).apiService.fetchCuentas();
      setState(() {
        accounts = fetchedAccounts;
      });
    } catch (e) {
      debugPrint('Error al cargar cuentas: $e');
    }
  }

  Future<void> _fetchSaldos() async {
    try {
      final fetchedSaldos =
          await Provider.of<DataProvider>(
            context,
            listen: false,
          ).apiService.fetchSaldos();
      setState(() {
        _balanceData = fetchedSaldos;
      });
    } catch (e) {
      debugPrint('Error al cargar saldos: $e');
      setState(() {
        _balanceData = {'saldoCuentas': 0.0, 'ingresos': 0.0, 'gastos': 0.0};
      });
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final fetchedTransactions =
          await Provider.of<DataProvider>(
            context,
            listen: false,
          ).apiService.fetchTransactions();
      setState(() {
        transactions = fetchedTransactions;
      });
    } catch (e) {
      debugPrint('Error al cargar transacciones: $e');
      setState(() {
        // Asigna datos dummy en caso de error
        transactions = [
          Transaction(
            idTransaccion: 'dummy1',
            categoria: 'Dummy Categoria',
            descripcion: 'Groceries',
            monto: 45.30,
            fecha: '2023-10-02',
            tipoTransaccion: 'Expense',
          ),
          Transaction(
            idTransaccion: 'dummy2',
            categoria: 'Dummy Categoria',
            descripcion: 'Netflix',
            monto: 13.99,
            fecha: '2023-10-02',
            tipoTransaccion: 'Expense',
          ),
        ];
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([_fetchAccounts(), _fetchSaldos(), _fetchTransactions()]);
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildBalanceCard() {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    var saldoCuentasVar = _balanceData?['saldoCuentas'] ?? 0.0;
    final double saldoTotal = double.parse(saldoCuentasVar.toString());
    var ingresosVar = _balanceData?['ingresos'] ?? 0.0;
    final double ingresos = double.parse(ingresosVar.toString());
    var gastosVar = _balanceData?['gastos'] ?? 0.0;
    final double gastos = double.parse(gastosVar.toString());

    return Card(
      key: _balanceCardKey, // Asignamos key para el tutorial
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              themeManager.isDarkMode
                  ? theme.canvasColor.withOpacity(0.2)
                  : Colors.white,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Total',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: saldoTotal),
              duration: const Duration(seconds: 1),
              builder: (context, animatedValue, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormat.format(animatedValue),
                      style: GoogleFonts.lato(
                        textStyle: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        color:
                            themeManager.isDarkMode
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color:
                          themeManager.isDarkMode
                              ? Colors.white70
                              : theme.colorScheme.primary,
                      size: 32,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedColumn(
                  title: 'Ingresos',
                  amount: ingresos,
                  color:
                      themeManager.isDarkMode
                          ? Colors.lightGreenAccent
                          : Colors.green.shade700,
                  icon: Icons.arrow_upward,
                ),
                _buildAnimatedColumn(
                  title: 'Gastos',
                  amount: gastos,
                  color:
                      themeManager.isDarkMode ? Colors.redAccent : Colors.red,
                  icon: Icons.arrow_downward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedColumn({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: amount),
          duration: const Duration(seconds: 1),
          builder: (context, animatedValue, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  currencyFormat.format(animatedValue),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountsCarousel() {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    List<Account> sortedAccounts = List.from(accounts);
    sortedAccounts.sort((a, b) => (b.saldo ?? 0.0).compareTo(a.saldo ?? 0.0));

    return SizedBox(
      key: _accountsCarouselKey, // Key para el tutorial
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: sortedAccounts.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final currentItem = sortedAccounts[index];
          final name = currentItem.nombre;
          final balance = currentItem.saldo ?? 0.0;
          final cardNumber = currentItem.numeroTarjeta ?? '****-0000-****';
          final owner = currentItem.beneficiario ?? 'Desconocido';

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = (_pageController.page! - index).abs();
                value = (1 - value * 0.3).clamp(0.0, 1.0);
              }
              return Card(
                color: Colors.transparent,
                shadowColor:
                    themeManager.isDarkMode
                        ? Colors.black45
                        : Colors.transparent,
                elevation: 6,
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Transform.scale(
                  scale: Curves.easeOut.transform(value),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            themeManager.isDarkMode
                                ? [Colors.grey.shade800, Colors.grey.shade900]
                                : [Colors.blue.shade400, Colors.blue.shade200],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              themeManager.isDarkMode
                                  ? Colors.black45
                                  : Colors.blue.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: balance),
                            duration: const Duration(seconds: 1),
                            builder: (context, animatedValue, _) {
                              return Text(
                                currencyFormat.format(animatedValue),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      themeManager.isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          Text(
                            'Card #: $cardNumber',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cardholder: $owner',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList() {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    List<Transaction> sortedTransactions = List.from(transactions);
    sortedTransactions.sort(
      (a, b) => DateTime.parse(b.fecha).compareTo(DateTime.parse(a.fecha)),
    );
    final int displayCount =
        sortedTransactions.length < 5 ? sortedTransactions.length : 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado y botón "Ver todo"
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Transacciones Recientes',
                  style: GoogleFonts.lato(
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                key: _verTodoKey, // Key para el tutorial
                onPressed: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(1);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No callback configured for tab change'),
                      ),
                    );
                  }
                },
                child: Text(
                  'Ver todo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          color:
              themeManager.isDarkMode
                  ? Colors.white54
                  : theme.colorScheme.primary.withOpacity(0.3),
          thickness: 1,
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayCount,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
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
                      child: Builder(
                        builder: (context) {
                          String formattedDate = DateFormat(
                            'EEEE, d',
                            'es_ES',
                          ).format(DateTime.parse(transaction.fecha));
                          formattedDate =
                              formattedDate[0].toUpperCase() +
                              formattedDate.substring(1);
                          return Text(
                            formattedDate,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                AnimatedContainer(
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: () {
                          List<Widget> badges = [];
                          final badgeTextStyle = theme.textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tipoColor,
                              );
                          if (transaction.tipoTransaccion == 'Traspasos') {
                            badges.add(
                              buildBadge(
                                text: transaction.cuentaOrigen,
                                backgroundColor: tipoColor,
                                textStyle: badgeTextStyle!,
                              ),
                            );
                            badges.add(const SizedBox(width: 4));
                            badges.add(
                              buildBadge(
                                text: transaction.cuentaDestino,
                                backgroundColor: tipoColor,
                                textStyle: badgeTextStyle,
                              ),
                            );
                          } else if (transaction.tipoTransaccion ==
                              'Reembolsos') {
                            badges.add(
                              buildBadge(
                                text: transaction.cuenta,
                                backgroundColor: tipoColor,
                                textStyle: badgeTextStyle!,
                              ),
                            );
                          } else if (transaction.tipoTransaccion == 'Gastos' ||
                              transaction.tipoTransaccion == 'Pagos' ||
                              transaction.tipoTransaccion == 'Ingresos') {
                            if (transaction.categoria.toLowerCase() ==
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
                              badges.add(const SizedBox(width: 4));
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
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
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
                          currencyFormat.format(transaction.monto.abs()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tipoColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Container(
      decoration:
          themeManager.isDarkMode
              ? null
              : BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            themeManager.isDarkMode
                ? themeManager.themeData.scaffoldBackgroundColor
                : Colors.transparent,
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildBalanceCard(),
                        const SizedBox(height: 16),
                        _buildAccountsCarousel(),
                        const SizedBox(height: 16),
                        _buildTransactionsList(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

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
}
