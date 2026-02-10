import 'package:flutter/material.dart';
import '../utils/animation_utils.dart';

/// Estados vacíos con ilustraciones y animaciones

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor =
        iconColor ?? theme.colorScheme.primary.withOpacity(0.5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado
            AnimationUtils.scaleIn(
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: defaultIconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: defaultIconColor),
              ),
              duration: AnimationUtils.slow,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 24),
            // Título
            AnimationUtils.fadeIn(
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              delay: 200,
            ),
            const SizedBox(height: 12),
            // Mensaje
            AnimationUtils.fadeIn(
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              delay: 300,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              // Botón de acción
              AnimationUtils.fadeIn(
                BounceTapButton(
                  onTap: onAction,
                  child: ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add),
                    label: Text(actionLabel!),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                delay: 400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state para transacciones
class EmptyTransactionsState extends StatelessWidget {
  final VoidCallback? onAddTransaction;

  const EmptyTransactionsState({Key? key, this.onAddTransaction})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Sin transacciones',
      message:
          'Aún no tienes transacciones registradas.\n¡Comienza a registrar tus gastos e ingresos!',
      actionLabel: 'Agregar Transacción',
      onAction: onAddTransaction,
      iconColor: Colors.blue,
    );
  }
}

/// Empty state para cuentas
class EmptyAccountsState extends StatelessWidget {
  final VoidCallback? onAddAccount;

  const EmptyAccountsState({Key? key, this.onAddAccount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Sin cuentas',
      message:
          'No tienes cuentas configuradas.\nAgrega tu primera cuenta para comenzar.',
      actionLabel: 'Agregar Cuenta',
      onAction: onAddAccount,
      iconColor: Colors.green,
    );
  }
}

/// Empty state para reportes
class EmptyReportsState extends StatelessWidget {
  const EmptyReportsState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.assessment_outlined,
      title: 'Sin reportes',
      message:
          'No hay reportes disponibles en este momento.\nRealiza transacciones para generar reportes.',
      iconColor: Colors.purple,
    );
  }
}

/// Empty state para búsqueda sin resultados
class EmptySearchState extends StatelessWidget {
  final String? searchQuery;

  const EmptySearchState({Key? key, this.searchQuery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Sin resultados',
      message:
          searchQuery != null
              ? 'No se encontraron resultados para "$searchQuery"'
              : 'No se encontraron resultados',
      iconColor: Colors.orange,
    );
  }
}

/// Empty state para categorías
class EmptyCategoriesState extends StatelessWidget {
  const EmptyCategoriesState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.category_outlined,
      title: 'Sin categorías',
      message:
          'No hay categorías disponibles.\nComunícate con el administrador.',
      iconColor: Colors.deepPurple,
    );
  }
}

/// Empty state genérico con ilustración personalizada
class CustomEmptyState extends StatelessWidget {
  final String imagePath;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CustomEmptyState({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustración
            AnimationUtils.scaleIn(
              Image.asset(
                imagePath,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              duration: AnimationUtils.slow,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 24),
            // Título
            AnimationUtils.fadeIn(
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              delay: 200,
            ),
            const SizedBox(height: 12),
            // Mensaje
            AnimationUtils.fadeIn(
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              delay: 300,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              AnimationUtils.fadeIn(
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
                delay: 400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
