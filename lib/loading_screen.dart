import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:notificaciones/home_screen.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'data_provider.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // State
  int _dotsCount = 0;
  bool _isLoading = true;
  double _progress = 0.0;

  // Loading steps
  final List<String> _loadingSteps = [
    'Inicializando...',
    'Cargando cuentas...',
    'Obteniendo transacciones...',
    'Sincronizando metas...',
    'Preparando dashboard...',
    'Casi listo...',
  ];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _startLoadingAnimation();
    _startProgressAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Animations Setup
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  // Loading Animations
  void _startLoadingAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isLoading && mounted) {
        setState(() {
          _dotsCount = (_dotsCount + 1) % 4;
        });
        return true;
      }
      return false;
    });
  }

  void _startProgressAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isLoading && mounted) {
        setState(() {
          if (_progress < 0.95) {
            _progress += 0.05;
            // Cambiar mensaje cada 20% de progreso
            int newStep = (_progress * _loadingSteps.length).floor();
            if (newStep != _currentStep && newStep < _loadingSteps.length) {
              _currentStep = newStep;
            }
          }
        });
        return true;
      }
      return false;
    });
  }

  // Data Loading
  Future<void> _loadData() async {
    try {
      await initializeDateFormatting('es_ES', null);

      if (!mounted) return;

      // Paso 0: Inicializar categorías por defecto (DESHABILITADO)
      // final prefs = await SharedPreferences.getInstance();
      // final categoriasInicializadas =
      //     prefs.getBool('categorias_inicializadas') ?? false;

      // if (!categoriasInicializadas) {
      //   setState(() {
      //     _currentStep = 0;
      //     _progress = 0.1;
      //   });
      //   await inicializarCategoriasDefecto();
      //   await prefs.setBool('categorias_inicializadas', true);
      // }

      if (!mounted) return;

      // Paso 1: Cargar datos principales
      setState(() {
        _currentStep = 1;
        _progress = 0.2;
      });

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.loadData();

      if (!mounted) return;

      // Paso 2: Sincronizar metas de ahorro
      setState(() {
        _currentStep = 3;
        _progress = 0.7;
      });

      await _sincronizarMetas();

      if (!mounted) return;

      // Asegurar que llegue al 100%
      setState(() {
        _progress = 1.0;
        _currentStep = _loadingSteps.length - 1;
      });

      // Pequeña pausa para mostrar el 100%
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Transición suave a HomeScreen
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Manejo de errores
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(e.toString());
    }
  }

  Future<void> _sincronizarMetas() async {
    try {
      print('🔄 Sincronizando metas de ahorro...');

      // 1. Obtener metas del servidor
      final apiService = ApiService();
      final metasServidor = await apiService.getMetas();

      // 2. Guardar localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'metas_ahorro',
        json.encode(metasServidor.map((m) => m.toJson()).toList()),
      );

      print('✅ Metas sincronizadas: ${metasServidor.length} metas');
    } catch (e) {
      print('⚠️ Error al sincronizar metas: $e');
      // No detenemos la carga si falla la sincronización
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Container(
              padding: EdgeInsets.all(20.r), // ✅ REDUCIDO de 24
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 16
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 40.sp, // ✅ REDUCIDO de 48
                      color: Colors.red.shade400,
                    ),
                  ),
                  SizedBox(height: 16.h), // ✅ REDUCIDO de 20
                  Text(
                    'Error al Cargar',
                    style: GoogleFonts.lato(
                      fontSize: 18.sp, // ✅ REDUCIDO de 20
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  SizedBox(height: 10.h), // ✅ REDUCIDO de 12
                  Text(
                    'Hubo un problema al cargar los datos. Por favor, intenta nuevamente.',
                    style: GoogleFonts.openSans(
                      fontSize: 12.sp, // ✅ REDUCIDO de 14
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 18.h), // ✅ REDUCIDO de 20
                  Container(
                    width: double.infinity,
                    height: 44.h, // ✅ REDUCIDO de 48
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _isLoading = true;
                            _progress = 0.0;
                            _currentStep = 0;
                          });
                          _loadData();
                        },
                        borderRadius: BorderRadius.circular(10.r),
                        child: Center(
                          child: Text(
                            'Reintentar',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 14.sp, // ✅ REDUCIDO de 16
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // UI Builders
  Widget _buildBackground(bool isDarkMode) {
    if (isDarkMode) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade900, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF5F7FA),
            const Color(0xFF667eea).withOpacity(0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildLoadingContent(ThemeManager themeManager) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: EdgeInsets.all(20.r), // ✅ REDUCIDO de 24
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 24.r, // ✅ REDUCIDO de 30
                      offset: Offset(0, 12.h), // ✅ REDUCIDO de 15
                    ),
                  ],
                ),
                child: Lottie.asset(
                  'assets/animations/spash_screen.json',
                  width: 100.w, // ✅ REDUCIDO de 120
                  height: 100.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 40.h), // ✅ REDUCIDO de 48
            // Título
            Text(
              'Administración de Gastos',
              style: GoogleFonts.lato(
                fontSize: 28.sp, // ✅ REDUCIDO de 32
                fontWeight: FontWeight.bold,
                color:
                    themeManager.isDarkMode
                        ? Colors.white
                        : const Color(0xFF2D3436),
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 6.h), // ✅ REDUCIDO de 8
            Text(
              'Tu gestor financiero personal',
              style: GoogleFonts.openSans(
                fontSize: 12.sp, // ✅ REDUCIDO de 14
                color:
                    themeManager.isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
              ),
            ),

            SizedBox(height: 52.h), // ✅ REDUCIDO de 64
            // Contenedor de progreso
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 40.w,
              ), // ✅ REDUCIDO de 48
              padding: EdgeInsets.all(20.r), // ✅ REDUCIDO de 24
              decoration: BoxDecoration(
                color:
                    themeManager.isDarkMode
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.white,
                borderRadius: BorderRadius.circular(18.r), // ✅ REDUCIDO de 20
                boxShadow: [
                  BoxShadow(
                    color:
                        themeManager.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                    blurRadius: 16.r, // ✅ REDUCIDO de 20
                    offset: Offset(0, 8.h), // ✅ REDUCIDO de 10
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Barra de progreso moderna
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Stack(
                      children: [
                        Container(
                          height: 7.h, // ✅ REDUCIDO de 8
                          decoration: BoxDecoration(
                            color:
                                themeManager.isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 7.h,
                          width:
                              MediaQuery.of(context).size.width *
                              _progress *
                              0.7,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.5),
                                blurRadius: 6.r, // ✅ REDUCIDO de 8
                                offset: Offset(0, 1.5.h), // ✅ REDUCIDO de 2
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h), // ✅ REDUCIDO de 20
                  // Porcentaje y mensaje
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _currentStep < _loadingSteps.length
                              ? _loadingSteps[_currentStep]
                              : 'Cargando',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp, // ✅ REDUCIDO de 15
                            fontWeight: FontWeight.w600,
                            color:
                                themeManager.isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF2D3436),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w, // ✅ REDUCIDO de 12
                          vertical: 5.h, // ✅ REDUCIDO de 6
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(
                            6.r,
                          ), // ✅ REDUCIDO de 8
                        ),
                        child: Text(
                          '${(_progress * 100).toInt()}%',
                          style: GoogleFonts.lato(
                            fontSize: 12.sp, // ✅ REDUCIDO de 14
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h), // ✅ REDUCIDO de 12
                  // Puntos animados
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(
                          horizontal: 3.w,
                        ), // ✅ REDUCIDO de 4
                        width:
                            _dotsCount > index ? 7.w : 5.w, // ✅ REDUCIDO de 8/6
                        height: _dotsCount > index ? 7.h : 5.h,
                        decoration: BoxDecoration(
                          color:
                              _dotsCount > index
                                  ? const Color(0xFF667eea)
                                  : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h), // ✅ REDUCIDO de 40
            // Mensaje de espera
            Text(
              'Preparando tu experiencia financiera',
              style: GoogleFonts.openSans(
                fontSize: 11.sp, // ✅ REDUCIDO de 13
                color:
                    themeManager.isDarkMode
                        ? Colors.grey.shade500
                        : Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(themeManager.isDarkMode),

          // Content
          SafeArea(child: Center(child: _buildLoadingContent(themeManager))),
        ],
      ),
    );
  }
}
