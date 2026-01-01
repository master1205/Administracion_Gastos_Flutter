import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:notificaciones/api_service.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/models/Account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class GraficasScreen extends StatefulWidget {
  const GraficasScreen({Key? key}) : super(key: key);

  @override
  GraficasScreenState createState() => GraficasScreenState();
}

class GraficasScreenState extends State<GraficasScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late Future<List<dynamic>> _futureData;
  bool _isLoading = false;

  // Keys para el tutorial
  final GlobalKey _tabBarKeyGastosPorCategoria = GlobalKey();
  final GlobalKey _tabBarKeyCuentasYSaldos = GlobalKey();
  // Variables para el tutorial
  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _futureData = Future.wait([
      ApiService().fetchGastosPorCategoria(),
      ApiService().fetchCuentas(),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        showTutorial();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _futureData = Future.wait([
        ApiService().fetchGastosPorCategoria(),
        ApiService().fetchCuentas(),
      ]);
    });
  }

  Future<void> showTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    // Usamos una clave única para GraficasScreen, por ejemplo "tutorial_graficas_shown"
    if (!(prefs.getBool('tutorial_graficas_shown') ?? false)) {
      createTutorial();
      tutorialCoachMark.show(context: context);
    }
  }

  Future<void> createTutorial() async {
    _initTutorialTargets();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.red,
      textSkip: "Omitir",
      paddingFocus: 10,
      opacityShadow: 0.5,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () async {
        await (await SharedPreferences.getInstance()).setBool(
          'tutorial_graficas_shown',
          true,
        );
      },
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('tutorial_graficas_shown', true);
        });
        return true;
      },
    );
  }

  void _initTutorialTargets() {
    targets.clear();

    targets.add(
      TargetFocus(
        identify: "GastosPorCategoriaTab",
        keyTarget: _tabBarKeyGastosPorCategoria,
        color: Colors.deepPurple,
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
                    colors: [Colors.deepPurple, Colors.purple],
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
                      "Gastos por Categoría",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Explora el gráfico de barras para ver tus gastos distribuidos por categoría.",
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

    targets.add(
      TargetFocus(
        identify: "CuentasYSaldosTab",
        keyTarget: _tabBarKeyCuentasYSaldos,
        color: Colors.deepOrange,
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
                    colors: [Colors.deepOrange, Colors.orange],
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
                      "Cuentas y Saldos",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Consulta el balance de tus cuentas de forma clara y organizada.",
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration:
          isDarkMode
              ? null
              : BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
      child: Scaffold(
        backgroundColor:
            isDarkMode ? theme.scaffoldBackgroundColor : Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              //key: _tabBarKey,
              child: TabBar(
                controller: _tabController,
                labelColor:
                    isDarkMode ? Colors.white : theme.colorScheme.primary,
                unselectedLabelColor:
                    isDarkMode
                        ? Colors.white70
                        : theme.colorScheme.primary.withOpacity(0.6),
                indicatorColor:
                    isDarkMode ? Colors.white : theme.colorScheme.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    key: _tabBarKeyGastosPorCategoria,
                    text: 'Gastos por Categoría',
                  ),
                  Tab(key: _tabBarKeyCuentasYSaldos, text: 'Cuentas y Saldos'),
                ],
              ),
            ),
          ),
        ),
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
                : FutureBuilder<List<dynamic>>(
                  future: _futureData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay datos disponibles',
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    } else {
                      final gastosPorCategoria =
                          snapshot.data![0] as Map<String, double>;
                      final cuentas = snapshot.data![1] as List<Account>;
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          RefreshIndicator(
                            onRefresh: refreshData,
                            child:
                                gastosPorCategoria.isEmpty
                                    ? Center(
                                      child: Text(
                                        'No hay datos disponibles',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    )
                                    : _buildGastosPorCategoria(
                                      gastosPorCategoria,
                                    ),
                          ),
                          RefreshIndicator(
                            onRefresh: refreshData,
                            child:
                                cuentas.isEmpty
                                    ? Center(
                                      child: Text(
                                        'No hay datos disponibles',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    )
                                    : _buildCuentasYSaldos(cuentas),
                          ),
                        ],
                      );
                    }
                  },
                ),
      ),
    );
  }

  Widget _buildGastosPorCategoria(Map<String, double> data) {
    final theme = Theme.of(context);
    final List<BarChartGroupData> barGroups = [];
    double totalGastos = 0;
    final List<Widget> rows = [];
    int index = 0;
    data.forEach((category, amount) {
      final color = _getRandomColor();
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              fromY: 0,
              toY: amount,
              color: color,
              width: 20,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: false,
                toY: 0,
                color: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      );
      totalGastos += amount;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  category,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                NumberFormat.currency(symbol: '\$ ').format(amount),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
      index++;
    });

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total: ${NumberFormat.currency(symbol: '\$ ').format(totalGastos)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      barGroups: barGroups,
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                      gridData: FlGridData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Column(children: rows),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCuentasYSaldos(List<Account> data) {
    final theme = Theme.of(context);
    final List<BarChartGroupData> barGroups = [];
    double totalSaldo = 0;
    final List<Widget> rows = [];
    int index = 0;
    for (var account in data) {
      final color = _getRandomColor();
      double saldo = account.saldo ?? 0;
      totalSaldo += saldo;
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              fromY: 0,
              toY: saldo,
              color: color,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  account.nombre,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                NumberFormat.currency(symbol: '\$ ').format(saldo),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
      index++;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total: ${NumberFormat.currency(symbol: '\$ ').format(totalSaldo)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      barGroups: barGroups,
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                      gridData: FlGridData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Column(children: rows),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }
}
