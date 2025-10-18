import 'package:flutter/material.dart';

class PaywallDialog extends StatelessWidget {
  const PaywallDialog({
    super.key,
    required this.onSelectPlan,
    required this.message,
  });

  final Future<bool> Function(bool annual) onSelectPlan;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Upgrade to Premium',
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 12),
          const Text('Premium unlocks:'),
          const SizedBox(height: 8),
          const Text('• Unlimited AI conversations'),
          const Text('• Unlimited daily devotionals'),
          const Text('• Priority responses and new features'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Maybe later'),
        ),
        FilledButton(
          onPressed: () async {
            final success = await onSelectPlan(false);
            if (!context.mounted) return;
            Navigator.of(context).pop(success);
          },
          child: const Text('Monthly \$9.99'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            final success = await onSelectPlan(true);
            if (!context.mounted) return;
            Navigator.of(context).pop(success);
          },
          child: const Text('Annual \$69.99'),
        ),
      ],
    );
  }
}
