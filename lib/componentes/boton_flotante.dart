import 'package:flutter/material.dart';
import 'package:notificaciones/dynamic_form_screen.dart';

class FloatingActionMenu extends StatefulWidget {
  const FloatingActionMenu({super.key});

  @override
  _FloatingActionState createState() => _FloatingActionState();
}

class _FloatingActionState extends State<FloatingActionMenu> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 80,
          right: 10,
          child: Visibility(
            visible: _isExpanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildFloatingActionButton(
                  Icons.undo,
                  'Reembolsos',
                  Colors.purple,
                ),
                _buildFloatingActionButton(
                  Icons.payment,
                  'Pagos',
                  Colors.orange,
                ),
                _buildFloatingActionButton(
                  Icons.compare_arrows,
                  'Transferencias',
                  Colors.blue,
                ),
                _buildFloatingActionButton(
                  Icons.attach_money,
                  'Ingresos',
                  Colors.green,
                ),
                _buildFloatingActionButton(
                  Icons.money_off,
                  'Gastos',
                  Colors.red,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: FloatingActionButton(
            onPressed: _toggleExpand,
            tooltip: 'Dock Button',
            shape: const CircleBorder(),
            child: Icon(_isExpanded ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }

  void _navigateToDynamicFormScreen(String type, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TrasaccionScreen(transactionType: type, color: color),
      ),
    );
  }

  Widget _buildFloatingActionButton(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () {
              _navigateToDynamicFormScreen(label, color);
              _toggleExpand();
            },
            tooltip: label,
            backgroundColor: color,
            shape: const CircleBorder(),
            child: Icon(icon),
          ),
        ],
      ),
    );
  }
}
