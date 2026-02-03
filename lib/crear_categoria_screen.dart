import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'componentes/heads_up_notification.dart';
import 'services/firestore_service.dart';
import 'theme_provider.dart';
import 'widgets/discard_changes_dialog.dart';

class CrearCategoriaScreen extends StatefulWidget {
  final Map<String, dynamic>? categoria;

  const CrearCategoriaScreen({Key? key, this.categoria}) : super(key: key);

  @override
  State<CrearCategoriaScreen> createState() => _CrearCategoriaScreenState();
}

class _CrearCategoriaScreenState extends State<CrearCategoriaScreen> {
  final _firestoreService = FirestoreService();
  final _nombreController = TextEditingController();
  String _tipoSeleccionado = 'Gasto';
  IconData _iconoSeleccionado = Icons.shopping_cart;

  // Estado inicial para detectar cambios
  late String _initialNombre;
  late String _initialTipo;
  late IconData _initialIcono;

  @override
  void initState() {
    super.initState();
    if (widget.categoria != null) {
      _nombreController.text = widget.categoria!['categoria'] ?? '';
      _tipoSeleccionado = widget.categoria!['tipoTransaccion'] ?? 'Gasto';
      _iconoSeleccionado = _getIconFromString(
        widget.categoria!['imagen'] ?? 'shopping_cart',
      );
    }
    _saveInitialState();
  }

  void _saveInitialState() {
    _initialNombre = _nombreController.text;
    _initialTipo = _tipoSeleccionado;
    _initialIcono = _iconoSeleccionado;
  }

  bool _hasChanges() {
    return _nombreController.text != _initialNombre ||
        _tipoSeleccionado != _initialTipo ||
        _iconoSeleccionado != _initialIcono;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges()) {
      return await DiscardChangesDialog.show(context);
    }
    return true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  IconData _getIconFromString(String iconString) {
    try {
      final codePoint = int.parse(iconString);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.category;
    }
  }

  String _getIconStringFromData(IconData icon) {
    return icon.codePoint.toString();
  }

  Color _getColorForTipo(String tipo) {
    switch (tipo) {
      case 'Gasto':
        return const Color(0xFFE53935);
      case 'Ingreso':
        return const Color(0xFF43A047);
      case 'Pago':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF667eea);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;
    final isEdit = widget.categoria != null;
    final colorTipo = _getColorForTipo(_tipoSeleccionado);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: colorTipo,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            isEdit ? 'Editar Categoría' : 'Nueva Categoría',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          children: [
            // Header con ícono
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: colorTipo,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconoSeleccionado,
                      color: Colors.white,
                      size: 48.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Personaliza tu categoría',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20.r,
                  right: 20.r,
                  top: 20.r,
                  bottom: 20.r + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    _buildSectionTitle('Nombre de la categoría', isDark),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _nombreController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _buildInputDecoration(
                        hintText: 'Ej: Comida, Transporte, Ropa',
                        prefixIcon: Icons.label_outline,
                        isDark: isDark,
                        color: colorTipo,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Tipo de transacción
                    _buildSectionTitle('Tipo de transacción', isDark),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTipoChip(
                            'Gasto',
                            const Color(0xFFE53935),
                            isDark,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTipoChip(
                            'Ingreso',
                            const Color(0xFF43A047),
                            isDark,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTipoChip(
                            'Pago',
                            const Color(0xFFFF9800),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Selector de ícono
                    _buildSectionTitle('Ícono', isDark),
                    SizedBox(height: 12.h),
                    InkWell(
                      onTap: () async {
                        final icon = await showIconPicker(
                          context,
                          configuration: SinglePickerConfiguration(
                            iconPackModes: [IconPack.material],
                            iconColor:
                                isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                            searchHintText: 'Buscar ícono...',
                          ),
                        );
                        if (icon != null) {
                          setState(() => _iconoSeleccionado = icon.data);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: colorTipo.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: colorTipo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                _iconoSeleccionado,
                                color: colorTipo,
                                size: 32.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                'Toca para cambiar el ícono',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color:
                                      isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 12.h),
          child: ElevatedButton(
            onPressed: () async {
              final nombre = _nombreController.text.trim();
              if (nombre.isEmpty) {
                showErrorNotification(
                  context,
                  message: 'El nombre es requerido',
                );
                return;
              }

              try {
                final iconString = _getIconStringFromData(_iconoSeleccionado);

                if (isEdit) {
                  await _firestoreService.actualizarCategoria(
                    categoriaId: widget.categoria!['id'],
                    nombre: nombre,
                    imagen: iconString,
                    tipoTransaccion: _tipoSeleccionado,
                  );
                } else {
                  await _firestoreService.crearCategoria(
                    nombre: nombre,
                    imagen: iconString,
                    tipoTransaccion: _tipoSeleccionado,
                  );
                }

                if (mounted) {
                  showSuccessNotification(
                    context,
                    message:
                        isEdit ? 'Categoría actualizada' : 'Categoría creada',
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  showErrorNotification(
                    context,
                    message: 'Error',
                    subtitle: e.toString(),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorTipo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
            ),
            child: Text(
              isEdit ? 'Actualizar Categoría' : 'Crear Categoría',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTipoChip(String tipo, Color color, bool isDark) {
    final isSelected = _tipoSeleccionado == tipo;
    return GestureDetector(
      onTap: () => setState(() => _tipoSeleccionado = tipo),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withOpacity(0.15)
                  : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected
                    ? color
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              tipo == 'Gasto'
                  ? Icons.arrow_downward
                  : (tipo == 'Ingreso' ? Icons.arrow_upward : Icons.payment),
              color: isSelected ? color : Colors.grey.shade400,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              tipo,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected
                        ? color
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    required Color color,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.openSans(
        color: Colors.grey.shade400,
        fontSize: 12.sp,
      ),
      prefixIcon: Container(
        margin: EdgeInsets.all(10.r),
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Icon(prefixIcon, color: Colors.white, size: 20.sp),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    );
  }
}
