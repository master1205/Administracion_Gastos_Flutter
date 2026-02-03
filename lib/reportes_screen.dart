import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'componentes/heads_up_notification.dart';
import 'utils/animation_utils.dart';
import 'componentes/empty_states.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  ReportesScreenState createState() => ReportesScreenState();
}

class ReportesScreenState extends State<ReportesScreen>
    with WidgetsBindingObserver {
  // Constants
  static const Duration _animationDuration = Duration(milliseconds: 300);

  // State
  late Stream<List<Reporte>> _reportesStream;
  bool _isLoading = false;
  bool _isManualRefresh = false;
  final Map<String, bool> _expandedYears = {};

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
    // Los Streams de Firebase se actualizan automáticamente
  }

  // Initialization
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await initializeDateFormatting('es_ES', null);
      _reportesStream = _obtenerReportesDesdeFirebase();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Obtiene reportes desde Firebase en tiempo real
  Stream<List<Reporte>> _obtenerReportesDesdeFirebase() {
    return FirebaseFirestore.instance
        .collection('reportes')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Reporte(
              name: data['nombre'] ?? 'Reporte Mensual.pdf',
              file: data['urlReporte'] ?? '',
              fechaCorte: '${data['mes']} ${data['año']}',
            );
          }).toList();
        });
  }

  Future<void> refreshData() async {
    setState(() => _isManualRefresh = true);

    // Firebase Stream se actualiza automáticamente, solo esperamos para feedback visual
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isManualRefresh = false);
    }
  }

  // Helpers
  Map<String, List<Reporte>> _agruparReportesPorAno(List<Reporte> reportes) {
    final Map<String, List<Reporte>> reportesPorAno = {};

    for (var reporte in reportes) {
      try {
        final String ano = reporte.fechaCorte.split(' ').last;
        if (!reportesPorAno.containsKey(ano)) {
          reportesPorAno[ano] = [];
        }
        reportesPorAno[ano]!.add(reporte);
      } catch (e) {
        debugPrint('Error al extraer el año: ${reporte.fechaCorte}');
      }
    }

    // Ordenar años de más reciente a más antiguo
    final sortedKeys =
        reportesPorAno.keys.toList()
          ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));

    return {for (var key in sortedKeys) key: reportesPorAno[key]!};
  }

  Future<void> _openReport(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        showErrorNotification(context, message: 'Error al abrir el reporte');
      }
    }
  }

  // UI Builders
  Widget _buildEmptyState() {
    return const EmptyReportsState();
  }

  Widget _buildYearCard({
    required String year,
    required List<Reporte> reportes,
    required ThemeManager themeManager,
  }) {
    final isExpanded = _expandedYears[year] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 6.h,
      ), // ✅ REDUCIDO de 14/7
      decoration: BoxDecoration(
        color:
            themeManager.isDarkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.white,
        borderRadius: BorderRadius.circular(16.r), // ✅ REDUCIDO de 18
        boxShadow: [
          BoxShadow(
            color:
                themeManager.isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 10.r, // ✅ REDUCIDO de 12
            offset: Offset(0, 3.h), // ✅ REDUCIDO de 4
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('expansion_$year'),
          initiallyExpanded: isExpanded,
          tilePadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 6.h,
          ), // ✅ REDUCIDO de 18/7
          childrenPadding: EdgeInsets.only(bottom: 8.h), // ✅ REDUCIDO de 10
          leading: Container(
            padding: EdgeInsets.all(10.r), // ✅ REDUCIDO de 11
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(10.r), // ✅ REDUCIDO de 11
            ),
            child: Icon(
              Icons.folder_rounded,
              color: Colors.white,
              size: 20.sp,
            ), // ✅ REDUCIDO de 22
          ),
          title: Text(
            'Año $year',
            style: GoogleFonts.lato(
              fontSize: 15.sp, // ✅ REDUCIDO de 16
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 2.h), // ✅ REDUCIDO de 3
            child: Text(
              '${reportes.length} reporte${reportes.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ), // ✅ REDUCIDO de 12
            ),
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: _animationDuration,
            child: Container(
              padding: EdgeInsets.all(6.r), // ✅ REDUCIDO de 7
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF667eea),
                size: 18.sp, // ✅ REDUCIDO de 20
              ),
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedYears[year] = expanded;
            });
          },
          children:
              reportes.map((reporte) {
                return _buildReportItem(
                  reporte: reporte,
                  themeManager: themeManager,
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required Reporte reporte,
    required ThemeManager themeManager,
  }) {
    return BounceTapButton(
      onTap: () => _openReport(reporte.file),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 3.h,
        ), // ✅ REDUCIDO de 11
        decoration: BoxDecoration(
          color:
              themeManager.isDarkMode
                  ? Colors.grey.shade900.withOpacity(0.3)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10.r), // ✅ REDUCIDO de 11
          border: Border.all(
            color:
                themeManager.isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade200,
            width: 1.w,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openReport(reporte.file),
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.all(12.r), // ✅ REDUCIDO de 14
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r), // ✅ REDUCIDO de 11
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf093fb), Color(0xFFF5576c)],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 20.sp, // ✅ REDUCIDO de 22
                    ),
                  ),
                  SizedBox(width: 12.w), // ✅ REDUCIDO de 14
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reporte.name,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp, // ✅ REDUCIDO de 14
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h), // ✅ REDUCIDO de 3
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12.sp, // ✅ REDUCIDO de 13
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 4.w), // ✅ REDUCIDO de 5
                            Text(
                              reporte.fechaCorte,
                              style: TextStyle(
                                fontSize: 11.sp, // ✅ REDUCIDO de 12
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(6.r), // ✅ REDUCIDO de 7
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: const Color(0xFF667eea),
                      size: 16.sp, // ✅ REDUCIDO de 18
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeManager themeManager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              themeManager.isDarkMode ? Colors.white : const Color(0xFF667eea),
            ),
            strokeWidth: 2.5.w, // ✅ REDUCIDO de 3
          ),
          SizedBox(height: 12.h), // ✅ REDUCIDO de 14
          Text(
            'Cargando reportes...',
            style: TextStyle(
              color:
                  themeManager.isDarkMode
                      ? Colors.white70
                      : Colors.grey.shade600,
              fontSize: 12.sp, // ✅ REDUCIDO de 13
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r), // ✅ REDUCIDO de 28
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 60.sp, // ✅ REDUCIDO de 70
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(height: 16.h), // ✅ REDUCIDO de 20
          Text(
            'Error al cargar reportes',
            style: GoogleFonts.lato(
              fontSize: 16.sp, // ✅ REDUCIDO de 18
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 5.h), // ✅ REDUCIDO de 6
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w), // ✅ REDUCIDO de 35
            child: Text(
              error.toString(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ), // ✅ REDUCIDO de 13
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final bgColor =
        themeManager.isDarkMode
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _isLoading
              ? _buildLoadingIndicator(themeManager)
              : StreamBuilder<List<Reporte>>(
                stream: _reportesStream,
                builder: (context, snapshot) {
                  // Si está en waiting y no hay datos, mostrar loading
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return _buildLoadingIndicator(themeManager);
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error);
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final reportes = snapshot.data!;
                  final reportesPorAno = _agruparReportesPorAno(reportes);

                  // Inicializar _expandedYears si es necesario
                  for (var ano in reportesPorAno.keys) {
                    _expandedYears.putIfAbsent(ano, () => false);
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      top: 12.h,
                      bottom:
                          12.h + MediaQuery.of(context).padding.bottom + 80.h,
                    ), // ✅ REDUCIDO de 14
                    itemCount: reportesPorAno.keys.length,
                    itemBuilder: (context, index) {
                      final year = reportesPorAno.keys.elementAt(index);
                      final reportesDelAno = reportesPorAno[year]!;

                      return _buildYearCard(
                        year: year,
                        reportes: reportesDelAno,
                        themeManager: themeManager,
                      );
                    },
                  );
                },
              ),
          // Indicador sutil de recarga (solo refresh manual)
          if (_isManualRefresh)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Container(
                      height: 3.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667eea).withOpacity(0.0),
                            const Color(0xFF667eea),
                            const Color(0xFF764ba2),
                            const Color(0xFF764ba2).withOpacity(0.0),
                          ],
                        ),
                      ),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
