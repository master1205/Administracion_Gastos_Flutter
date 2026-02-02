import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
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

  String _getIconStringFromData(IconData icon) {
    // Guardar el codePoint del icono permite usar cualquier icono de Material Icons
    // sin necesidad de mantener un mapa enorme manualmente
    return icon.codePoint.toString();
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

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setStateDialog) => Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header simple
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.08),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24.r),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(14.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667eea),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF667eea,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                iconoSeleccionado,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit
                                        ? 'Editar Categoría'
                                        : 'Nueva Categoría',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Completa la información',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(Icons.close, size: 24.sp),
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                      // Contenido
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(20.r),
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
                                    isDark
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.white,
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

                              // Selector de icono con búsqueda
                              _buildSelectorIconoConBusqueda(
                                context,
                                isDark,
                                iconoSeleccionado,
                                (icon) {
                                  setStateDialog(() {
                                    iconoSeleccionado = icon;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Footer con botones
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
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
                                      await _firestoreService
                                          .actualizarCategoria(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  isEdit ? 'Actualizar' : 'Crear',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.all(28.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 48.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  '¿Eliminar categoría?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  '¿Estás seguro de eliminar "${categoria['categoria']}"?',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Esta acción no se puede deshacer',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Eliminar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
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

  // Selector de icono con flutter_iconpicker (incluye búsqueda)
  Widget _buildSelectorIconoConBusqueda(
    BuildContext context,
    bool isDark,
    IconData? iconoSeleccionado,
    Function(IconData) onIconSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icono',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),

        // Botón para abrir el selector con búsqueda
        GestureDetector(
          onTap: () async {
            IconPickerIcon? icon = await showIconPicker(
              context,
              configuration: SinglePickerConfiguration(
                iconPackModes: [IconPack.material],
                iconSize: 44.0,
                iconColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                backgroundColor:
                    isDark ? const Color(0xFF1E1E1E) : Colors.white,
                selectedIconBackgroundColor:
                    isDark
                        ? const Color(0xFF667eea).withOpacity(0.3)
                        : const Color(0xFF667eea).withOpacity(0.15),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  maxWidth: 600,
                ),
                searchHintText: 'Buscar icono...',
                noResultsText: 'No se encontraron resultados',
                showTooltips: true,
                title: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Seleccionar icono',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Busca por nombre en inglés: restaurant, car, home...',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                closeChild: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                iconPickerShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            );

            if (icon != null) {
              onIconSelected(icon.data);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDark
                        ? [const Color(0xFF2A2A2A), const Color(0xFF252525)]
                        : [Colors.grey.shade50, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color:
                    isDark
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.grey.shade300.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono seleccionado
                Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isDark
                              ? [Colors.grey.shade800, Colors.grey.shade900]
                              : [Colors.white, Colors.grey.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.grey.shade700.withOpacity(0.5)
                              : Colors.grey.shade300.withOpacity(0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    iconoSeleccionado ?? Icons.category,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    size: 30.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar icono',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Toca para buscar',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color:
                              isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Icono de búsqueda
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.grey.shade800.withOpacity(0.5)
                            : Colors.grey.shade200.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
