import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../theme_provider.dart';

class ColorPickerTile extends StatelessWidget {
  const ColorPickerTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: Icon(
        Icons.palette_outlined,
        color: const Color(0xFF30cfd0),
        size: 24.sp,
      ),
      title: Text(
        'Color de acento',
        style: GoogleFonts.lato(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        'Personaliza el tema de la app',
        style: GoogleFonts.openSans(
          fontSize: 11.sp,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: themeManager.accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    themeManager.isDarkMode
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.chevron_right, size: 20.sp, color: Colors.grey.shade400),
        ],
      ),
      onTap: () => _showColorPicker(context, themeManager),
    );
  }

  void _showColorPicker(BuildContext context, ThemeManager themeManager) {
    Color tempColor = themeManager.accentColor;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  title: Text(
                    'Seleccionar color',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Selector de color completo
                        ColorPicker(
                          color: tempColor,
                          onColorChanged: (Color color) {
                            setState(() {
                              tempColor = color;
                            });
                          },
                          width: 40.w,
                          height: 40.h,
                          borderRadius: 8.r,
                          spacing: 5,
                          runSpacing: 5,
                          wheelDiameter: 200.w,
                          heading: Text(
                            'Selector de color',
                            style: GoogleFonts.lato(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  themeManager.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          subheading: Text(
                            'Toca para seleccionar',
                            style: GoogleFonts.openSans(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          pickersEnabled: const <ColorPickerType, bool>{
                            ColorPickerType.both: false,
                            ColorPickerType.primary: true,
                            ColorPickerType.accent: true,
                            ColorPickerType.bw: false,
                            ColorPickerType.custom: false,
                            ColorPickerType.wheel: true,
                          },
                          enableShadesSelection: true,
                          showColorCode: true,
                          colorCodeHasColor: true,
                          showColorName: false,
                          showMaterialName: false,
                          enableOpacity: false,
                          enableTonalPalette: true,
                        ),
                        SizedBox(height: 16.h),
                        Divider(color: Colors.grey.shade400),
                        SizedBox(height: 8.h),
                        // Colores predefinidos
                        Text(
                          'Colores rápidos',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                themeManager.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.maxFinite,
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            alignment: WrapAlignment.center,
                            children:
                                _colors.map((color) {
                                  final isSelected =
                                      color.value == tempColor.value;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        tempColor = color;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Container(
                                      width: 44.w,
                                      height: 44.h,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: Colors.white,
                                                  width: 3.w,
                                                )
                                                : null,
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: color.withOpacity(
                                                      0.5,
                                                    ),
                                                    blurRadius: 8.r,
                                                    offset: Offset(0, 2.h),
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      alignment: Alignment.center,
                                      child:
                                          isSelected
                                              ? Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 24.sp,
                                              )
                                              : null,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.lato(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        themeManager.setAccentColor(tempColor);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tempColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                      ),
                      child: Text(
                        'Aplicar',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  static final List<Color> _colors = [
    const Color(0xFF667eea), // Morado-azul (default Cashew)
    const Color(0xFFEF476F), // Rojo
    const Color(0xFFFF6B6B), // Rojo claro
    const Color(0xFFFF8C42), // Naranja
    const Color(0xFFFFD166), // Amarillo
    const Color(0xFF06D6A0), // Verde agua
    const Color(0xFF118AB2), // Azul
    const Color(0xFF073B4C), // Azul oscuro
    const Color(0xFF9B5DE5), // Morado
    const Color(0xFFF15BB5), // Rosa
    const Color(0xFF00BBF9), // Cyan
    const Color(0xFF00F5FF), // Cyan claro
    const Color(0xFF4ECDC4), // Turquesa
    const Color(0xFF95E1D3), // Verde menta
    const Color(0xFFAACC00), // Verde lima
    const Color(0xFF88D498), // Verde suave
    const Color(0xFFF38181), // Rosa salmón
    const Color(0xFFAA96DA), // Lavanda
  ];
}
