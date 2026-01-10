import 'package:cloud_firestore/cloud_firestore.dart';

class InicializadorCategorias {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String defaultUserId = 'default_user';

  /// Script temporal para regenerar todas las categorías
  /// Este método debe ejecutarse UNA SOLA VEZ al iniciar la app
  static Future<void> regenerarCategorias() async {
    print('🔄 Iniciando regeneración de categorías...');

    try {
      // 1. ELIMINAR todas las categorías existentes
      print('🗑️  Eliminando categorías existentes...');
      final categoriasExistentes =
          await _db
              .collection('categorias')
              .where('usuarioId', isEqualTo: defaultUserId)
              .get();

      final batch = _db.batch();
      for (var doc in categoriasExistentes.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('✅ ${categoriasExistentes.docs.length} categorías eliminadas');

      // 2. CREAR las nuevas categorías
      print('📝 Creando nuevas categorías...');

      final categorias = [
        // GASTOS (14 categorías consolidadas)
        {'nombre': 'Alimentación', 'icono': 'restaurant', 'tipo': 'Gasto'},
        {
          'nombre': 'Transporte',
          'icono': 'directions_car_outlined',
          'tipo': 'Gasto',
        },
        {
          'nombre': 'Viajes',
          'icono': 'airplanemode_active_outlined',
          'tipo': 'Gasto',
        },
        {
          'nombre': 'Hogar y Muebles',
          'icono': 'house_outlined',
          'tipo': 'Gasto',
        },
        {
          'nombre': 'Salud',
          'icono': 'medical_services_outlined',
          'tipo': 'Gasto',
        },
        {
          'nombre': 'Ropa y Calzado',
          'icono': 'checkroom_outlined',
          'tipo': 'Gasto',
        },
        {
          'nombre': 'Entretenimiento',
          'icono': 'movie_outlined',
          'tipo': 'Gasto',
        },
        {'nombre': 'Deportes', 'icono': 'sports', 'tipo': 'Gasto'},
        {
          'nombre': 'Belleza y Cuidado Personal',
          'icono': 'spa',
          'tipo': 'Gasto',
        },
        {'nombre': 'Electrónica', 'icono': 'laptop', 'tipo': 'Gasto'},
        {'nombre': 'Mascotas', 'icono': 'pets_outlined', 'tipo': 'Gasto'},
        {
          'nombre': 'Regalos y Donaciones',
          'icono': 'card_giftcard_outlined',
          'tipo': 'Gasto',
        },
        {
          'nombre': 'Reparaciones',
          'icono': 'handyman_outlined',
          'tipo': 'Gasto',
        },
        {'nombre': 'Otros Gastos', 'icono': 'more_horiz', 'tipo': 'Gasto'},

        // INGRESOS (7 categorías consolidadas)
        {'nombre': 'Salario', 'icono': 'work_outlined', 'tipo': 'Ingreso'},
        {
          'nombre': 'Trabajo Independiente',
          'icono': 'business_outlined',
          'tipo': 'Ingreso',
        },
        {
          'nombre': 'Inversiones',
          'icono': 'trending_up_outlined',
          'tipo': 'Ingreso',
        },
        {
          'nombre': 'Rentas',
          'icono': 'real_estate_outlined',
          'tipo': 'Ingreso',
        },
        {
          'nombre': 'Regalos Recibidos',
          'icono': 'redeem_outlined',
          'tipo': 'Ingreso',
        },
        {
          'nombre': 'Pensión/Jubilación',
          'icono': 'elderly_outlined',
          'tipo': 'Ingreso',
        },
        {
          'nombre': 'Otros Ingresos',
          'icono': 'monetization_on_outlined',
          'tipo': 'Ingreso',
        },

        // PAGOS (9 categorías consolidadas)
        {'nombre': 'Vivienda', 'icono': 'home_outlined', 'tipo': 'Pago'},
        {
          'nombre': 'Servicios Básicos',
          'icono': 'electrical_services_outlined',
          'tipo': 'Pago',
        },
        {
          'nombre': 'Internet y Teléfono',
          'icono': 'wifi_outlined',
          'tipo': 'Pago',
        },
        {'nombre': 'Streaming', 'icono': 'tv_outlined', 'tipo': 'Pago'},
        {'nombre': 'Gimnasio', 'icono': 'fitness_center', 'tipo': 'Pago'},
        {'nombre': 'Seguros', 'icono': 'security_outlined', 'tipo': 'Pago'},
        {
          'nombre': 'Préstamos',
          'icono': 'receipt_long_outlined',
          'tipo': 'Pago',
        },
        {
          'nombre': 'Otros Pagos',
          'icono': 'attach_money_outlined',
          'tipo': 'Pago',
        },
      ];

      final batch2 = _db.batch();

      for (var catData in categorias) {
        final docRef = _db.collection('categorias').doc();
        batch2.set(docRef, {
          'categoria': catData['nombre'],
          'imagen': catData['icono'],
          'tipoTransaccion': catData['tipo'],
          'usuarioId': defaultUserId,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
      }

      await batch2.commit();
      print('✅ ${categorias.length} categorías creadas exitosamente');
      print('🎉 Regeneración de categorías completada');
    } catch (e) {
      print('❌ Error al regenerar categorías: $e');
      rethrow;
    }
  }
}

/// CÓDIGO OBSOLETO - Se mantiene por si se necesita referencia
/// Script para inicializar categorías por defecto en Firebase
/// Solo se debe ejecutar una vez al migrar de Google Sheets a Firebase
Future<void> inicializarCategoriasDefecto() async {
  final db = FirebaseFirestore.instance;
  const userId = 'default_user';

  // Categorías por defecto
  final categorias = [
    {
      'categoria': 'Alimentación',
      'imagen': 'restaurant',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Transporte',
      'imagen': 'directions_car',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Servicios',
      'imagen': 'electric_bolt',
      'tipoTransaccion': 'Pago',
      'usuarioId': userId,
    },
    {
      'categoria': 'Entretenimiento',
      'imagen': 'movie',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Salud',
      'imagen': 'medical_services',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Educación',
      'imagen': 'school',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Hogar',
      'imagen': 'home',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Ropa',
      'imagen': 'shopping_bag',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Salario',
      'imagen': 'attach_money',
      'tipoTransaccion': 'Ingreso',
      'usuarioId': userId,
    },
    {
      'categoria': 'Inversiones',
      'imagen': 'savings',
      'tipoTransaccion': 'Ingreso',
      'usuarioId': userId,
    },
    {
      'categoria': 'Gasolina',
      'imagen': 'local_gas_station',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Mascotas',
      'imagen': 'pets',
      'tipoTransaccion': 'Gasto',
      'usuarioId': userId,
    },
    {
      'categoria': 'Gym',
      'imagen': 'fitness_center',
      'tipoTransaccion': 'Pago',
      'usuarioId': userId,
    },
    {
      'categoria': 'Teléfono',
      'imagen': 'phone_android',
      'tipoTransaccion': 'Pago',
      'usuarioId': userId,
    },
    {
      'categoria': 'Internet',
      'imagen': 'wifi',
      'tipoTransaccion': 'Pago',
      'usuarioId': userId,
    },
  ];

  print('🚀 Inicializando categorías por defecto...');

  try {
    // Verificar si ya existen categorías
    final existentes =
        await db
            .collection('categorias')
            .where('usuarioId', isEqualTo: userId)
            .limit(1)
            .get();

    if (existentes.docs.isNotEmpty) {
      print(
        '⚠️ Ya existen categorías en Firebase. No se agregaron duplicados.',
      );
      return;
    }

    // Insertar categorías en lote
    final batch = db.batch();
    for (final categoria in categorias) {
      final docRef = db.collection('categorias').doc();
      batch.set(docRef, {
        ...categoria,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print('✅ ${categorias.length} categorías inicializadas correctamente');
  } catch (e) {
    print('❌ Error al inicializar categorías: $e');
  }
}
