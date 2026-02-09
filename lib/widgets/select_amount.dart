import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

/// Widget para seleccionar un monto con teclado numérico personalizado
/// Incluye calculadora integrada y formateo de moneda
class SelectAmountWidget extends StatefulWidget {
  const SelectAmountWidget({
    Key? key,
    required this.setSelectedAmount,
    this.amountPassed = "",
    this.next,
    this.nextLabel,
    this.allowZero = false,
    this.padding = EdgeInsets.zero,
    this.showEnteredNumber = true,
    this.enableCalculator = true,
    this.currencySymbol = '\$',
  }) : super(key: key);

  final Function(double amount, String stringAmount) setSelectedAmount;
  final String amountPassed;
  final VoidCallback? next;
  final String? nextLabel;
  final bool allowZero;
  final EdgeInsets padding;
  final bool showEnteredNumber;
  final bool enableCalculator;
  final String currencySymbol;

  @override
  _SelectAmountWidgetState createState() => _SelectAmountWidgetState();
}

class _SelectAmountWidgetState extends State<SelectAmountWidget> {
  String amount = "";
  FocusNode _focusNode = FocusNode();
  late FocusAttachment _focusAttachment;

  @override
  void initState() {
    super.initState();
    amount = widget.amountPassed;
    // Limpiar valores que equivalen a cero
    if (amount == "0" ||
        amount == "0.0" ||
        amount == "0.00" ||
        double.tryParse(amount) == 0) {
      amount = "";
    }
    _focusAttachment = _focusNode.attach(
      context,
      onKeyEvent: (node, event) {
        bool keyIsPressed =
            event.runtimeType == KeyDownEvent ||
            event.runtimeType == KeyRepeatEvent;

        if (!keyIsPressed) return KeyEventResult.ignored;

        // Números
        if (event.logicalKey.keyLabel.length == 1) {
          String key = event.logicalKey.keyLabel;
          if (RegExp(r'[0-9]').hasMatch(key)) {
            addToAmount(key, hapticFeedback: false);
            return KeyEventResult.handled;
          }
        }

        // Operaciones
        if (widget.enableCalculator) {
          if (event.logicalKey == LogicalKeyboardKey.numpadAdd ||
              event.logicalKey == LogicalKeyboardKey.add ||
              event.logicalKey.keyLabel == '+') {
            addToAmount("+", hapticFeedback: false);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.numpadSubtract ||
              event.logicalKey == LogicalKeyboardKey.minus ||
              event.logicalKey.keyLabel == '-') {
            addToAmount("-", hapticFeedback: false);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.numpadMultiply ||
              event.logicalKey == LogicalKeyboardKey.asterisk ||
              event.logicalKey.keyLabel == '*') {
            addToAmount("×", hapticFeedback: false);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.numpadDivide ||
              event.logicalKey == LogicalKeyboardKey.slash ||
              event.logicalKey.keyLabel == '/') {
            addToAmount("÷", hapticFeedback: false);
            return KeyEventResult.handled;
          }
        }

        // Punto decimal
        if (event.logicalKey == LogicalKeyboardKey.period ||
            event.logicalKey.keyLabel == '.') {
          addToAmount(".", hapticFeedback: false);
          return KeyEventResult.handled;
        }

        // Backspace
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          removeToAmount();
          return KeyEventResult.handled;
        }

        // Enter
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            widget.next != null) {
          widget.next!();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );
    _focusNode.requestFocus();

    // Notificar el monto inicial para que el padre lo conozca
    if (amount.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyAmountChange();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void addToAmount(String input, {bool hapticFeedback = true}) {
    if (hapticFeedback) {
      if (includesOperations(input, false)) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }

    String amountClone = amount;

    // Validar punto decimal
    if (input == "." &&
        !decimalCheck(operationsWithSpaces(amountClone + "."))) {
      return;
    }

    // Limitar a 2 decimales
    if (!includesOperations(input, true)) {
      // Es un número - solo validar si NO acabamos de poner un operador
      if (amount.isNotEmpty &&
          !includesOperations(amount.substring(amount.length - 1), false)) {
        String lastSegment = getLastNumberSegment(amount);
        if (lastSegment.contains(".")) {
          int decimalPos = lastSegment.indexOf(".");
          int decimalsCount = lastSegment.length - decimalPos - 1;
          if (decimalsCount >= 2) {
            // Ya tiene 2 decimales, no permitir más
            return;
          }
        }
      }
    }

    if (amount.isEmpty && !includesOperations(input, false)) {
      if (input == "0") {
        return;
      } else if (input == ".") {
        setState(() {
          amount = "0.";
        });
      } else {
        setState(() {
          amount = input;
        });
      }
    } else if (amount.isNotEmpty &&
        (!includesOperations(amount.substring(amount.length - 1), true) &&
                includesOperations(input, true) ||
            !includesOperations(input, true))) {
      setState(() {
        amount += input;
      });
    } else if (amount.isNotEmpty &&
        includesOperations(amount.substring(amount.length - 1), false) &&
        input == ".") {
      setState(() {
        amount += "0.";
      });
    } else if (amount.isNotEmpty &&
        amount.substring(amount.length - 1) == "." &&
        includesOperations(input, false)) {
      setState(() {
        amount = amount.substring(0, amount.length - 1) + input;
      });
    } else if (amount.isNotEmpty &&
        includesOperations(amount.substring(amount.length - 1), false) &&
        includesOperations(input, false)) {
      // Reemplazar última operación con la nueva
      setState(() {
        amount = amount.substring(0, amount.length - 1) + input;
      });
    } else if (amount.isEmpty && input == "-") {
      setState(() {
        amount = input;
      });
    }

    _notifyAmountChange();
  }

  void removeToAmount() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (amount.isNotEmpty) {
        amount = amount.substring(0, amount.length - 1);
      }
    });
    _notifyAmountChange();
  }

  void removeAll() {
    HapticFeedback.heavyImpact();
    setState(() {
      amount = "";
    });
    _notifyAmountChange();
  }

  void _notifyAmountChange() {
    double result = calculateResult(amount);
    widget.setSelectedAmount(result, amount);
  }

  bool includesOperations(String input, bool checkAll) {
    if (checkAll) {
      return input.contains("÷") ||
          input.contains("×") ||
          input.contains("-") ||
          input.contains("+");
    }
    return input == "÷" || input == "×" || input == "-" || input == "+";
  }

  bool decimalCheck(String input) {
    var splitInputs = input.split(" ");
    for (var splitInput in splitInputs) {
      if ('.'.allMatches(splitInput).length > 1) {
        return false;
      }
    }
    return true;
  }

  String getLastNumberSegment(String input) {
    if (input.isEmpty) return "";

    // Obtener el último segmento numérico después de cualquier operación
    String withSpaces = operationsWithSpaces(input);
    List<String> segments = withSpaces.split(" ");

    // Obtener el último segmento no vacío que no sea un operador
    for (int i = segments.length - 1; i >= 0; i--) {
      String seg = segments[i].trim();
      if (seg.isNotEmpty && !includesOperations(seg, true)) {
        return seg;
      }
    }
    return "";
  }

  String operationsWithSpaces(String input) {
    return input
        .replaceAll("÷", " ÷ ")
        .replaceAll("×", " × ")
        .replaceAll("-", " - ")
        .replaceAll("+", " + ");
  }

  double calculateResult(String input) {
    if (input.isEmpty) {
      return 0;
    }

    String changedInput = input;
    if (includesOperations(input.substring(input.length - 1), true)) {
      changedInput = input.substring(0, input.length - 1);
    }

    if (changedInput.isEmpty) {
      return 0;
    }

    changedInput = changedInput.replaceAll("÷", "/");
    changedInput = changedInput.replaceAll("×", "*");

    double result = 0;
    try {
      Parser p = Parser();
      Expression exp = p.parse(changedInput);
      ContextModel cm = ContextModel();
      result = exp.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      try {
        result = double.parse(changedInput);
      } catch (e2) {
        result = 0;
      }
    }
    return result;
  }

  String formatMoney(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: widget.currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment.reparent();
    final theme = Theme.of(context);
    String amountConverted = amount.isEmpty ? "0" : amount;
    double calculatedAmount = calculateResult(amountConverted);
    String displayAmount = amount.isEmpty ? "0" : amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mostrar número ingresado
        if (widget.showEnteredNumber)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Resultado formateado
                Text(
                  formatMoney(calculatedAmount),
                  style: GoogleFonts.poppins(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.end,
                ),
                // Cálculo si hay operaciones
                if (widget.enableCalculator && includesOperations(amount, true))
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      displayAmount,
                      style: GoogleFonts.lato(
                        fontSize: 16.sp,
                        color: theme.colorScheme.secondary.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

        // Teclado numérico
        Padding(padding: widget.padding, child: _buildNumberPad(theme)),

        // Botón siguiente
        if (widget.next != null) ...[
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              decoration: BoxDecoration(
                color:
                    (calculatedAmount > 0 || widget.allowZero)
                        ? theme.colorScheme.secondary.withOpacity(0.08)
                        : theme.colorScheme.secondary.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color:
                      (calculatedAmount > 0 || widget.allowZero)
                          ? theme.colorScheme.secondary.withOpacity(0.2)
                          : theme.colorScheme.secondary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      (calculatedAmount > 0 || widget.allowZero)
                          ? widget.next
                          : null,
                  borderRadius: BorderRadius.circular(12.r),
                  splashColor: theme.colorScheme.secondary.withOpacity(0.1),
                  highlightColor: theme.colorScheme.secondary.withOpacity(0.05),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Center(
                      child: Text(
                        widget.nextLabel ?? 'Continuar',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              (calculatedAmount > 0 || widget.allowZero)
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.secondary.withOpacity(
                                    0.4,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberPad(ThemeData theme) {
    final buttonColor = theme.colorScheme.surface;
    final buttonTextColor = theme.colorScheme.onSurface;

    return Container(
      constraints: BoxConstraints(maxWidth: 400.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.15),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(8.r),
      child: Column(
        children: [
          // Fila 1: 1 2 3 ÷
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  '1',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('1'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildButton(
                  '2',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('2'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildButton(
                  '3',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('3'),
                ),
              ),
              if (widget.enableCalculator) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildButton(
                    '÷',
                    buttonColor,
                    buttonTextColor,
                    onTap: () => addToAmount('÷'),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),

          // Fila 2: 4 5 6 ×
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  '4',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('4'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildButton(
                  '5',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('5'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildButton(
                  '6',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('6'),
                ),
              ),
              if (widget.enableCalculator) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildButton(
                    '×',
                    buttonColor,
                    buttonTextColor,
                    onTap: () => addToAmount('×'),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),

          // Fila 3: 7 8 9 -
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  '7',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('7'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildButton(
                  '8',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('8'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildButton(
                  '9',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('9'),
                ),
              ),
              if (widget.enableCalculator) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildButton(
                    '-',
                    buttonColor,
                    buttonTextColor,
                    onTap: () => addToAmount('-'),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),

          // Fila 4: . 0 ⌫ +
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  '.',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('.'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildButton(
                  '0',
                  buttonColor,
                  buttonTextColor,
                  onTap: () => addToAmount('0'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildButton(
                  'C',
                  buttonColor,
                  buttonTextColor,
                  icon: Icons.backspace_outlined,
                  onTap: removeToAmount,
                  onLongPress: removeAll,
                ),
              ),
              if (widget.enableCalculator) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildButton(
                    '+',
                    buttonColor,
                    buttonTextColor,
                    onTap: () => addToAmount('+'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String label,
    Color bgColor,
    Color textColor, {
    IconData? icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12.r),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        child: Container(
          height: 56.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child:
              icon != null
                  ? Icon(icon, size: 24.sp, color: textColor)
                  : Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
        ),
      ),
    );
  }
}

/// Bottom sheet para seleccionar monto
Future<double?> showSelectAmountBottomSheet(
  BuildContext context, {
  String title = 'Ingresa el monto',
  double initialAmount = 0,
  bool allowZero = false,
  String currencySymbol = '\$',
}) async {
  double? selectedAmount;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final bottomPadding =
          MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom
              : MediaQuery.of(context).viewPadding.bottom;

      final theme = Theme.of(context);
      return SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.only(top: 16.h, bottom: bottomPadding + 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.secondary.withOpacity(0.2),
              ),

              // Widget de selección de monto
              SelectAmountWidget(
                amountPassed: initialAmount.toString(),
                allowZero: allowZero,
                currencySymbol: currencySymbol,
                setSelectedAmount: (amount, _) {
                  selectedAmount = amount;
                },
                next: () {
                  Navigator.pop(context);
                },
                nextLabel: 'Confirmar',
                padding: EdgeInsets.all(16.r),
              ),
            ],
          ),
        ),
      );
    },
  );

  return selectedAmount;
}
