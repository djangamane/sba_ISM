import 'package:flutter/material.dart';

class PaywallDialog extends StatelessWidget {
  const PaywallDialog(
      {super.key, required this.onUpgrade, required this.message});

  final Future<void> Function() onUpgrade;
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
            await onUpgrade();
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Start demo'),
        ),
      ],
    );
  }
}
