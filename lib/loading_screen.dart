import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:notificaciones/home_screen.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  int _dotsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _startLoadingAnimation();
  }

  void _startLoadingAnimation() {
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 500));
      if (_isLoading) {
        setState(() {
          _dotsCount = (_dotsCount + 1) % 4;
        });
        return true;
      }
      return false;
    });
  }

  void _loadData() async {
    await initializeDateFormatting('es_ES', null);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.loadData();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
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
        body: Center(
          child: Consumer<DataProvider>(
            builder: (context, dataProvider, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/spash_screen.json',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${dataProvider.loadingMessage}${'.' * _dotsCount}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
