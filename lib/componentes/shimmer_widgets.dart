import 'package:flutter/material.dart';
import '../utils/animation_utils.dart';

/// Widgets shimmer prediseñados para estados de carga

/// Shimmer para tarjeta de transacción
class TransactionCardShimmer extends StatelessWidget {
  const TransactionCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ShimmerLoading(
          isLoading: true,
          child: Row(
            children: [
              // Icono
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Monto
              Container(
                height: 20,
                width: 80,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer para tarjeta de estadística (Dashboard)
class StatCardShimmer extends StatelessWidget {
  const StatCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ShimmerLoading(
          isLoading: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 24,
                width: 120,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer para lista de transacciones
class TransactionListShimmer extends StatelessWidget {
  final int itemCount;

  const TransactionListShimmer({Key? key, this.itemCount = 5})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const TransactionCardShimmer();
      },
    );
  }
}

/// Shimmer para gráfica circular
class CircularChartShimmer extends StatelessWidget {
  final double size;

  const CircularChartShimmer({Key? key, this.size = 200}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return ShimmerLoading(
      isLoading: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
      ),
    );
  }
}

/// Shimmer para saldo principal (Dashboard header)
class BalanceHeaderShimmer extends StatelessWidget {
  const BalanceHeaderShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return ShimmerLoading(
      isLoading: true,
      child: Column(
        children: [
          Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            width: 200,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 24),
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
