import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notificaciones/services/firestore_service.dart';
import 'package:notificaciones/theme_provider.dart';
import 'package:provider/provider.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filtroTipo = 'Todas'; // Todas, Gasto, Ingreso

  // Iconos disponibles para categorías
  final List<IconData> _iconosDisponibles = [
    // Compras y consumo
    Icons.shopping_cart,
    Icons.shopping_bag,
    Icons.store,
    Icons.local_mall,
    Icons.local_grocery_store,
    // Comida y bebida
    Icons.restaurant,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.local_pizza,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.breakfast_dining,
    Icons.cake,
    Icons.liquor,
    // Transporte
    Icons.local_gas_station,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.train,
    Icons.flight,
    Icons.two_wheeler,
    Icons.local_taxi,
    Icons.directions_bike,
    Icons.directions_subway,
    Icons.airport_shuttle,
    // Hogar
    Icons.home,
    Icons.house,
    Icons.apartment,
    Icons.bed,
    Icons.weekend,
    Icons.chair,
    Icons.roofing,
    // Servicios
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.wifi,
    Icons.phone_android,
    Icons.phone,
    Icons.tv,
    Icons.router,
    Icons.cable,
    Icons.power,
    // Salud y bienestar
    Icons.medical_services,
    Icons.local_hospital,
    Icons.local_pharmacy,
    Icons.healing,
    Icons.favorite,
    Icons.psychology,
    Icons.spa,
    Icons.clean_hands,
    Icons.medication,
    Icons.vaccines,
    // Educación
    Icons.school,
    Icons.menu_book,
    Icons.library_books,
    Icons.auto_stories,
    Icons.science,
    Icons.calculate,
    Icons.edit_note,
    // Entretenimiento
    Icons.movie,
    Icons.theaters,
    Icons.live_tv,
    Icons.music_note,
    Icons.headphones,
    Icons.videogame_asset,
    Icons.casino,
    Icons.celebration,
    Icons.festival,
    // Deportes
    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.sports_tennis,
    Icons.sports_baseball,
    Icons.sports_football,
    Icons.fitness_center,
    Icons.pool,
    Icons.surfing,
    Icons.snowboarding,
    Icons.sailing,
    // Finanzas
    Icons.attach_money,
    Icons.savings,
    Icons.account_balance,
    Icons.credit_card,
    Icons.payment,
    Icons.currency_exchange,
    Icons.paid,
    Icons.money,
    Icons.account_balance_wallet,
    // Trabajo y negocios
    Icons.work,
    Icons.business,
    Icons.business_center,
    Icons.badge,
    Icons.engineering,
    Icons.construction,
    Icons.precision_manufacturing,
    Icons.agriculture,
    Icons.handyman,
    // Regalos y celebraciones
    Icons.card_giftcard,
    Icons.redeem,
    Icons.volunteer_activism,
    Icons.emoji_events,
    // Tecnología
    Icons.computer,
    Icons.laptop,
    Icons.tablet,
    Icons.watch,
    Icons.headset,
    Icons.keyboard,
    Icons.mouse,
    Icons.print,
    // Mascotas y animales
    Icons.pets,
    Icons.cruelty_free,
    // Familia
    Icons.child_care,
    Icons.baby_changing_station,
    Icons.face,
    Icons.elderly,
    Icons.people,
    Icons.groups,
    Icons.family_restroom,
    // Viajes
    Icons.airplane_ticket,
    Icons.luggage,
    Icons.hotel,
    Icons.beach_access,
    Icons.place,
    Icons.map,
    Icons.explore,
    Icons.tour,
    // Otros
    Icons.category,
    Icons.more_horiz,
    Icons.star,
    Icons.bolt,
    Icons.local_fire_department,
    Icons.eco,
    Icons.recycling,
    Icons.brush,
    Icons.palette,
    Icons.photo_camera,
    Icons.notifications,
    Icons.alarm,
  ];

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Categorías',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          // Filtros
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onSelected: (value) {
              setState(() {
                _filtroTipo = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'Todas', child: Text('Todas')),
                  const PopupMenuItem(value: 'Gasto', child: Text('Gastos')),
                  const PopupMenuItem(value: 'Pago', child: Text('Pagos')),
                  const PopupMenuItem(
                    value: 'Ingreso',
                    child: Text('Ingresos'),
                  ),
                ],
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.obtenerCategorias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
            padding: EdgeInsets.all(16.w),
            itemCount: categoriasFiltradas.length,
            itemBuilder: (context, index) {
              final categoria = categoriasFiltradas[index];
              return _buildCategoriaCard(categoria, isDark);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCategoria(context),
        backgroundColor: const Color(0xFF667eea),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nueva',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80.sp,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'No hay categorías',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Agrega tu primera categoría',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(Map<String, dynamic> categoria, bool isDark) {
    final tipoTransaccion = categoria['tipoTransaccion'] ?? 'Gasto';
    final color = _getColorForTipo(tipoTransaccion);

    // Obtener el icono
    final iconCode = categoria['imagen'] ?? 'shopping_cart';
    final iconData = _getIconFromString(iconCode);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(iconData, color: color, size: 24.sp),
        ),
        title: Text(
          categoria['categoria'] ?? '',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          tipoTransaccion,
          style: GoogleFonts.poppins(fontSize: 13.sp, color: color),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: Colors.blue.shade400),
              onPressed:
                  () => _mostrarDialogoCategoria(context, categoria: categoria),
            ),
            IconButton(
              icon: Icon(Icons.delete_rounded, color: Colors.red.shade400),
              onPressed: () => _confirmarEliminar(categoria),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForTipo(String tipo) {
    switch (tipo) {
      case 'Ingreso':
        return const Color(0xFF4CAF50);
      case 'Pago':
        return const Color(0xFFFF9800);
      case 'Gasto':
      default:
        return const Color(0xFFF44336);
    }
  }

  IconData _getIconFromString(String iconString) {
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

  String _getIconStringFromData(IconData icon) {
    final iconMap = {
      // Compras
      Icons.shopping_cart: 'shopping_cart',
      Icons.shopping_bag: 'shopping_bag',
      Icons.store: 'store',
      Icons.local_mall: 'local_mall',
      Icons.local_grocery_store: 'local_grocery_store',
      // Comida
      Icons.restaurant: 'restaurant',
      Icons.restaurant_outlined: 'restaurant_outlined',
      Icons.fastfood: 'fastfood',
      Icons.local_cafe: 'local_cafe',
      Icons.local_bar: 'local_bar',
      Icons.local_pizza: 'local_pizza',
      Icons.lunch_dining: 'lunch_dining',
      Icons.dinner_dining: 'dinner_dining',
      Icons.breakfast_dining: 'breakfast_dining',
      Icons.cake: 'cake',
      Icons.liquor: 'liquor',
      // Transporte
      Icons.local_gas_station: 'local_gas_station',
      Icons.directions_car: 'directions_car',
      Icons.directions_car_outlined: 'directions_car_outlined',
      Icons.directions_bus: 'directions_bus',
      Icons.train: 'train',
      Icons.flight: 'flight',
      Icons.two_wheeler: 'two_wheeler',
      Icons.local_taxi: 'local_taxi',
      Icons.directions_bike: 'directions_bike',
      Icons.directions_subway: 'directions_subway',
      Icons.airport_shuttle: 'airport_shuttle',
      // Hogar
      Icons.home: 'home',
      Icons.home_outlined: 'home_outlined',
      Icons.house: 'house',
      Icons.house_outlined: 'house_outlined',
      Icons.apartment: 'apartment',
      Icons.bed: 'bed',
      Icons.weekend: 'weekend',
      Icons.chair: 'chair',
      Icons.roofing: 'roofing',
      // Servicios
      Icons.electric_bolt: 'electric_bolt',
      Icons.electrical_services_outlined: 'electrical_services_outlined',
      Icons.water_drop: 'water_drop',
      Icons.water_drop_outlined: 'water_drop_outlined',
      Icons.wifi: 'wifi',
      Icons.wifi_outlined: 'wifi_outlined',
      Icons.phone_android: 'phone_android',
      Icons.phone: 'phone',
      Icons.phone_outlined: 'phone_outlined',
      Icons.tv: 'tv',
      Icons.tv_outlined: 'tv_outlined',
      Icons.router: 'router',
      Icons.cable: 'cable',
      Icons.power: 'power',
      // Salud
      Icons.medical_services: 'medical_services',
      Icons.medical_services_outlined: 'medical_services_outlined',
      Icons.local_hospital: 'local_hospital',
      Icons.local_pharmacy: 'local_pharmacy',
      Icons.healing: 'healing',
      Icons.favorite: 'favorite',
      Icons.psychology: 'psychology',
      Icons.spa: 'spa',
      Icons.clean_hands: 'clean_hands',
      Icons.medication: 'medication',
      Icons.vaccines: 'vaccines',
      // Educación
      Icons.school: 'school',
      Icons.school_outlined: 'school_outlined',
      Icons.menu_book: 'menu_book',
      Icons.library_books: 'library_books',
      Icons.auto_stories: 'auto_stories',
      Icons.science: 'science',
      Icons.calculate: 'calculate',
      Icons.edit_note: 'edit_note',
      // Entretenimiento
      Icons.movie: 'movie',
      Icons.movie_outlined: 'movie_outlined',
      Icons.theaters: 'theaters',
      Icons.live_tv: 'live_tv',
      Icons.music_note: 'music_note',
      Icons.headphones: 'headphones',
      Icons.videogame_asset: 'videogame_asset',
      Icons.casino: 'casino',
      Icons.casino_outlined: 'casino_outlined',
      Icons.celebration: 'celebration',
      Icons.festival: 'festival',
      // Ropa y accesorios
      Icons.checkroom_outlined: 'checkroom_outlined',
      // Deportes
      Icons.sports: 'sports',
      Icons.sports_soccer: 'sports_soccer',
      Icons.sports_basketball: 'sports_basketball',
      Icons.sports_tennis: 'sports_tennis',
      Icons.sports_baseball: 'sports_baseball',
      Icons.sports_football: 'sports_football',
      Icons.fitness_center: 'fitness_center',
      Icons.pool: 'pool',
      Icons.surfing: 'surfing',
      Icons.snowboarding: 'snowboarding',
      Icons.sailing: 'sailing',
      // Finanzas
      Icons.attach_money: 'attach_money',
      Icons.attach_money_outlined: 'attach_money_outlined',
      Icons.monetization_on_outlined: 'monetization_on_outlined',
      Icons.savings: 'savings',
      Icons.account_balance: 'account_balance',
      Icons.credit_card: 'credit_card',
      Icons.payment: 'payment',
      Icons.currency_exchange: 'currency_exchange',
      Icons.paid: 'paid',
      Icons.money: 'money',
      Icons.account_balance_wallet: 'account_balance_wallet',
      Icons.trending_up_outlined: 'trending_up_outlined',
      Icons.sell_outlined: 'sell_outlined',
      Icons.workspace_premium_outlined: 'workspace_premium_outlined',
      Icons.real_estate_agent_outlined: 'real_estate_outlined',
      Icons.location_city_outlined: 'location_city_outlined',
      Icons.security_outlined: 'security_outlined',
      Icons.receipt_long_outlined: 'receipt_long_outlined',
      // Trabajo
      Icons.work: 'work',
      Icons.work_outlined: 'work_outlined',
      Icons.business: 'business',
      Icons.business_outlined: 'business_outlined',
      Icons.business_center: 'business_center',
      Icons.badge: 'badge',
      Icons.engineering: 'engineering',
      Icons.construction: 'construction',
      Icons.precision_manufacturing: 'precision_manufacturing',
      Icons.agriculture: 'agriculture',
      Icons.handyman: 'handyman',
      Icons.handyman_outlined: 'handyman_outlined',
      // Regalos
      Icons.card_giftcard: 'card_giftcard',
      Icons.card_giftcard_outlined: 'card_giftcard_outlined',
      Icons.redeem: 'redeem',
      Icons.redeem_outlined: 'redeem_outlined',
      Icons.volunteer_activism: 'volunteer_activism',
      Icons.emoji_events: 'emoji_events',
      // Tecnología
      Icons.computer: 'computer',
      Icons.laptop: 'laptop',
      Icons.tablet: 'tablet',
      Icons.watch: 'watch',
      Icons.headset: 'headset',
      Icons.keyboard: 'keyboard',
      Icons.mouse: 'mouse',
      Icons.print: 'print',
      // Mascotas
      Icons.pets: 'pets',
      Icons.pets_outlined: 'pets_outlined',
      Icons.cruelty_free: 'cruelty_free',
      // Familia
      Icons.child_care: 'child_care',
      Icons.baby_changing_station: 'baby_changing_station',
      Icons.face: 'face',
      Icons.elderly: 'elderly',
      Icons.elderly_outlined: 'elderly_outlined',
      Icons.people: 'people',
      Icons.groups: 'groups',
      Icons.family_restroom: 'family_restroom',
      // Viajes
      Icons.airplanemode_active_outlined: 'airplanemode_active_outlined',
      Icons.airplane_ticket: 'airplane_ticket',
      Icons.luggage: 'luggage',
      Icons.hotel: 'hotel',
      Icons.beach_access: 'beach_access',
      Icons.place: 'place',
      Icons.map: 'map',
      Icons.explore: 'explore',
      Icons.tour: 'tour',
      // Otros
      Icons.category: 'category',
      Icons.more_horiz: 'more_horiz',
      Icons.star: 'star',
      Icons.bolt: 'bolt',
      Icons.local_fire_department: 'local_fire_department',
      Icons.eco: 'eco',
      Icons.recycling: 'recycling',
      Icons.brush: 'brush',
      Icons.palette: 'palette',
      Icons.photo_camera: 'photo_camera',
      Icons.notifications: 'notifications',
      Icons.alarm: 'alarm',
      Icons.propane_tank: 'propane_tank',
      Icons.local_laundry_service: 'local_laundry_service',
      Icons.emergency_outlined: 'emergency_outlined',
    };

    return iconMap[icon] ?? 'category';
  }

  Future<void> _mostrarDialogoCategoria(
    BuildContext context, {
    Map<String, dynamic>? categoria,
  }) async {
    final isEdit = categoria != null;
    final nombreController = TextEditingController(
      text: categoria?['categoria'] ?? '',
    );
    final tipoController = TextEditingController(
      text: categoria?['tipoTransaccion'] ?? 'Gasto',
    );

    IconData iconoSeleccionado = _getIconFromString(
      categoria?['imagen'] ?? 'shopping_cart',
    );

    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.isDarkMode;

    await showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  backgroundColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  title: Text(
                    isEdit ? 'Editar Categoría' : 'Nueva Categoría',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  content: SizedBox(
                    width: 300.w,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre
                          TextField(
                            controller: nombreController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: TextStyle(
                                color:
                                    isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              filled: true,
                              fillColor:
                                  isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.grey.shade100,
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Tipo de transacción
                          DropdownButtonFormField<String>(
                            value: tipoController.text,
                            decoration: InputDecoration(
                              labelText: 'Tipo',
                              labelStyle: TextStyle(
                                color:
                                    isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              filled: true,
                              fillColor:
                                  isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.grey.shade100,
                            ),
                            dropdownColor:
                                isDark ? const Color(0xFF2A2A2A) : Colors.white,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            items:
                                ['Gasto', 'Pago', 'Ingreso'].map((tipo) {
                                  return DropdownMenuItem(
                                    value: tipo,
                                    child: Text(tipo),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                tipoController.text = value;
                              }
                            },
                          ),
                          SizedBox(height: 16.h),

                          // Selector de icono
                          Text(
                            'Icono',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          SizedBox(
                            height: 180.h,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: GridView.builder(
                                padding: EdgeInsets.all(8.w),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 5,
                                      mainAxisSpacing: 8.h,
                                      crossAxisSpacing: 8.w,
                                    ),
                                itemCount: _iconosDisponibles.length,
                                itemBuilder: (context, index) {
                                  final icon = _iconosDisponibles[index];
                                  final isSelected = icon == iconoSeleccionado;

                                  return GestureDetector(
                                    onTap: () {
                                      setStateDialog(() {
                                        iconoSeleccionado = icon;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? const Color(
                                                  0xFF667eea,
                                                ).withOpacity(0.2)
                                                : Colors.transparent,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? const Color(0xFF667eea)
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Icon(
                                        icon,
                                        color:
                                            isSelected
                                                ? const Color(0xFF667eea)
                                                : (isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600),
                                        size: 24.sp,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(
                          color:
                              isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final nombre = nombreController.text.trim();
                        final tipo = tipoController.text;
                        final iconString = _getIconStringFromData(
                          iconoSeleccionado,
                        );

                        if (nombre.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El nombre es requerido'),
                              behavior: SnackBarBehavior.fixed,
                            ),
                          );
                          return;
                        }

                        try {
                          if (isEdit) {
                            await _firestoreService.actualizarCategoria(
                              categoriaId: categoria['id'],
                              nombre: nombre,
                              imagen: iconString,
                              tipoTransaccion: tipo,
                            );
                          } else {
                            await _firestoreService.crearCategoria(
                              nombre: nombre,
                              imagen: iconString,
                              tipoTransaccion: tipo,
                            );
                          }

                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Categoría actualizada'
                                      : 'Categoría creada',
                                ),
                                behavior: SnackBarBehavior.fixed,
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                behavior: SnackBarBehavior.fixed,
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Actualizar' : 'Crear',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar. La categoría está en uso'),
          behavior: SnackBarBehavior.fixed,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;

    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDark = themeManager.isDarkMode;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              '¿Eliminar categoría?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              '¿Estás seguro de eliminar "${categoria['categoria']}"?',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Eliminar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await _firestoreService.eliminarCategoria(categoria['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría eliminada'),
              behavior: SnackBarBehavior.fixed,
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              behavior: SnackBarBehavior.fixed,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
