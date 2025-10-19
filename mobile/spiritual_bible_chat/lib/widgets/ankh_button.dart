import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnkhButton extends StatelessWidget {
  const AnkhButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !isLoading;
    final backgroundRadius = BorderRadius.circular(16);

    Widget buildContent() {
      if (isLoading) {
        return const SizedBox(
          key: ValueKey('ankh-button-loading'),
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.obsidian),
          ),
        );
      }

      final textStyle = theme.textTheme.titleMedium;
      return Row(
        key: const ValueKey('ankh-button-label'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.obsidian),
            const SizedBox(width: 8),
          ],
          Text(label, style: textStyle),
        ],
      );
    }

    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.aurora,
        borderRadius: backgroundRadius,
        boxShadow: const [
          BoxShadow(color: Color(0x33C6A664), blurRadius: 18, spreadRadius: 2),
          BoxShadow(color: Color(0x22C6A664), blurRadius: 30, spreadRadius: 10),
        ],
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: backgroundRadius),
          foregroundColor: AppColors.obsidian,
          textStyle: theme.textTheme.titleMedium,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: buildContent(),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
