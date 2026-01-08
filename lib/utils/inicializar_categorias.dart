import 'package:cloud_firestore/cloud_firestore.dart';

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
