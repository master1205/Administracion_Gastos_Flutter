import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:notificaciones/home_screen.dart';
import 'package:notificaciones/services/biometric_service.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
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
  String _loadingMessage = 'Cargando datos...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _startLoadingAnimation();
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

  // Data Loading
  Future<void> _loadData() async {
    final startTime = DateTime.now();

    try {
      await initializeDateFormatting('es_ES', null);

      if (!mounted) return;

      // Verificar autenticación biométrica
      final biometricService = BiometricService();
      final isBiometricEnabled = await biometricService.isBiometricEnabled();

      if (isBiometricEnabled) {
        setState(() {
          _loadingMessage = 'Verificando identidad...';
        });

        final authenticated = await biometricService.authenticate(
          localizedReason: 'Verifica tu identidad para acceder a la aplicación',
        );

        if (!authenticated) {
          if (!mounted) return;
          _showBiometricErrorDialog();
          return;
        }
      }

      if (!mounted) return;

      setState(() {
        _loadingMessage = 'Cargando datos...';
      });

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.loadData();

      if (!mounted) return;

      // Garantizar mínimo 2 segundos de visualización del loading
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 2000) {
        await Future.delayed(
          Duration(milliseconds: 2000 - elapsed.inMilliseconds),
        );
      }

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

  void _showBiometricErrorDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48.sp,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Autenticación fallida',
                  style: GoogleFonts.lato(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'No se pudo verificar tu identidad. Inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF30cfd0),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Reintentar',
                          style: GoogleFonts.lato(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
  Widget _buildBackground(ThemeData theme) {
    return Container(color: theme.colorScheme.background);
  }

  Widget _buildLoadingContent(ThemeManager themeManager) {
    final theme = Theme.of(context);
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
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Lottie.asset(
                  'assets/animations/spash_screen.json',
                  width: 100.w,
                  height: 100.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 40.h),
            // Título
            Text(
              'Administración de Gastos',
              style: GoogleFonts.lato(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Tu gestor financiero personal',
              style: GoogleFonts.openSans(
                fontSize: 12.sp,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
            ),

            SizedBox(height: 52.h), // ✅ REDUCIDO de 64
            // Contenedor de progreso
            Container(
              margin: EdgeInsets.symmetric(horizontal: 40.w),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Mensaje de carga
                  Text(
                    _loadingMessage,
                    style: GoogleFonts.lato(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 10.h),
                  // Puntos animados
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        width: _dotsCount > index ? 7.w : 5.w,
                        height: _dotsCount > index ? 7.h : 5.h,
                        decoration: BoxDecoration(
                          color:
                              _dotsCount > index
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary.withOpacity(
                                    0.3,
                                  ),
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
                fontSize: 11.sp,
                color: theme.colorScheme.secondary.withOpacity(0.6),
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(theme),

          // Content
          SafeArea(child: Center(child: _buildLoadingContent(themeManager))),
        ],
      ),
    );
  }
}
