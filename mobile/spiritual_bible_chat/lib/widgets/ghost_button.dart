import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !isLoading;
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 18, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 22, vertical: 16);

    Widget buildContent() {
      if (isLoading) {
        return const SizedBox(
          key: ValueKey('ghost-button-loading'),
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.maatGold),
          ),
        );
      }

      return Row(
        key: const ValueKey('ghost-button-label'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.maatGold),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.maatGold,
            ),
          ),
        ],
      );
    }

    final button = OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
            color: AppColors.maatGold.withOpacity(enabled ? 0.9 : 0.4)),
        foregroundColor: AppColors.maatGold,
        backgroundColor: AppColors.onyx.withOpacity(0.35),
        disabledForegroundColor: AppColors.maatGold.withOpacity(0.4),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: buildContent(),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
