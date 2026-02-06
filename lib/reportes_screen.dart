import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notificaciones/models/Reporte.dart';
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
    required ThemeData theme,
  }) {
    final isExpanded = _expandedYears[year] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.25),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('expansion_$year'),
          initiallyExpanded: isExpanded,
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          childrenPadding: EdgeInsets.only(bottom: 8.h),
          leading: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.folder_rounded,
              color: theme.colorScheme.primary,
              size: 20.sp,
            ),
          ),
          title: Text(
            'Año $year',
            style: GoogleFonts.lato(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              '${reportes.length} reporte${reportes.length != 1 ? 's' : ''}',
              style: GoogleFonts.openSans(
                fontSize: 11.sp,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
            ),
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: _animationDuration,
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.secondary,
                size: 18.sp,
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
                return _buildReportItem(reporte: reporte, theme: theme);
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required Reporte reporte,
    required ThemeData theme,
  }) {
    return BounceTapButton(
      onTap: () => _openReport(reporte.file),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openReport(reporte.file),
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.red.shade600,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reporte.name,
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12.sp,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.7,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              reporte.fechaCorte,
                              style: GoogleFonts.openSans(
                                fontSize: 11.sp,
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.secondary,
                      size: 16.sp,
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

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
            strokeWidth: 2.5.w,
          ),
          SizedBox(height: 12.h),
          Text(
            'Cargando reportes...',
            style: GoogleFonts.openSans(
              color: theme.colorScheme.secondary,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 60.sp,
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Error al cargar reportes',
            style: GoogleFonts.lato(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          SizedBox(height: 5.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              error.toString(),
              style: GoogleFonts.openSans(
                fontSize: 12.sp,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          _isLoading
              ? _buildLoadingIndicator(theme)
              : StreamBuilder<List<Reporte>>(
                stream: _reportesStream,
                builder: (context, snapshot) {
                  // Si está en waiting y no hay datos, mostrar loading
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return _buildLoadingIndicator(theme);
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
                          32.h + MediaQuery.of(context).padding.bottom,
                    ), // ✅ REDUCIDO de 14
                    itemCount: reportesPorAno.keys.length,
                    itemBuilder: (context, index) {
                      final year = reportesPorAno.keys.elementAt(index);
                      final reportesDelAno = reportesPorAno[year]!;

                      return _buildYearCard(
                        year: year,
                        reportes: reportesDelAno,
                        theme: theme,
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
                  final theme = Theme.of(context);
                  return Opacity(
                    opacity: value,
                    child: Container(
                      height: 3.h,
                      child: LinearProgressIndicator(
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
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
