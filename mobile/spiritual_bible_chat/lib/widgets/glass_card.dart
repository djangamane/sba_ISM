import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundGradient,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Gradient? backgroundGradient;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: backgroundGradient,
      color: backgroundGradient == null
          ? (backgroundColor ?? AppColors.onyx.withOpacity(0.55))
          : null,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: borderColor ?? AppColors.maatGold.withOpacity(0.18),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x220B0B0F),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    );

    return Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );
  }
}
