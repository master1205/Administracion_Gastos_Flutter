import 'package:flutter/material.dart';
import 'package:notificaciones/api_service.dart';
import 'package:notificaciones/models/Reporte.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/date_symbol_data_local.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  ReportesScreenState createState() => ReportesScreenState();
}

class ReportesScreenState extends State<ReportesScreen>
    with WidgetsBindingObserver {
  late Future<List<Reporte>> _futureReportes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    // Asignamos un Future inicial para evitar que el FutureBuilder lea _futureReportes antes de tener un valor.
    _futureReportes = Future.value([]);

    // Inicializamos la localización y cargamos los reportes.
    initializeDateFormatting('es_ES', null).then((_) {
      setState(() {
        _futureReportes = ApiService().fetchReportes();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Maneja el estado de carga al reanudar la app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        isLoading = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration:
          !isDarkMode
              ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
              : null,
      child: Scaffold(
        backgroundColor:
            isDarkMode ? theme.scaffoldBackgroundColor : Colors.transparent,
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Reporte>>(
                  future: _futureReportes,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No hay reportes disponibles'),
                      );
                    } else {
                      final reportes = snapshot.data!;
                      final reportesPorAno = _agruparReportesPorAno(reportes);

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        itemCount: reportesPorAno.keys.length,
                        itemBuilder: (context, index) {
                          final ano = reportesPorAno.keys.elementAt(index);
                          final reportesDelAno = reportesPorAno[ano]!;

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ExpansionTile(
                              leading: const Icon(
                                Icons.folder,
                                color: Colors.blue,
                              ),
                              collapsedIconColor: Colors.blue,
                              iconColor: Colors.blue,
                              title: Text(
                                'Año $ano',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 18,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide.none,
                              ),
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide.none,
                              ),
                              children:
                                  reportesDelAno.map((reporte) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                          leading: const Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red,
                                          ),
                                          title: Text(
                                            reporte.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color,
                                            ),
                                          ),
                                          subtitle: Text(
                                            reporte.fechaCorte,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.remove_red_eye_outlined,
                                            size: 20,
                                          ),
                                          onTap: () async {
                                            final Uri url = Uri.parse(
                                              reporte.file,
                                            );
                                            await launchUrl(
                                              url,
                                              mode:
                                                  LaunchMode
                                                      .externalApplication,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
      ),
    );
  }

  Map<String, List<Reporte>> _agruparReportesPorAno(List<Reporte> reportes) {
    final Map<String, List<Reporte>> reportesPorAno = {};

    for (var reporte in reportes) {
      try {
        // Se asume que el año está al final de la cadena, por ejemplo: "Febrero 2025"
        final String ano = reporte.fechaCorte.split(' ').last;
        if (!reportesPorAno.containsKey(ano)) {
          reportesPorAno[ano] = [];
        }
        reportesPorAno[ano]!.add(reporte);
      } catch (e) {
        // Si ocurre un error, se reporta
        print('Error al extraer el año de la fecha: ${reporte.fechaCorte}');
      }
    }
    return reportesPorAno;
  }
}
