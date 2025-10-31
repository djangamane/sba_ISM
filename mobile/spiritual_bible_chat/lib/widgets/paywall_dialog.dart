import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ankh_button.dart';
import 'ghost_button.dart';
import 'glass_card.dart';

class PaywallDialog extends StatelessWidget {
  const PaywallDialog({
    super.key,
    required this.onSelectPlan,
    required this.onSelectLifetime,
    required this.message,
  });

  final Future<bool> Function(bool annual) onSelectPlan;
  final Future<bool> Function() onSelectLifetime;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        backgroundColor: AppColors.onyx.withOpacity(0.88),
        borderColor: AppColors.maatGold.withOpacity(0.28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(false),
                icon: const Icon(Icons.close, color: AppColors.quartz),
              ),
            ),
            Text(
              'Begin the inner work',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.quartz,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BenefitRow('Unlimited sacred conversations each day'),
                SizedBox(height: 10),
                _BenefitRow('Full devotional library & ritual blueprints'),
                SizedBox(height: 10),
                _BenefitRow('Priority responses and upcoming temple features'),
              ],
            ),
            const SizedBox(height: 28),
            AnkhButton(
              label: 'Annual pilgrimage • \$49.99',
              icon: Icons.workspace_premium_outlined,
              expand: true,
              onPressed: () async {
                final success = await onSelectPlan(true);
                if (!context.mounted) return;
                Navigator.of(context).pop(success);
              },
            ),
            const SizedBox(height: 12),
            GhostButton(
              label: 'Monthly journey • \$4.99',
              icon: Icons.calendar_month_outlined,
              expand: true,
              onPressed: () async {
                final success = await onSelectPlan(false);
                if (!context.mounted) return;
                Navigator.of(context).pop(success);
              },
            ),
            const SizedBox(height: 12),
            GhostButton(
              label: 'Limited lifetime access • \$150 (first 50)',
              icon: Icons.auto_awesome,
              expand: true,
              onPressed: () async {
                final success = await onSelectLifetime();
                if (!context.mounted) return;
                Navigator.of(context).pop(success);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Maybe later'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 18, color: AppColors.maatGold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.papyrus,
            ),
          ),
        ),
      ],
    );
  }
}
