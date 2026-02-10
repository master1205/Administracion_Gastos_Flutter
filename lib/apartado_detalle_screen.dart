import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'models/Apartado.dart';
import 'models/Account.dart';
import 'data_provider.dart';
import 'services/firestore_service.dart';
import 'widgets/animated_goo_background.dart';
import 'widgets/budget_widgets.dart';
import 'widgets/animations.dart';
import 'widgets/select_amount.dart';
import 'widgets/confirmation_dialog.dart';
import 'componentes/heads_up_notification.dart';
import 'crear_apartado_screen.dart';

/// URL del Web App de Google Apps Script para enviar push notifications.
/// Actualizar después de cada nuevo deploy del script.
const String _gasWebAppUrl =
    'https://script.google.com/macros/s/AKfycbyZnjDeqvBlXNWhy6Ww3lzEt6lqXWIa4GAcDmVSXuQwp4Gvt03EXnvyDQVIrT0_Yj3p/exec';

class ApartadoDetalleScreen extends StatefulWidget {
  final Apartado apartado;

  const ApartadoDetalleScreen({Key? key, required this.apartado})
    : super(key: key);

  @override
  State<ApartadoDetalleScreen> createState() => _ApartadoDetalleScreenState();
}

class _ApartadoDetalleScreenState extends State<ApartadoDetalleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  late Apartado _apartado;
  List<Abono> _abonos = [];
  bool _isLoading = true;
  StreamSubscription<List<Abono>>? _abonosSubscription;
  StreamSubscription? _apartadoSubscription;

  /// Envía push a todos los dispositivos via GAS Web App.
  /// Fire & forget: no bloquea la UI.
  void _enviarPushCompletado(Apartado apartado) {
    http
        .post(
          Uri.parse(_gasWebAppUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'titulo': '🎉 ¡Apartado completado!',
            'mensaje':
                '"${apartado.nombre}" alcanzó el 100%. Ya puedes registrar el pago.',
            'data': {
              'screen': 'apartados',
              'apartadoId': apartado.id,
              'tipo': 'apartado_completado',
              'timestamp': DateTime.now().toIso8601String(),
            },
          }),
        )
        .catchError(
          (_) => http.Response('', 500),
        ); // Silenciar errores: el push es complementario
  }

  @override
  void initState() {
    super.initState();
    _apartado = widget.apartado;
    initializeDateFormatting('es_ES', null);
    _cargarDatos();
  }

  @override
  void dispose() {
    _abonosSubscription?.cancel();
    _apartadoSubscription?.cancel();
    super.dispose();
  }

  void _cargarDatos() {
    // Escuchar cambios del apartado en tiempo real
    _apartadoSubscription = _firestoreService.obtenerApartados().listen((
      apartados,
    ) {
      try {
        final actualizado = apartados.firstWhere((a) => a.id == _apartado.id);
        if (mounted) {
          setState(() => _apartado = actualizado);
        }
      } catch (_) {
        // El apartado fue eliminado
      }
    });

    // Escuchar abonos
    _abonosSubscription = _firestoreService.obtenerAbonos(_apartado.id).listen((
      abonos,
    ) {
      if (mounted) {
        setState(() {
          _abonos = abonos;
          _isLoading = false;
        });
      }
    });
  }

  Color get _baseColor {
    try {
      final colorHex = int.parse('FF${_apartado.color}', radix: 16);
      return Color(colorHex);
    } catch (_) {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Color get _statusColor {
    if (_apartado.estado == 'completado') return const Color(0xFF66BB6A);
    if (_apartado.estado == 'pagado') return Colors.grey;
    if (_apartado.estaVencido) return const Color(0xFFEF5350);
    return _baseColor;
  }

  IconData _getIconData(String iconName) {
    final codePoint = int.tryParse(iconName);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return Icons.account_balance_wallet_rounded;
  }

  Future<void> _registrarAbono() async {
    final montoSugerido = _apartado.montoPorPago;

    final monto = await showSelectAmountBottomSheet(
      context,
      title: 'Registrar abono',
      initialAmount: montoSugerido,
      allowZero: false,
      currencySymbol: '\$',
    );

    if (monto == null || monto <= 0) return;

    // Verificar saldo disponible en la cuenta
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    Account? cuenta;
    try {
      cuenta = dataProvider.cuentas.firstWhere(
        (a) => a.id == _apartado.cuentaId,
      );
    } catch (_) {}

    if (cuenta != null && cuenta.saldoDisponible < monto) {
      showErrorNotification(
        context,
        message: 'Fondos insuficientes',
        subtitle:
            'Disponible: ${_currencyFormat.format(cuenta.saldoDisponible)}, '
            'abono: ${_currencyFormat.format(monto)}',
      );
      return;
    }

    try {
      // Guardar montos previos para detectar cambios
      final montoAnterior = _apartado.montoApartado;
      final montoPorPagoAnterior = _apartado.montoPorPago;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await _firestoreService.registrarAbono(
        apartadoId: _apartado.id,
        monto: monto,
        numeroAbono: _apartado.pagosRealizados + 1,
        nota: 'Abono #${_apartado.pagosRealizados + 1}',
      );

      if (mounted) Navigator.pop(context);

      // Verificar si el apartado se completó con este abono
      final nuevoMonto = montoAnterior + monto;
      final seCompleto = nuevoMonto >= _apartado.montoTotal;

      if (seCompleto) {
        // Push a todos los dispositivos (fire & forget, no await)
        _enviarPushCompletado(_apartado);
      } else {
        // Verificar si el montoPorPago cambió (redistribución)
        final pagosRestantesNuevo =
            _apartado.numeroPagos - (_apartado.pagosRealizados + 1);
        if (pagosRestantesNuevo > 0) {
          final nuevoMontoPorPago =
              (_apartado.montoTotal - nuevoMonto) / pagosRestantesNuevo;
          final diferencia = (nuevoMontoPorPago - montoPorPagoAnterior).abs();
          if (diferencia > 0.01 && monto != montoPorPagoAnterior) {
            if (mounted) {
              showSuccessNotification(
                context,
                message: 'Monto por abono ajustado',
                subtitle:
                    'Nuevo monto: ${_currencyFormat.format(nuevoMontoPorPago)} '
                    '(antes ${_currencyFormat.format(montoPorPagoAnterior)})',
              );
            }
            // Esperar un momento antes de mostrar otra notificación
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (mounted) {
        showSuccessNotification(
          context,
          message:
              seCompleto ? '¡Último abono registrado!' : 'Abono registrado',
          subtitle: _currencyFormat.format(monto),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showErrorNotification(
          context,
          message: 'Error al registrar abono',
          subtitle: e.toString(),
        );
      }
    }
  }

  Future<void> _confirmarPago() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    // Buscar la cuenta asociada
    Account? cuenta;
    try {
      cuenta = dataProvider.cuentas.firstWhere(
        (a) => a.id == _apartado.cuentaId,
      );
    } catch (_) {
      if (dataProvider.cuentas.isNotEmpty) {
        cuenta = dataProvider.cuentas.first;
      }
    }

    if (cuenta == null) {
      showErrorNotification(
        context,
        message: 'No se encontró la cuenta asociada',
      );
      return;
    }

    final cuentaSeleccionada = cuenta;

    // Verificar fondos suficientes (usar saldo real, no disponible,
    // porque el monto retenido del propio apartado ya está incluido)
    if (cuentaSeleccionada.saldo < _apartado.montoTotal) {
      showErrorNotification(
        context,
        message: 'Fondos insuficientes',
        subtitle:
            'La cuenta "${cuentaSeleccionada.nombre}" tiene ${_currencyFormat.format(cuentaSeleccionada.saldo)} '
            'y se necesitan ${_currencyFormat.format(_apartado.montoTotal)}',
      );
      return;
    }

    final mensajeRecurrente =
        _apartado.esRecurrente
            ? '\n\nComo es recurrente, se creará un nuevo apartado automáticamente.'
            : '';

    final confirmed = await showConfirmationDialog(
      context: context,
      title: '¿Ya realizaste este pago?',
      message:
          'Se registrará un pago por ${_currencyFormat.format(_apartado.montoTotal)} '
          'en la categoría "${_apartado.categoria}" desde la cuenta "${cuentaSeleccionada.nombre}".$mensajeRecurrente',
      confirmText: 'Sí, registrar pago',
      icon: Icons.check_circle_rounded,
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await _firestoreService
          .marcarApartadoComoPagado(
            apartado: _apartado,
            cuenta: cuentaSeleccionada,
          )
          .then((apartadoPropuesto) async {
            if (mounted) Navigator.pop(context); // dismiss loading

            if (apartadoPropuesto != null && mounted) {
              // Mostrar diálogo de confirmación de fechas
              final apartadoFinal = await _mostrarDialogoFechasRecurrente(
                apartadoPropuesto,
              );

              if (apartadoFinal != null) {
                await _firestoreService.crearApartado(apartadoFinal);
                if (mounted) {
                  showSuccessNotification(
                    context,
                    message: 'Pago registrado',
                    subtitle:
                        '${_currencyFormat.format(_apartado.montoTotal)} desde ${cuentaSeleccionada.nombre} — nuevo apartado creado',
                  );
                }
              } else {
                if (mounted) {
                  showSuccessNotification(
                    context,
                    message: 'Pago registrado',
                    subtitle:
                        '${_currencyFormat.format(_apartado.montoTotal)} desde ${cuentaSeleccionada.nombre} — apartado recurrente cancelado',
                  );
                }
              }
            } else {
              if (mounted) {
                showSuccessNotification(
                  context,
                  message: 'Pago registrado',
                  subtitle:
                      '${_currencyFormat.format(_apartado.montoTotal)} desde ${cuentaSeleccionada.nombre}',
                );
              }
            }
          });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showErrorNotification(
          context,
          message: 'Error al registrar el pago',
          subtitle: e.toString(),
        );
      }
    }
  }

  /// Muestra un diálogo con las fechas propuestas para el nuevo apartado
  /// recurrente. Permite editarlas antes de confirmar.
  Future<Apartado?> _mostrarDialogoFechasRecurrente(Apartado propuesto) async {
    final fechasEditables = List<DateTime>.from(propuesto.fechasPago);
    final theme = Theme.of(context);
    final color = Color(int.parse('FF${propuesto.color}', radix: 16));

    return await showDialog<Apartado?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Row(
                children: [
                  Icon(Icons.event_repeat_rounded, color: color, size: 24.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Nuevo ciclo de pagos',
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Se creará un nuevo "${propuesto.nombre}" con estas fechas de pago:',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      constraints: BoxConstraints(maxHeight: 250.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: fechasEditables.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              height: 1,
                              indent: 40.w,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.08,
                              ),
                            ),
                        itemBuilder: (context, index) {
                          final fecha = fechasEditables[index];
                          return InkWell(
                            onTap: () async {
                              final nueva = await showDatePicker(
                                context: context,
                                initialDate: fecha,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                                builder: (ctx, child) {
                                  return Theme(
                                    data: Theme.of(ctx).copyWith(
                                      dialogBackgroundColor:
                                          theme.colorScheme.surface,
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (nueva != null) {
                                setDialogState(() {
                                  fechasEditables[index] = DateTime(
                                    nueva.year,
                                    nueva.month,
                                    nueva.day,
                                  );
                                  fechasEditables.sort(
                                    (a, b) => a.compareTo(b),
                                  );
                                });
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26.w,
                                    height: 26.h,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(7.r),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.lato(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      DateFormat(
                                        "EEEE d 'de' MMMM, yyyy",
                                        'es',
                                      ).format(fecha),
                                      style: GoogleFonts.lato(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 16.sp,
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Toca una fecha para editarla',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: Text(
                    'No crear',
                    style: GoogleFonts.lato(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final actualizado = propuesto.copyWith(
                      fechasPago: fechasEditables,
                      fechaProximoPago:
                          fechasEditables.isNotEmpty
                              ? fechasEditables.first
                              : null,
                    );
                    Navigator.pop(dialogContext, actualizado);
                  },
                  icon: Icon(Icons.check_rounded, size: 18.sp),
                  label: Text(
                    'Crear apartado',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _eliminarApartado() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar apartado?',
      message: 'Se eliminará "${_apartado.nombre}" y todos sus abonos.',
      confirmText: 'Eliminar',
      confirmColor: Colors.red,
      icon: Icons.delete_rounded,
    );

    if (confirmed != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await _firestoreService.eliminarApartado(_apartado.id);

      if (mounted) Navigator.pop(context); // dialog
      if (mounted) Navigator.pop(context); // screen

      if (mounted) {
        showSuccessNotification(
          context,
          message: 'Apartado eliminado',
          subtitle: _apartado.nombre,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showErrorNotification(
          context,
          message: 'Error al eliminar',
          subtitle: e.toString(),
        );
      }
    }
  }

  void _editarApartado() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearApartadoScreen(apartado: _apartado),
      ),
    );
    if (result == true && mounted) {
      showSuccessNotification(
        context,
        message: 'Apartado actualizado',
        subtitle: _apartado.nombre,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(child: _buildSummarySection(theme)),
          SliverToBoxAdapter(child: _buildPaymentPlanSection(theme)),
          if (_apartado.fechasPago.isNotEmpty)
            SliverToBoxAdapter(child: _buildFechasPagoSection(theme)),
          if (_apartado.estado == 'activo')
            SliverToBoxAdapter(child: _buildNotificacionesToggle(theme)),
          if (_apartado.estado == 'completado')
            SliverToBoxAdapter(child: _buildConfirmPaymentCard(theme)),
          if (_apartado.descripcion.isNotEmpty)
            SliverToBoxAdapter(child: _buildDescriptionSection(theme)),
          SliverToBoxAdapter(child: _buildAbonosHeader(theme)),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40.r),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (_abonos.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyAbonos(theme))
          else
            _buildAbonosList(theme),
          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
      ),
      floatingActionButton:
          _apartado.estado == 'activo' ? _buildFAB(theme) : null,
    );
  }

  // ── FAB: Registrar abono ──
  Widget _buildFAB(ThemeData theme) {
    return Container(
      height: 50.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_baseColor, _baseColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: _baseColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25.r),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _registrarAbono,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 22.sp),
                SizedBox(width: 8.w),
                Text(
                  'Registrar Abono',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SliverAppBar con AnimatedGoo ──
  Widget _buildSliverAppBar(ThemeData theme) {
    final expandedH = 240.h;
    final statusBar = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: expandedH,
      pinned: true,
      stretch: true,
      backgroundColor: _baseColor,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_apartado.estado == 'activo' || _apartado.estado == 'completado')
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
            onPressed: _editarApartado,
          ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
          ),
          onPressed: _eliminarApartado,
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final maxExtent = expandedH + statusBar;
          final minExtent = kToolbarHeight + statusBar;
          final t = ((maxExtent - constraints.maxHeight) /
                  (maxExtent - minExtent))
              .clamp(0.0, 1.0);
          final contentOpacity = (1.0 - t * 2.0).clamp(0.0, 1.0);

          final titleFontSize = 22.0 - 6.0 * t;
          final expandedY = maxExtent - 165.h;
          final collapsedY = statusBar + kToolbarHeight / 2;
          final titleCenterY = expandedY + (collapsedY - expandedY) * t;
          final titleLeft = 76.w + (56.w - 76.w) * t;
          final titleRight = 20.w + (56.w - 20.w) * t;

          return Stack(
            children: [
              // Fondo animado
              Positioned.fill(
                child: ClipRect(
                  child: AnimatedGooBackground(
                    color:
                        _apartado.estado == 'pagado' ? Colors.grey : _baseColor,
                    randomOffset: _apartado.nombre.length,
                    enableAnimation: true,
                  ),
                ),
              ),
              // Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.35),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Contenido expandido
              Positioned.fill(
                child: Opacity(
                  opacity: contentOpacity,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 90.h, 20.w, 20.h),
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomLeft,
                        maxHeight: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Icon(
                                    _getIconData(_apartado.icono),
                                    size: 24.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 30.h),
                                      Text(
                                        _getSubtitleText(),
                                        style: GoogleFonts.lato(
                                          fontSize: 13.sp,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            BudgetProgressBar(
                              progreso: _apartado.progreso,
                              color: _statusColor,
                              height: 14.h,
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Text(
                                  '${_apartado.progreso.toStringAsFixed(1)}%',
                                  style: GoogleFonts.lato(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const Spacer(),
                                _buildStatusBadge(),
                                if (_apartado.esRecurrente) ...[
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.repeat_rounded,
                                          size: 12.sp,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Recurrente',
                                          style: GoogleFonts.lato(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Text(
                                  _apartado.diasRestantes > 0
                                      ? '${_apartado.diasRestantes} días'
                                      : 'Plazo vencido',
                                  style: GoogleFonts.lato(
                                    fontSize: 12.sp,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Título deslizante
              Positioned(
                top: titleCenterY - titleFontSize.sp * 0.6,
                left: titleLeft,
                right: titleRight,
                child: Align(
                  alignment:
                      Alignment.lerp(
                        Alignment.centerLeft,
                        Alignment.center,
                        t,
                      )!,
                  child: Text(
                    _apartado.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getSubtitleText() {
    if (_apartado.estado == 'pagado') return '¡Pago realizado!';
    if (_apartado.estado == 'completado') return '¡Monto completado!';
    if (_apartado.estaVencido) return 'Apartado vencido';
    return 'Faltan ${_currencyFormat.format(_apartado.montoRestante)}';
  }

  Widget _buildStatusBadge() {
    String label;
    if (_apartado.estado == 'pagado') {
      label = '✓ Pagado';
    } else if (_apartado.estado == 'completado') {
      label = '✓ Completado';
    } else if (_apartado.estaVencido) {
      label = '⚠ Vencido';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Resumen ──
  Widget _buildSummarySection(ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn(
                label: 'Apartado',
                amount: _apartado.montoApartado,
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  '${_apartado.progreso.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ),
              _buildAmountColumn(
                label: 'Total',
                amount: _apartado.montoTotal,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                theme: theme,
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Restante',
                  value: _currencyFormat.format(_apartado.montoRestante),
                  color:
                      _apartado.estaCompleto
                          ? Colors.green
                          : theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Días restantes',
                  value: '${_apartado.diasRestantes}',
                  color:
                      _apartado.diasRestantes <= 7 && !_apartado.estaCompleto
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.category_rounded,
                  label: 'Categoría',
                  value: _apartado.categoria,
                  color: theme.colorScheme.secondary,
                  theme: theme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.account_balance_rounded,
                  label: 'Cuenta',
                  value: _apartado.cuentaNombre ?? 'Sin cuenta',
                  color: theme.colorScheme.tertiary,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Plan de pagos ──
  Widget _buildPaymentPlanSection(ThemeData theme) {
    final frecuenciaLabel =
        {
          'semanal': 'Semanal',
          'quincenal': 'Quincenal',
          'mensual': 'Mensual',
        }[_apartado.frecuencia] ??
        _apartado.frecuencia;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: _baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: _baseColor,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Plan de pagos',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildPlanChip(
                  label: 'Abonos',
                  value:
                      '${_apartado.pagosRealizados}/${_apartado.numeroPagos}',
                  icon: Icons.payments_rounded,
                  theme: theme,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildPlanChip(
                  label: 'Frecuencia',
                  value: frecuenciaLabel,
                  icon: Icons.schedule_rounded,
                  theme: theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildPlanChip(
                  label: 'Próximo abono',
                  value:
                      _apartado.estado == 'activo' &&
                              _apartado.pagosRestantes > 0
                          ? _currencyFormat.format(_apartado.montoPorPago)
                          : 'N/A',
                  icon: Icons.attach_money_rounded,
                  theme: theme,
                  highlight: _apartado.estado == 'activo',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildPlanChip(
                  label: 'Fecha límite',
                  value: DateFormat(
                    'dd MMM yyyy',
                    'es',
                  ).format(_apartado.fechaLimite),
                  icon: Icons.flag_rounded,
                  theme: theme,
                ),
              ),
            ],
          ),
          if (_apartado.fechaProximoPago != null &&
              _apartado.estado == 'activo') ...[
            SizedBox(height: 8.h),
            _buildPlanChip(
              label: 'Próximo pago programado',
              value: DateFormat(
                'dd \'de\' MMMM \'de\' yyyy',
                'es',
              ).format(_apartado.fechaProximoPago!),
              icon: Icons.event_rounded,
              theme: theme,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }

  // ── Fechas de pago programadas ──
  Widget _buildFechasPagoSection(ThemeData theme) {
    final ahora = DateTime.now();
    final fechasOrdenadas = List<DateTime>.from(_apartado.fechasPago)
      ..sort((a, b) => a.compareTo(b));

    // Determinar cuál es la próxima fecha (la primera futura o de hoy)
    DateTime? proximaFecha;
    for (final f in fechasOrdenadas) {
      if (f.isAfter(ahora) || _esMismoDiaLocal(f, ahora)) {
        proximaFecha = f;
        break;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: _baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.date_range_rounded,
                  color: _baseColor,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Fechas de pago',
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${fechasOrdenadas.length} fecha${fechasOrdenadas.length != 1 ? 's' : ''}',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _baseColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...fechasOrdenadas.map((fecha) {
            final esPasada =
                fecha.isBefore(ahora) && !_esMismoDiaLocal(fecha, ahora);
            final esProxima =
                proximaFecha != null && _esMismoDiaLocal(fecha, proximaFecha);
            final esHoy = _esMismoDiaLocal(fecha, ahora);

            return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color:
                          esPasada
                              ? Colors.green.withOpacity(0.15)
                              : esProxima
                              ? _baseColor.withOpacity(0.15)
                              : theme.colorScheme.onSurface.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      esPasada
                          ? Icons.check_rounded
                          : esHoy
                          ? Icons.today_rounded
                          : Icons.circle_outlined,
                      size: 14.sp,
                      color:
                          esPasada
                              ? Colors.green
                              : esProxima
                              ? _baseColor
                              : theme.colorScheme.onSurface.withOpacity(0.35),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE d \'de\' MMMM yyyy', 'es').format(fecha),
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight:
                            esProxima ? FontWeight.w700 : FontWeight.w400,
                        color:
                            esPasada
                                ? theme.colorScheme.onSurface.withOpacity(0.4)
                                : esProxima
                                ? _baseColor
                                : theme.colorScheme.onSurface.withOpacity(0.75),
                        decoration:
                            esPasada ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (esHoy)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _baseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Hoy',
                        style: GoogleFonts.lato(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: _baseColor,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _esMismoDiaLocal(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ── Toggle notificaciones ──
  Widget _buildNotificacionesToggle(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: _cardDecoration(theme),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: (_apartado.notificacionesActivas
                      ? _baseColor
                      : theme.colorScheme.onSurface.withOpacity(0.3))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _apartado.notificacionesActivas
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color:
                  _apartado.notificacionesActivas
                      ? _baseColor
                      : theme.colorScheme.onSurface.withOpacity(0.35),
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones',
                  style: GoogleFonts.lato(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _apartado.notificacionesActivas
                      ? 'Recordatorios de pago activados'
                      : 'Sin recordatorios',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _apartado.notificacionesActivas,
            activeColor: _baseColor,
            onChanged: (value) async {
              final updated = _apartado.copyWith(notificacionesActivas: value);
              await _firestoreService.actualizarApartado(updated);
              if (mounted) {
                showSuccessNotification(
                  context,
                  message:
                      value
                          ? 'Notificaciones activadas'
                          : 'Notificaciones desactivadas',
                  subtitle: _apartado.nombre,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Confirmar pago (cuando está completado) ──
  Widget _buildConfirmPaymentCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF66BB6A).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF66BB6A).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 40.sp,
              color: const Color(0xFF66BB6A),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '¡Monto completado!',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Ya apartaste ${_currencyFormat.format(_apartado.montoTotal)}.\n¿Ya realizaste el pago?',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmarPago,
              icon: Icon(Icons.receipt_long_rounded, size: 20.sp),
              label: Text(
                'Registrar como pago',
                style: GoogleFonts.lato(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Descripción ──
  Widget _buildDescriptionSection(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(theme),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_rounded,
            size: 20.sp,
            color: theme.colorScheme.secondary.withOpacity(0.6),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _apartado.descripcion,
              style: GoogleFonts.lato(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Abonos header ──
  Widget _buildAbonosHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: _baseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.history_rounded, size: 18.sp, color: _baseColor),
          ),
          SizedBox(width: 10.w),
          Text(
            'Historial de abonos',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${_abonos.length}',
              style: GoogleFonts.lato(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty abonos ──
  Widget _buildEmptyAbonos(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Icon(
            Icons.payments_outlined,
            size: 48.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          SizedBox(height: 12.h),
          Text(
            'Sin abonos registrados',
            style: GoogleFonts.lato(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          if (_apartado.estado == 'activo') ...[
            SizedBox(height: 8.h),
            Text(
              'Toca el botón para registrar tu primer abono',
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Lista de abonos ──
  SliverList _buildAbonosList(ThemeData theme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final abono = _abonos[index];
        return FadeIn(
          duration: Duration(milliseconds: 200 + (index * 50)),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: _baseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      '#${abono.numeroAbono}',
                      style: GoogleFonts.lato(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: _baseColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abono #${abono.numeroAbono}',
                        style: GoogleFonts.lato(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm',
                          'es',
                        ).format(abono.fechaAbono),
                        style: GoogleFonts.lato(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (abono.nota != null && abono.nota!.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          abono.nota!,
                          style: GoogleFonts.lato(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  _currencyFormat.format(abono.monto),
                  style: GoogleFonts.lato(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF66BB6A),
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: _abonos.length),
    );
  }

  // ── Helpers ──

  Widget _buildPlanChip({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
    bool highlight = false,
  }) {
    final color = highlight ? _baseColor : theme.colorScheme.onSurface;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color:
            highlight
                ? _baseColor.withOpacity(0.06)
                : theme.colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10.r),
        border:
            highlight ? Border.all(color: _baseColor.withOpacity(0.15)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.sp, color: color.withOpacity(0.6)),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: color.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: highlight ? _baseColor : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn({
    required String label,
    required double amount,
    required Color color,
    required ThemeData theme,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _currencyFormat.format(amount),
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
