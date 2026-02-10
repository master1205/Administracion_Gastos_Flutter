import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget genérico para secciones expandibles con cards
class ExpandableSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onViewAll;
  final Widget Function(T item, bool isFirst) itemBuilder;
  final String itemLabel;
  final T Function(List<T>)? selectPrincipal;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.items,
    required this.isExpanded,
    required this.onToggle,
    required this.onViewAll,
    required this.itemBuilder,
    required this.itemLabel,
    this.selectPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final itemPrincipal = selectPrincipal?.call(items) ?? items.first;
    final otherItems = items.where((item) => item != itemPrincipal).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        itemBuilder(itemPrincipal, true),
        if (otherItems.isNotEmpty)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                isExpanded
                    ? Column(
                      children:
                          otherItems
                              .map(
                                (item) => Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: itemBuilder(item, false),
                                ),
                              )
                              .toList(),
                    )
                    : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'Ver todos',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de toggle simple para expandir/contraer
class ExpandToggleButton extends StatelessWidget {
  final bool isExpanded;
  final int itemCount;
  final String itemLabel;
  final VoidCallback onToggle;

  const ExpandToggleButton({
    super.key,
    required this.isExpanded,
    required this.itemCount,
    required this.itemLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isExpanded
                  ? 'Ver menos'
                  : 'Ver $itemCount $itemLabel${itemCount > 1 ? 's' : ''} más',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.primary,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}
