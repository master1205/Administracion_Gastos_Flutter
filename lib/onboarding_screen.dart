import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notificaciones/local_notifications.dart';
import 'package:notificaciones/loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State
  int _currentPage = 0;
  bool _notificationsActivated = false;
  bool _isLoading = false;

  // Constants
  static const int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Animations Setup
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  // Navigation
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onFinish() async {
    // Validar nombre en la primera página
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Por favor ingresa tu nombre para continuar');
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      await prefs.setString('username', _nameController.text.trim());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    const LoadingScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al guardar la información');
    }
  }

  Future<void> _activateNotifications() async {
    setState(() => _isLoading = true);

    try {
      await LocalNotifications.requestNotificationPermission();
      await LocalNotifications.requestAlarmExactPermission();
      await LocalNotifications.scheduleDailyMorningNotification();
      await LocalNotifications.scheduleDailyAfternoonNotification();
      await LocalNotifications.scheduleDailyNightNotification();

      setState(() {
        _notificationsActivated = true;
        _isLoading = false;
      });

      _showSuccessSnackBar('Notificaciones activadas correctamente');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al activar notificaciones');
    }
  }

  // UI Helpers
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 18.sp,
            ), // ✅ REDUCIDO de 20
            SizedBox(width: 10.w), // ✅ REDUCIDO de 12
            Expanded(
              child: Text(message, style: TextStyle(fontSize: 13.sp)),
            ), // ✅ REDUCIDO de 14
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(14.r), // ✅ REDUCIDO de 16
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(child: Text(message, style: TextStyle(fontSize: 13.sp))),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(14.r),
      ),
    );
  }

  // Page Builders
  Widget _buildWelcomePage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.1),
            const Color(0xFF764ba2).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(22.r), // ✅ REDUCIDO de 24
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: EdgeInsets.all(18.r), // ✅ REDUCIDO de 20
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 22.r, // ✅ REDUCIDO de 25
                          offset: Offset(0, 10.h), // ✅ REDUCIDO de 12
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icons/cochinito.png',
                      height: 90.h, // ✅ REDUCIDO de 100
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 36.h), // ✅ REDUCIDO de 40
              Text(
                '¡Bienvenido!',
                style: GoogleFonts.lato(
                  fontSize: 30.sp, // ✅ REDUCIDO de 32
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h), // ✅ REDUCIDO de 12
              Text(
                'Administra tus finanzas de manera\nsencilla y eficiente',
                style: GoogleFonts.openSans(
                  fontSize: 13.sp, // ✅ REDUCIDO de 14
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 36.h), // ✅ REDUCIDO de 40
              Container(
                padding: EdgeInsets.all(18.r), // ✅ REDUCIDO de 20
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r), // ✅ REDUCIDO de 20
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16.r, // ✅ REDUCIDO de 18
                      offset: Offset(0, 6.h), // ✅ REDUCIDO de 8
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Personaliza tu experiencia',
                      style: GoogleFonts.lato(
                        fontSize: 15.sp, // ✅ REDUCIDO de 16
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                    SizedBox(height: 14.h), // ✅ REDUCIDO de 16
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.openSans(
                        fontSize: 13.sp, // ✅ REDUCIDO de 14
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ingresa tu nombre',
                        hintStyle: GoogleFonts.openSans(
                          color: Colors.grey.shade400,
                          fontSize: 13.sp,
                        ),
                        prefixIcon: Container(
                          margin: EdgeInsets.all(9.r), // ✅ REDUCIDO de 10
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(9.r),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 17.sp, // ✅ REDUCIDO de 18
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            12.r,
                          ), // ✅ REDUCIDO de 14
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: const Color(0xFF667eea),
                            width: 2.w,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, // ✅ REDUCIDO de 18
                          vertical: 14.h, // ✅ REDUCIDO de 16
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFf093fb).withOpacity(0.1),
            const Color(0xFFF5576c).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(22.r), // ✅ REDUCIDO de 24
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: EdgeInsets.all(25.r), // ✅ REDUCIDO de 28
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFf093fb).withOpacity(0.4),
                      blurRadius: 22.r, // ✅ REDUCIDO de 25
                      offset: Offset(0, 10.h), // ✅ REDUCIDO de 12
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 65.sp, // ✅ REDUCIDO de 70
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 36.h), // ✅ REDUCIDO de 40
              Text(
                'Mantente Informado',
                style: GoogleFonts.lato(
                  fontSize: 26.sp, // ✅ REDUCIDO de 28
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h), // ✅ REDUCIDO de 12
              Text(
                'Recibe notificaciones sobre tus\ntransacciones y presupuestos',
                style: GoogleFonts.openSans(
                  fontSize: 13.sp, // ✅ REDUCIDO de 14
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 36.h), // ✅ REDUCIDO de 40
              Container(
                padding: EdgeInsets.all(18.r), // ✅ REDUCIDO de 20
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r), // ✅ REDUCIDO de 20
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16.r, // ✅ REDUCIDO de 18
                      offset: Offset(0, 6.h), // ✅ REDUCIDO de 8
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.schedule_rounded,
                      title: 'Recordatorios Diarios',
                      description: 'A las 10 AM, 3 PM y 9 PM',
                      color: const Color(0xFF667eea),
                    ),
                    SizedBox(height: 12.h), // ✅ REDUCIDO de 14
                    _buildFeatureItem(
                      icon: Icons.trending_up_rounded,
                      title: 'Alertas de Presupuesto',
                      description: 'Controla tus gastos',
                      color: const Color(0xFFf093fb),
                    ),
                    SizedBox(height: 12.h),
                    _buildFeatureItem(
                      icon: Icons.receipt_long_rounded,
                      title: 'Resúmenes Mensuales',
                      description: 'Reportes automáticos',
                      color: const Color(0xFF4facfe),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 25.h), // ✅ REDUCIDO de 28
              if (_notificationsActivated)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 25.w,
                    vertical: 12.h,
                  ), // ✅ REDUCIDO
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 2.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade600,
                        size: 22.sp,
                      ), // ✅ REDUCIDO
                      SizedBox(width: 9.w), // ✅ REDUCIDO de 10
                      Text(
                        '¡Notificaciones Activadas!',
                        style: GoogleFonts.lato(
                          fontSize: 13.sp, // ✅ REDUCIDO de 14
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 48.h, // ✅ REDUCIDO de 50
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFf093fb).withOpacity(0.4),
                        blurRadius: 9.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _activateNotifications,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Center(
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.3.w,
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_active_rounded,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ), // ✅ REDUCIDO
                                    SizedBox(width: 9.w),
                                    Text(
                                      'Activar Notificaciones',
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: 14.sp, // ✅ REDUCIDO de 15
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
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4facfe).withOpacity(0.1),
            const Color(0xFF00f2fe).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(22.r), // ✅ REDUCIDO de 24
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: EdgeInsets.all(25.r), // ✅ REDUCIDO de 28
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4facfe).withOpacity(0.4),
                      blurRadius: 22.r, // ✅ REDUCIDO de 25
                      offset: Offset(0, 10.h), // ✅ REDUCIDO de 12
                    ),
                  ],
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 65.sp, // ✅ REDUCIDO de 70
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 36.h), // ✅ REDUCIDO de 40
              Text(
                '¡Todo Listo!',
                style: GoogleFonts.lato(
                  fontSize: 30.sp, // ✅ REDUCIDO de 32
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h), // ✅ REDUCIDO de 12
              Text(
                'Estás listo para comenzar a\nadministrar tus finanzas',
                style: GoogleFonts.openSans(
                  fontSize: 13.sp, // ✅ REDUCIDO de 14
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 36.h), // ✅ REDUCIDO de 40
              Container(
                padding: EdgeInsets.all(18.r), // ✅ REDUCIDO de 20
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildCheckItem(
                      icon: Icons.person_rounded,
                      text: 'Perfil configurado',
                      color: const Color(0xFF667eea),
                    ),
                    SizedBox(height: 9.h), // ✅ REDUCIDO de 10
                    _buildCheckItem(
                      icon: Icons.notifications_rounded,
                      text:
                          _notificationsActivated
                              ? 'Notificaciones activas'
                              : 'Notificaciones desactivadas',
                      color:
                          _notificationsActivated
                              ? Colors.green
                              : Colors.orange,
                    ),
                    SizedBox(height: 9.h),
                    _buildCheckItem(
                      icon: Icons.check_circle_rounded,
                      text: 'Listo para comenzar',
                      color: const Color(0xFF4facfe),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 25.h), // ✅ REDUCIDO de 28
              Container(
                width: double.infinity,
                height: 48.h, // ✅ REDUCIDO de 50
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4facfe).withOpacity(0.4),
                      blurRadius: 9.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _onFinish,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Center(
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.3.w,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¡Empezar Ahora!',
                                    style: GoogleFonts.lato(
                                      color: Colors.white,
                                      fontSize: 14.sp, // ✅ REDUCIDO de 15
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 9.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ), // ✅ REDUCIDO
                                ],
                              ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(9.r), // ✅ REDUCIDO de 10
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20.sp,
          ), // ✅ REDUCIDO de 22
        ),
        SizedBox(width: 12.w), // ✅ REDUCIDO de 14
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 13.sp, // ✅ REDUCIDO de 14
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
              ),
              Text(
                description,
                style: GoogleFonts.openSans(
                  fontSize: 11.sp, // ✅ REDUCIDO de 12
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r), // ✅ REDUCIDO de 7
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 17.sp), // ✅ REDUCIDO de 18
        ),
        SizedBox(width: 9.w), // ✅ REDUCIDO de 10
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 13.sp, // ✅ REDUCIDO de 14
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _animationController.reset();
              _animationController.forward();
            },
            children: [
              _buildWelcomePage(),
              _buildNotificationsPage(),
              _buildFinalPage(),
            ],
          ),
          // Navigation Controls
          Positioned(
            bottom: 30.h, // ✅ REDUCIDO de 32
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 26.w,
              ), // ✅ REDUCIDO de 28
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  if (_currentPage > 0)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 7.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _previousPage,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 20.sp,
                        ), // ✅ REDUCIDO de 22
                        color: const Color(0xFF667eea),
                        padding: EdgeInsets.all(9.r),
                      ),
                    )
                  else
                    SizedBox(width: 42.w), // ✅ REDUCIDO de 44
                  // Page Indicator
                  AnimatedSmoothIndicator(
                    activeIndex: _currentPage,
                    count: _totalPages,
                    effect: ExpandingDotsEffect(
                      activeDotColor: const Color(0xFF667eea),
                      dotColor: Colors.grey.shade300,
                      dotHeight: 6.h, // ✅ REDUCIDO de 7
                      dotWidth: 6.w,
                      spacing: 4.w, // ✅ REDUCIDO de 5
                      expansionFactor: 3.5,
                    ),
                  ),
                  // Next/Finish Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 7.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _nextPage,
                      icon: Icon(
                        _currentPage == _totalPages - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 20.sp, // ✅ REDUCIDO de 22
                      ),
                      color: Colors.white,
                      padding: EdgeInsets.all(9.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
