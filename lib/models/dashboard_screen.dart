import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/models/Account.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  double saldoCuentas = 0.0;
  double ingresos = 0.0;
  double gastos = 0.0;
  List<Map<String, dynamic>> cuentas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        isLoading = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        apiService.fetchSaldos(),
        apiService.fetchCuentas(),
      ]);

      final Map<String, dynamic> saldos = results[0] as Map<String, dynamic>;
      final List<Account> cuentas = results[1] as List<Account>;

      setState(() {
        saldoCuentas = saldos['saldoCuentas'].toDouble();
        ingresos = saldos['ingresos'].toDouble();
        gastos = saldos['gastos'].toDouble();
        this.cuentas =
            cuentas.map((account) {
              return {
                'nombre': account.nombre,
                'saldo': account.saldo,
                'imagen': account.imagen,
              };
            }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadData();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var format = NumberFormat.currency(locale: 'es_MX', symbol: '\$ ');
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Importante para ver el gradiente
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Inicio",
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        // Gradiente de fondo
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                theme.brightness == Brightness.dark
                    ? [
                      const Color(0xFF2F345C),
                      const Color(0xFF1A1A24),
                      const Color(0xFF1A1A24),
                      const Color(0xFF1A1A24),
                      const Color(0xFF1A1A24),
                      const Color(0xFF1A1A24),
                      const Color(0xFF1A1A24),
                      const Color(0xFF1A1A24),
                    ]
                    : [
                      Color(0xFFBABEF9),
                      Color(0xFFF4F5FA),
                      Color(0xFFF4F5FA),
                      Color(0xFFF4F5FA),
                      Color(0xFFF4F5FA),
                      Color(0xFFF4F5FA),
                      Color(0xFFF4F5FA),
                      Color(0xFFF4F5FA),
                    ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Card(
                        // Tarjeta con un color semitransparente
                        color: theme.cardColor.withOpacity(0.65),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Saldo disponible",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: saldoCuentas,
                                ),
                                duration: const Duration(seconds: 1),
                                builder: (context, value, child) {
                                  return Text(
                                    format.format(value),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      const Icon(
                                        Icons.attach_money,
                                        size: 30,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Ingresos",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: ingresos,
                                        ),
                                        duration: const Duration(seconds: 1),
                                        builder: (context, value, child) {
                                          return Text(
                                            format.format(value),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart,
                                        size: 30,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Gastos",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: gastos,
                                        ),
                                        duration: const Duration(seconds: 1),
                                        builder: (context, value, child) {
                                          return Text(
                                            format.format(value),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: theme.cardColor.withOpacity(0.65),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Cuentas",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...cuentas.map((cuenta) {
                                String imagen = '${cuenta['imagen']}.png';
                                return ListTile(
                                  leading: Image.asset(
                                    'assets/images/$imagen',
                                    width: 32,
                                    height: 32,
                                  ),
                                  title: Text(
                                    cuenta['nombre'],
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: cuenta['saldo'].toDouble(),
                                    ),
                                    duration: const Duration(seconds: 1),
                                    builder: (context, value, child) {
                                      return Text(
                                        format.format(value),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
