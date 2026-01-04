import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:card_swiper/card_swiper.dart';
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
  // Constants
  static const String _tutorialKey = 'tutorial_dashboard_shown';
  static const Duration _animationDuration = Duration(milliseconds: 800);
  static const int _maxRecentTransactions = 5;

  // Keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _balanceCardKey = GlobalKey();
  final GlobalKey _accountsCarouselKey = GlobalKey();
  final GlobalKey _verTodoKey = GlobalKey();

  // Formatters
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  // State
  List<Account> _accounts = [];
  Map<String, dynamic>? _balanceData;
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  // Tutorial
  late TutorialCoachMark _tutorialCoachMark;
  final List<TargetFocus> _targets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  // Initialization
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchAccounts(),
        _fetchSaldos(),
        _fetchTransactions(),
      ]);
      await _maybeShowDashboardTutorial();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tutorial Methods
  Future<void> _maybeShowDashboardTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final homeTutorialShown = prefs.getBool('tutorial_home_shown') ?? false;
    final dashboardTutorialShown = prefs.getBool(_tutorialKey) ?? false;

    if (homeTutorialShown && !dashboardTutorialShown) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _createTutorial();
          _tutorialCoachMark.show(context: context);
        }
      });
    } else if (!homeTutorialShown) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _maybeShowDashboardTutorial();
      });
    }
  }

  void _createTutorial() {
    _initTargets();
    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black,
      textSkip: "",
      paddingFocus: 10,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_tutorialKey, true);
      },
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool(_tutorialKey, true);
        });
        return true;
      },
    );
  }

  void _initTargets() {
    _targets.clear();
    _targets.addAll([
      _createBalanceTarget(),
      _createAccountsTarget(),
      _createViewAllTarget(),
    ]);
  }

  TargetFocus _createBalanceTarget() {
    return TargetFocus(
      identify: "BalanceCard",
      keyTarget: _balanceCardKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 20,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r), // ✅ REDUCIDO de 20
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "💰 Balance Total",
                description:
                    "Aquí puedes ver tu saldo acumulado, ingresos y gastos en un solo vistazo.",
                icon: Icons.account_balance_wallet_rounded,
                gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                currentStep: 1,
                totalSteps: 3,
                onNext: controller.next,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createAccountsTarget() {
    return TargetFocus(
      identify: "AccountsCarousel",
      keyTarget: _accountsCarouselKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 20,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "💳 Tus Cuentas",
                description:
                    "Desliza para explorar todas tus cuentas. Cada tarjeta muestra el saldo disponible.",
                icon: Icons.credit_card_rounded,
                gradientColors: const [Color(0xFFf093fb), Color(0xFFF5576c)],
                currentStep: 2,
                totalSteps: 3,
                onNext: controller.next,
                onBack: controller.previous,
                onSkip: controller.skip,
              ),
        ),
      ],
    );
  }

  TargetFocus _createViewAllTarget() {
    return TargetFocus(
      identify: "VerTodoButton",
      keyTarget: _verTodoKey,
      color: Colors.transparent,
      enableOverlayTab: true,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          padding: EdgeInsets.all(16.r),
          builder:
              (context, controller) => _buildModernTutorialCard(
                title: "📊 Historial Completo",
                description:
                    "Toca aquí para ver todas tus transacciones y analiza tus hábitos.",
                icon: Icons.history_rounded,
                gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                currentStep: 3,
                totalSteps: 3,
                onNext: controller.next,
                onBack: controller.previous,
                isLastStep: true,
              ),
        ),
      ],
    );
  }

  Widget _buildModernTutorialCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required int currentStep,
    required int totalSteps,
    VoidCallback? onNext,
    VoidCallback? onBack,
    VoidCallback? onSkip,
    bool isLastStep = false,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: 280.w), // ✅ REDUCIDO de 350
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r), // ✅ REDUCIDO de 24
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 20
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r), // ✅ REDUCIDO de 12
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 26.sp,
                    color: Colors.white,
                  ), // ✅ REDUCIDO de 32
                ),
                SizedBox(height: 8.h), // ✅ REDUCIDO de 12
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp, // ✅ REDUCIDO de 20
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 20
            child: Column(
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp, // ✅ REDUCIDO de 14
                    height: 1.3,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h), // ✅ REDUCIDO de 16
                _buildProgressIndicator(
                  currentStep,
                  totalSteps,
                  gradientColors,
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isLastStep && onSkip != null)
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          minimumSize: Size(50.w, 32.h),
                        ),
                        child: Text(
                          'Omitir',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.sp, // ✅ REDUCIDO de 14
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        if (onBack != null)
                          Container(
                            margin: EdgeInsets.only(right: 6.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onBack,
                              icon: Icon(Icons.arrow_back_rounded, size: 16.sp),
                              color: Colors.grey.shade700,
                              padding: EdgeInsets.all(6.r),
                              constraints: BoxConstraints(
                                minWidth: 30.w,
                                minHeight: 30.h,
                              ),
                            ),
                          ),
                        if (onNext != null)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors.first.withOpacity(0.4),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 3.h),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onNext,
                                borderRadius: BorderRadius.circular(18.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isLastStep
                                            ? '¡Entendido!'
                                            : 'Siguiente',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        isLastStep
                                            ? Icons.check_rounded
                                            : Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 14.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    int currentStep,
    int totalSteps,
    List<Color> gradientColors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: isCurrent ? 20.w : 5.w,
          height: 5.h,
          decoration: BoxDecoration(
            gradient:
                isActive || isCurrent
                    ? LinearGradient(colors: gradientColors)
                    : null,
            color: !isActive && !isCurrent ? Colors.grey.shade300 : null,
            borderRadius: BorderRadius.circular(2.5.r),
          ),
        );
      }),
    );
  }

  // Data Fetching
  Future<void> _fetchAccounts() async {
    try {
      final fetchedAccounts =
          await Provider.of<DataProvider>(
            context,
            listen: false,
          ).apiService.fetchCuentas();
      if (mounted) setState(() => _accounts = fetchedAccounts);
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
      if (mounted) setState(() => _balanceData = fetchedSaldos);
    } catch (e) {
      debugPrint('Error al cargar saldos: $e');
      if (mounted) {
        setState(
          () =>
              _balanceData = {
                'saldoCuentas': 0.0,
                'ingresos': 0.0,
                'gastos': 0.0,
              },
        );
      }
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final fetchedTransactions =
          await Provider.of<DataProvider>(
            context,
            listen: false,
          ).apiService.fetchTransactions();
      if (mounted) setState(() => _transactions = fetchedTransactions);
    } catch (e) {
      debugPrint('Error al cargar transacciones: $e');
    }
  }

  Future<void> refreshData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchAccounts(), _fetchSaldos(), _fetchTransactions()]);
    if (mounted) setState(() => _isLoading = false);
  }

  // UI Builders - Balance Card
  Widget _buildBalanceCard() {
    final themeManager = Provider.of<ThemeManager>(context);

    final double saldoTotal = double.parse(
      (_balanceData?['saldoCuentas'] ?? 0.0).toString(),
    );
    final double ingresos = double.parse(
      (_balanceData?['ingresos'] ?? 0.0).toString(),
    );
    final double gastos = double.parse(
      (_balanceData?['gastos'] ?? 0.0).toString(),
    );

    return Container(
      key: _balanceCardKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r), // ✅ REDUCIDO de 24
        gradient: LinearGradient(
          colors:
              themeManager.isDarkMode
                  ? [Colors.grey.shade800, Colors.grey.shade900]
                  : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color:
                themeManager.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15.r, // ✅ REDUCIDO de 20
            offset: Offset(0, 8.h), // ✅ REDUCIDO de 10
          ),
        ],
      ),
      padding: EdgeInsets.all(18.r), // ✅ REDUCIDO de 20
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Total',
                    style: TextStyle(
                      fontSize: 12.sp, // ✅ REDUCIDO de 13
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 5.h), // ✅ REDUCIDO de 6
                  _buildAnimatedBalance(saldoTotal),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12.r), // ✅ REDUCIDO de 14
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24.sp, // ✅ REDUCIDO de 28
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h), // ✅ REDUCIDO de 24
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'Ingresos',
                  ingresos,
                  Icons.trending_up_rounded,
                  Colors.greenAccent,
                ),
              ),
              Container(
                width: 1.w,
                height: 40.h, // ✅ REDUCIDO de 45
                color: Colors.white.withOpacity(0.3),
                margin: EdgeInsets.symmetric(
                  horizontal: 10.w,
                ), // ✅ REDUCIDO de 12
              ),
              Expanded(
                child: _buildStatColumn(
                  'Gastos',
                  gastos,
                  Icons.trending_down_rounded,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBalance(double amount) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: _animationDuration,
      builder: (context, animatedValue, _) {
        return Text(
          _currencyFormat.format(animatedValue),
          style: GoogleFonts.lato(
            fontSize: 28.sp, // ✅ REDUCIDO de 32
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(4.r), // ✅ REDUCIDO de 5
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(icon, color: color, size: 12.sp), // ✅ REDUCIDO de 14
            ),
            SizedBox(width: 5.w), // ✅ REDUCIDO de 6
            Text(
              title,
              style: TextStyle(
                fontSize: 11.sp, // ✅ REDUCIDO de 12
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h), // ✅ REDUCIDO de 6
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: amount),
          duration: _animationDuration,
          builder: (context, animatedValue, _) {
            return Text(
              _currencyFormat.format(animatedValue),
              style: GoogleFonts.lato(
                fontSize: 14.sp, // ✅ REDUCIDO de 16
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
      ],
    );
  }

  // UI Builders - Accounts Carousel
  Widget _buildAccountsCarousel() {
    final sortedAccounts = List<Account>.from(_accounts)
      ..sort((a, b) => (b.saldo ?? 0.0).compareTo(a.saldo ?? 0.0));

    if (sortedAccounts.isEmpty) return _buildEmptyAccounts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 5.h,
          ), // ✅ REDUCIDO de 6
          child: Text(
            'Mis Cuentas',
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ), // ✅ REDUCIDO de 18
          ),
        ),
        SizedBox(
          key: _accountsCarouselKey,
          height: 180.h, // ✅ REDUCIDO de 200
          child: Swiper(
            itemBuilder:
                (BuildContext context, int index) =>
                    _buildAccountCard(sortedAccounts[index]),
            itemCount: sortedAccounts.length,
            viewportFraction: 0.85,
            scale: 0.9,
            loop: sortedAccounts.length > 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAccounts() {
    final themeManager = Provider.of<ThemeManager>(context);

    return Container(
      height: 180.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color:
            themeManager.isDarkMode
                ? Colors.grey.shade800.withOpacity(0.3)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color:
              themeManager.isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
          width: 2.w,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 50.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 10.h),
            Text(
              'No hay cuentas disponibles',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final themeManager = Provider.of<ThemeManager>(context);

    final gradientColors =
        themeManager.isDarkMode
            ? [Colors.grey.shade800, Colors.grey.shade900]
            : [const Color(0xFF4facfe), const Color(0xFF00f2fe)];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r), // ✅ REDUCIDO de 18
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    account.nombre,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo disponible',
                  style: TextStyle(
                    fontSize: 10.sp, // ✅ REDUCIDO de 11
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: account.saldo ?? 0.0),
                  duration: _animationDuration,
                  builder: (context, animatedValue, _) {
                    return Text(
                      _currencyFormat.format(animatedValue),
                      style: GoogleFonts.lato(
                        fontSize: 24.sp, // ✅ REDUCIDO de 28
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.credit_card_rounded,
                        size: 12.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        account.numeroTarjeta ?? "****-****",
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UI Builders - Transactions List
  Widget _buildTransactionsList() {
    final theme = Theme.of(context);

    final sortedTransactions = List<Transaction>.from(_transactions)..sort(
      (a, b) => DateTime.parse(b.fecha).compareTo(DateTime.parse(a.fecha)),
    );

    final displayCount =
        sortedTransactions.length < _maxRecentTransactions
            ? sortedTransactions.length
            : _maxRecentTransactions;

    if (sortedTransactions.isEmpty) return _buildEmptyTransactions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTransactionsHeader(theme),
        SizedBox(height: 10.h), // ✅ REDUCIDO de 12
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayCount,
          separatorBuilder:
              (context, index) => SizedBox(height: 8.h), // ✅ REDUCIDO de 10
          itemBuilder:
              (context, index) => _buildTransactionItem(
                sortedTransactions[index],
                index > 0 ? sortedTransactions[index - 1] : null,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    final themeManager = Provider.of<ThemeManager>(context);

    return Container(
      padding: EdgeInsets.all(28.r), // ✅ REDUCIDO de 32
      decoration: BoxDecoration(
        color:
            themeManager.isDarkMode
                ? Colors.grey.shade800.withOpacity(0.3)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 50.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 10.h),
            Text(
              'No hay transacciones recientes',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transacciones Recientes',
          style: GoogleFonts.lato(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ), // ✅ REDUCIDO de 18
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 6.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: _verTodoKey,
              onTap: () => widget.onTabChange?.call(1),
              borderRadius: BorderRadius.circular(18.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    Transaction transaction,
    Transaction? previousTransaction,
  ) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    final (icon, color) = _getTransactionIconAndColor(
      transaction.tipoTransaccion,
    );
    final showHeader =
        previousTransaction == null ||
        transaction.fecha != previousTransaction.fecha;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) _buildDateHeader(transaction.fecha, theme),
        _buildTransactionCard(transaction, icon, color, themeManager, theme),
      ],
    );
  }

  Widget _buildDateHeader(String date, ThemeData theme) {
    String formattedDate = DateFormat(
      'EEEE, d MMMM',
      'es_ES',
    ).format(DateTime.parse(date));
    formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 5.h), // ✅ REDUCIDO de 10/6
      child: Text(
        formattedDate,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12.sp, // ✅ REDUCIDO de 13
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    IconData icon,
    Color color,
    ThemeManager themeManager,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            themeManager.isDarkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color:
                themeManager.isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 5.h,
        ), // ✅ REDUCIDO de 14/6
        leading: Container(
          padding: EdgeInsets.all(9.r), // ✅ REDUCIDO de 10
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20.sp,
          ), // ✅ REDUCIDO de 22
        ),
        title: Text(
          transaction.descripcion,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13.sp, // ✅ REDUCIDO de 14
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Wrap(
            spacing: 4.w,
            runSpacing: 2.h,
            children: _buildTransactionBadges(transaction, color),
          ),
        ),
        trailing: Text(
          _currencyFormat.format(transaction.monto.abs()),
          style: GoogleFonts.lato(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ), // ✅ REDUCIDO de 15
        ),
      ),
    );
  }

  List<Widget> _buildTransactionBadges(Transaction transaction, Color color) {
    final badges = <Widget>[];

    switch (transaction.tipoTransaccion) {
      case 'Traspasos':
        badges.addAll([
          _buildBadge(transaction.cuentaOrigen, color),
          Icon(Icons.arrow_forward, size: 10.sp, color: Colors.grey),
          _buildBadge(transaction.cuentaDestino, color),
        ]);
        break;
      case 'Reembolsos':
        badges.add(_buildBadge(transaction.cuenta, color));
        break;
      case 'Gastos':
      case 'Pagos':
      case 'Ingresos':
        badges.add(_buildBadge(transaction.categoria, color));
        if (transaction.cuenta.isNotEmpty) {
          badges.add(_buildBadge(transaction.cuenta, color));
        }
        break;
    }

    return badges;
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1.w),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ), // ✅ REDUCIDO de 10
      ),
    );
  }

  (IconData, Color) _getTransactionIconAndColor(String tipoTransaccion) {
    return switch (tipoTransaccion) {
      'Reembolsos' => (Icons.restore_rounded, Colors.purple),
      'Pagos' => (Icons.monetization_on_rounded, Colors.orange),
      'Traspasos' => (Icons.swap_horiz_rounded, Colors.blue),
      'Ingresos' => (Icons.trending_up_rounded, Colors.green),
      'Gastos' => (Icons.trending_down_rounded, Colors.red),
      _ => (Icons.receipt_rounded, Colors.grey),
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          themeManager.isDarkMode
              ? themeManager.themeData.scaffoldBackgroundColor
              : const Color(0xFFF5F7FA),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeManager.isDarkMode
                            ? Colors.white
                            : const Color(0xFF667eea),
                      ),
                      strokeWidth: 3.w,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Cargando datos...',
                      style: TextStyle(
                        color:
                            themeManager.isDarkMode
                                ? Colors.white70
                                : Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: refreshData,
                color: const Color(0xFF667eea),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(14.r), // ✅ REDUCIDO de 16
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(),
                      SizedBox(height: 18.h), // ✅ REDUCIDO de 20
                      _buildAccountsCarousel(),
                      SizedBox(height: 18.h),
                      _buildTransactionsList(),
                      SizedBox(height: 14.h),
                    ],
                  ),
                ),
              ),
    );
  }
}
