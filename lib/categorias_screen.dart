import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notificaciones/widgets/confirmation_dialog.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/animations.dart';
import 'componentes/heads_up_notification.dart';
import 'widgets/shimmer_loading.dart';
import 'crear_categoria_screen.dart';

class CategoriasScreen extends StatefulWidget {
  final Color? headerColor;

  const CategoriasScreen({super.key, this.headerColor});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filtroTipo = 'Todas'; // Todas, Gasto, Ingreso

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            size: 22.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Categorías',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todas', theme),
                  SizedBox(width: 8.w),
                  _buildFilterChip('Gasto', theme),
                  SizedBox(width: 8.w),
                  _buildFilterChip('Pago', theme),
                  SizedBox(width: 8.w),
                  _buildFilterChip('Ingreso', theme),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.obtenerCategorias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ShimmerList(
              shimmerItem: CategoriaCardShimmer(),
              itemCount: 4,
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final categorias = snapshot.data ?? [];

          // Aplicar filtro
          final categoriasFiltradas =
              _filtroTipo == 'Todas'
                  ? categorias
                  : categorias
                      .where((c) => c['tipoTransaccion'] == _filtroTipo)
                      .toList();

          if (categoriasFiltradas.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16.r,
              right: 16.r,
              top: 16.r,
              bottom: 16.r + MediaQuery.of(context).padding.bottom + 80.h,
            ),
            itemCount: categoriasFiltradas.length,
            itemBuilder: (context, index) {
              final categoria = categoriasFiltradas[index];
              return FadeIn(
                duration: Duration(milliseconds: 300 + (index * 50)),
                child: _buildCategoriaCard(categoria, isDark),
              );
            },
          );
        },
      ),
      floatingActionButton: AnimateFABDelayed(
        fab: FloatingActionButton(
          onPressed: () => _mostrarDialogoCategoria(context),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                color: theme.colorScheme.primary,
                size: 26.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final theme = Theme.of(context);
    return Center(
      child: SlideFadeTransition(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleIn(
                child: Container(
                  padding: EdgeInsets.all(28.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    size: 64.sp,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                'Sin categorías',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Crea tu primera categoría para\norganizar tus transacciones',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: theme.colorScheme.secondary.withOpacity(0.6),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriaCard(Map<String, dynamic> categoria, bool isDark) {
    final theme = Theme.of(context);
    final tipoTransaccion = categoria['tipoTransaccion'] ?? 'Gasto';
    final color = _getColorForTipo(tipoTransaccion);

    // Obtener el icono
    final iconCode = categoria['imagen'] ?? 'shopping_cart';
    final iconData = _getIconFromString(iconCode);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            // Icono
            Container(
              width: 54.w,
              height: 54.h,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(iconData, color: color, size: 26.sp),
            ),
            SizedBox(width: 14.w),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoria['categoria'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        tipoTransaccion,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: theme.colorScheme.secondary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Botones de acción
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap:
                      () => _mostrarDialogoCategoria(
                        context,
                        categoria: categoria,
                      ),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    child: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.secondary.withOpacity(0.6),
                      size: 20.sp,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                InkWell(
                  onTap: () => _confirmarEliminar(categoria),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: const Color(0xFFEF4444).withOpacity(0.7),
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForTipo(String tipo) {
    switch (tipo) {
      case 'Ingreso':
        return const Color(0xFF10B981);
      case 'Pago':
        return const Color(0xFFF59E0B);
      case 'Gasto':
      default:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getIconFromString(String iconString) {
    // Si es un número (codePoint), crear el icono directamente
    final codePoint = int.tryParse(iconString);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    // Fallback para iconos antiguos guardados como strings
    final iconMap = {
      // Compras
      'shopping_cart': Icons.shopping_cart,
      'shopping_bag': Icons.shopping_bag,
      'store': Icons.store,
      'local_mall': Icons.local_mall,
      'local_grocery_store': Icons.local_grocery_store,
      // Comida
      'restaurant': Icons.restaurant,
      'restaurant_outlined': Icons.restaurant_outlined,
      'fastfood': Icons.fastfood,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'local_pizza': Icons.local_pizza,
      'lunch_dining': Icons.lunch_dining,
      'dinner_dining': Icons.dinner_dining,
      'breakfast_dining': Icons.breakfast_dining,
      'cake': Icons.cake,
      'liquor': Icons.liquor,
      // Transporte
      'local_gas_station': Icons.local_gas_station,
      'propane_tank': Icons.propane_tank,
      'local_laundry_service': Icons.local_laundry_service,
      'emergency_outlined': Icons.emergency_outlined,
      'directions_car': Icons.directions_car,
      'directions_car_outlined': Icons.directions_car_outlined,
      'directions_bus': Icons.directions_bus,
      'train': Icons.train,
      'flight': Icons.flight,
      'two_wheeler': Icons.two_wheeler,
      'local_taxi': Icons.local_taxi,
      'directions_bike': Icons.directions_bike,
      'directions_subway': Icons.directions_subway,
      'airport_shuttle': Icons.airport_shuttle,
      // Hogar
      'home': Icons.home,
      'home_outlined': Icons.home_outlined,
      'house': Icons.house,
      'house_outlined': Icons.house_outlined,
      'apartment': Icons.apartment,
      'bed': Icons.bed,
      'weekend': Icons.weekend,
      'chair': Icons.chair,
      'roofing': Icons.roofing,
      // Servicios
      'electric_bolt': Icons.electric_bolt,
      'electrical_services_outlined': Icons.electrical_services_outlined,
      'water_drop': Icons.water_drop,
      'water_drop_outlined': Icons.water_drop_outlined,
      'wifi': Icons.wifi,
      'wifi_outlined': Icons.wifi_outlined,
      'phone_android': Icons.phone_android,
      'phone': Icons.phone,
      'phone_outlined': Icons.phone_outlined,
      'tv': Icons.tv,
      'tv_outlined': Icons.tv_outlined,
      'router': Icons.router,
      'cable': Icons.cable,
      'power': Icons.power,
      // Salud
      'medical_services': Icons.medical_services,
      'medical_services_outlined': Icons.medical_services_outlined,
      'local_hospital': Icons.local_hospital,
      'local_pharmacy': Icons.local_pharmacy,
      'healing': Icons.healing,
      'favorite': Icons.favorite,
      'psychology': Icons.psychology,
      'spa': Icons.spa,
      'clean_hands': Icons.clean_hands,
      'medication': Icons.medication,
      'vaccines': Icons.vaccines,
      // Educación
      'school': Icons.school,
      'school_outlined': Icons.school_outlined,
      'menu_book': Icons.menu_book,
      'library_books': Icons.library_books,
      'auto_stories': Icons.auto_stories,
      'science': Icons.science,
      'calculate': Icons.calculate,
      'edit_note': Icons.edit_note,
      // Entretenimiento
      'movie': Icons.movie,
      'movie_outlined': Icons.movie_outlined,
      'theaters': Icons.theaters,
      'live_tv': Icons.live_tv,
      'music_note': Icons.music_note,
      'headphones': Icons.headphones,
      'videogame_asset': Icons.videogame_asset,
      'casino': Icons.casino,
      'casino_outlined': Icons.casino_outlined,
      'celebration': Icons.celebration,
      'festival': Icons.festival,
      // Ropa y accesorios
      'checkroom_outlined': Icons.checkroom_outlined,
      // Deportes
      'sports': Icons.sports,
      'sports_soccer': Icons.sports_soccer,
      'sports_basketball': Icons.sports_basketball,
      'sports_tennis': Icons.sports_tennis,
      'sports_baseball': Icons.sports_baseball,
      'sports_football': Icons.sports_football,
      'fitness_center': Icons.fitness_center,
      'pool': Icons.pool,
      'surfing': Icons.surfing,
      'snowboarding': Icons.snowboarding,
      'sailing': Icons.sailing,
      // Finanzas
      'attach_money': Icons.attach_money,
      'attach_money_outlined': Icons.attach_money_outlined,
      'monetization_on_outlined': Icons.monetization_on_outlined,
      'savings': Icons.savings,
      'account_balance': Icons.account_balance,
      'credit_card': Icons.credit_card,
      'payment': Icons.payment,
      'currency_exchange': Icons.currency_exchange,
      'paid': Icons.paid,
      'money': Icons.money,
      'account_balance_wallet': Icons.account_balance_wallet,
      'trending_up_outlined': Icons.trending_up_outlined,
      'sell_outlined': Icons.sell_outlined,
      'workspace_premium_outlined': Icons.workspace_premium_outlined,
      'real_estate_outlined': Icons.real_estate_agent_outlined,
      'location_city_outlined': Icons.location_city_outlined,
      'security_outlined': Icons.security_outlined,
      'receipt_long_outlined': Icons.receipt_long_outlined,
      // Trabajo
      'work': Icons.work,
      'work_outlined': Icons.work_outlined,
      'business': Icons.business,
      'business_outlined': Icons.business_outlined,
      'business_center': Icons.business_center,
      'badge': Icons.badge,
      'engineering': Icons.engineering,
      'construction': Icons.construction,
      'precision_manufacturing': Icons.precision_manufacturing,
      'agriculture': Icons.agriculture,
      'handyman': Icons.handyman,
      'handyman_outlined': Icons.handyman_outlined,
      // Regalos
      'card_giftcard': Icons.card_giftcard,
      'card_giftcard_outlined': Icons.card_giftcard_outlined,
      'redeem': Icons.redeem,
      'redeem_outlined': Icons.redeem_outlined,
      'volunteer_activism': Icons.volunteer_activism,
      'emoji_events': Icons.emoji_events,
      // Tecnología
      'computer': Icons.computer,
      'laptop': Icons.laptop,
      'tablet': Icons.tablet,
      'watch': Icons.watch,
      'headset': Icons.headset,
      'keyboard': Icons.keyboard,
      'mouse': Icons.mouse,
      'print': Icons.print,
      // Mascotas
      'pets': Icons.pets,
      'pets_outlined': Icons.pets_outlined,
      'cruelty_free': Icons.cruelty_free,
      // Familia
      'child_care': Icons.child_care,
      'baby_changing_station': Icons.baby_changing_station,
      'face': Icons.face,
      'elderly': Icons.elderly,
      'elderly_outlined': Icons.elderly_outlined,
      'people': Icons.people,
      'groups': Icons.groups,
      'family_restroom': Icons.family_restroom,
      // Viajes
      'airplanemode_active_outlined': Icons.airplanemode_active_outlined,
      'airplane_ticket': Icons.airplane_ticket,
      'luggage': Icons.luggage,
      'hotel': Icons.hotel,
      'beach_access': Icons.beach_access,
      'place': Icons.place,
      'map': Icons.map,
      'explore': Icons.explore,
      'tour': Icons.tour,
      // Otros
      'category': Icons.category,
      'more_horiz': Icons.more_horiz,
      'star': Icons.star,
      'bolt': Icons.bolt,
      'local_fire_department': Icons.local_fire_department,
      'eco': Icons.eco,
      'recycling': Icons.recycling,
      'brush': Icons.brush,
      'palette': Icons.palette,
      'photo_camera': Icons.photo_camera,
      'notifications': Icons.notifications,
      'alarm': Icons.alarm,
    };

    return iconMap[iconString] ?? Icons.category;
  }

  Future<void> _mostrarDialogoCategoria(
    BuildContext context, {
    Map<String, dynamic>? categoria,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearCategoriaScreen(categoria: categoria),
      ),
    );
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> categoria) async {
    // Verificar si está en uso
    final enUso = await _firestoreService.categoriaEnUso(
      categoria['categoria'],
    );

    if (enUso) {
      if (!mounted) return;
      showErrorNotification(
        context,
        message: 'No se puede eliminar',
        subtitle: 'La categoría está en uso',
      );
      return;
    }

    if (!mounted) return;

    final confirmar = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar categoría?',
      message:
          '¿Estás seguro de eliminar "${categoria['categoria']}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      confirmColor: Colors.red.shade400,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmar == true) {
      try {
        await _firestoreService.eliminarCategoria(categoria['id']);
        if (mounted) {
          showSuccessNotification(context, message: 'Categoría eliminada');
        }
      } catch (e) {
        if (mounted) {
          showErrorNotification(
            context,
            message: 'Error al eliminar',
            subtitle: e.toString(),
          );
        }
      }
    }
  }

  Widget _buildFilterChip(String label, ThemeData theme) {
    final isSelected = _filtroTipo == label;
    final color = _getColorForLabel(label);

    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroTipo = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withOpacity(0.12) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected
                    ? color.withOpacity(0.3)
                    : theme.colorScheme.secondary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6.w,
                height: 6.h,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected
                        ? color
                        : theme.colorScheme.secondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLabel(String label) {
    switch (label) {
      case 'Ingreso':
        return const Color(0xFF10B981);
      case 'Pago':
        return const Color(0xFFF59E0B);
      case 'Gasto':
        return const Color(0xFFEF4444);
      case 'Todas':
      default:
        return const Color(0xFF8B5CF6);
    }
  }
}
