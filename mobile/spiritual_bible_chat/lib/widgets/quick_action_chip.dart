import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuickActionChip extends StatelessWidget {
  const QuickActionChip({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.maatGold),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.papyrus,
            letterSpacing: 0.2,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x44121218),
            Color(0x662A2721),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.maatGold.withOpacity(0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B0B0F),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: content,
    );

    if (onPressed == null) {
      return child;
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      splashColor: AppColors.maatGold.withOpacity(0.12),
      highlightColor: AppColors.maatGold.withOpacity(0.08),
      child: child,
    );
  }
}
