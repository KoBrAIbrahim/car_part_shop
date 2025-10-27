import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CarPartsPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final Function(int)? onPageSelected;

  const CarPartsPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.getCardBackground(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          _buildPageButton(
            icon: Icons.chevron_left,
            label: 'Previous',
            onPressed: currentPage > 0 && !isLoading ? onPreviousPage : null,
            context: context,
          ),

          // Page Numbers
          Expanded(child: _buildPageNumbers(context)),

          // Next Button
          _buildPageButton(
            icon: Icons.chevron_right,
            label: 'Next',
            onPressed: currentPage < totalPages - 1 && !isLoading
                ? onNextPage
                : null,
            context: context,
            isNext: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required BuildContext context,
    bool isNext = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getTextColor(isDark);

    return TextButton.icon(
      onPressed: onPressed,
      icon: isNext ? null : Icon(icon, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNext) ...[
            Text(label),
          ] else ...[
            Text(label),
            const SizedBox(width: 4),
            Icon(icon, size: 18),
          ],
        ],
      ),
      style: TextButton.styleFrom(
        foregroundColor: onPressed != null
            ? AppColors.yellow
            : textColor.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPageNumbers(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.yellow,
              ),
            )
          else
            _buildPageNumbersRow(context, isDark),
        ],
      ),
    );
  }

  Widget _buildPageNumbersRow(BuildContext context, bool isDark) {
    List<Widget> pageButtons = [];

    // Show first page, current page vicinity, and last page with ellipsis if needed
    if (totalPages <= 7) {
      // Show all pages if total is 7 or less
      for (int i = 0; i < totalPages; i++) {
        pageButtons.add(_buildPageNumberButton(i, context, isDark));
      }
    } else {
      // More complex pagination for many pages
      if (currentPage <= 3) {
        // Show first 5 pages, ellipsis, last page
        for (int i = 0; i < 5; i++) {
          pageButtons.add(_buildPageNumberButton(i, context, isDark));
        }
        pageButtons.add(_buildEllipsis(isDark));
        pageButtons.add(
          _buildPageNumberButton(totalPages - 1, context, isDark),
        );
      } else if (currentPage >= totalPages - 4) {
        // Show first page, ellipsis, last 5 pages
        pageButtons.add(_buildPageNumberButton(0, context, isDark));
        pageButtons.add(_buildEllipsis(isDark));
        for (int i = totalPages - 5; i < totalPages; i++) {
          pageButtons.add(_buildPageNumberButton(i, context, isDark));
        }
      } else {
        // Show first page, ellipsis, current vicinity, ellipsis, last page
        pageButtons.add(_buildPageNumberButton(0, context, isDark));
        pageButtons.add(_buildEllipsis(isDark));
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          pageButtons.add(_buildPageNumberButton(i, context, isDark));
        }
        pageButtons.add(_buildEllipsis(isDark));
        pageButtons.add(
          _buildPageNumberButton(totalPages - 1, context, isDark),
        );
      }
    }

    return Wrap(spacing: 4, children: pageButtons);
  }

  Widget _buildPageNumberButton(
    int pageIndex,
    BuildContext context,
    bool isDark,
  ) {
    final isCurrentPage = pageIndex == currentPage;
    final textColor = AppColors.getTextColor(isDark);

    return GestureDetector(
      onTap: !isCurrentPage && !isLoading
          ? () => onPageSelected?.call(pageIndex)
          : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCurrentPage
              ? AppColors.yellow
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrentPage
                ? AppColors.yellow
                : AppColors.getDivider(isDark),
          ),
        ),
        child: Center(
          child: Text(
            '${pageIndex + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              color: isCurrentPage
                  ? Colors.black // Black text on yellow
                  : textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(bool isDark) {
    return Container(
      width: 32,
      height: 32,
      child: Center(
        child: Text(
          '...',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextColor(isDark).withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}