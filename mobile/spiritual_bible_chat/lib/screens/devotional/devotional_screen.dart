import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../exceptions/paywall_required_exception.dart';
import '../../models/onboarding_profile.dart';
import '../../utils/api_base.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ankh_button.dart';
import '../../widgets/ghost_button.dart';
import '../../widgets/glass_card.dart';

class DevotionalScreen extends StatefulWidget {
  const DevotionalScreen({
    super.key,
    required this.profile,
    required this.verseText,
    required this.verseReference,
    this.onPaywall,
  });

  final OnboardingProfile profile;
  final String verseText;
  final String verseReference;
  final Future<void> Function(BuildContext context, String message)? onPaywall;

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchDevotional();
  }

  Future<String> _fetchDevotional() async {
    final uri = Uri.parse('${apiBaseUrl()}/api/v1/devotional');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ...await authHeaders(),
      },
      body: jsonEncode({
        'verseText': widget.verseText,
        'verseReference': widget.verseReference,
        'persona': {
          'goal': widget.profile.goal.name,
          'familiarity': widget.profile.familiarity.name,
          'preferences':
              widget.profile.contentPreferences.map((e) => e.name).toList(),
        },
      }),
    );

    if (response.statusCode >= 400) {
      if (response.statusCode == 401) {
        throw Exception('Please sign in to read devotional content.');
      }
      if (response.statusCode == 402) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw PaywallRequiredException(
          body['error'] as String? ?? 'Upgrade required to read devotionals.',
        );
      }
      throw Exception('Server responded with status ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final devotional = payload['devotional'] as String?;
    if (devotional == null || devotional.isEmpty) {
      throw Exception('Empty devotional response');
    }
    return devotional;
  }

  Future<void> _copyToClipboard(String devotional) async {
    await Clipboard.setData(ClipboardData(text: devotional));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Devotional copied. Share when you feel led.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Devotional'),
      ),
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DevotionalLoading();
          }

          if (snapshot.hasError) {
            return _DevotionalError(
              error: snapshot.error,
              onRetry: () {
                setState(() {
                  _future = _fetchDevotional();
                });
              },
              onShowPaywall: snapshot.error is PaywallRequiredException &&
                      widget.onPaywall != null
                  ? () async {
                      await widget.onPaywall!(
                        context,
                        (snapshot.error as PaywallRequiredException).message,
                      );
                      if (mounted) {
                        setState(() {
                          _future = _fetchDevotional();
                        });
                      }
                    }
                  : null,
            );
          }

          final devotional = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  backgroundGradient: AppGradients.aurora,
                  borderColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.verseReference,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.obsidian,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.verseText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.obsidian.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    backgroundColor: AppColors.onyx.withOpacity(0.58),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        devotional,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AnkhButton(
                      label: 'Copy devotional',
                      icon: Icons.copy_outlined,
                      onPressed: () => _copyToClipboard(devotional),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                    ),
                    GhostButton(
                      label: 'Request another',
                      icon: Icons.refresh,
                      onPressed: () {
                        setState(() {
                          _future = _fetchDevotional();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DevotionalLoading extends StatelessWidget {
  const _DevotionalLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        backgroundColor: AppColors.onyx.withOpacity(0.65),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.maatGold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gathering today’s devotional...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DevotionalError extends StatelessWidget {
  const _DevotionalError({
    required this.error,
    required this.onRetry,
    this.onShowPaywall,
  });

  final Object? error;
  final VoidCallback onRetry;
  final Future<void> Function()? onShowPaywall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaywall = error is PaywallRequiredException;
    final friendlyDescription = isPaywall
        ? (error as PaywallRequiredException).message
        : 'The devotional well is momentarily unavailable. Please try again soon.';
    final title =
        isPaywall ? 'Premium devotionals await' : 'Devotional unavailable';
    final icon = isPaywall ? Icons.workspace_premium_outlined : Icons.wifi_off;

    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        backgroundColor: AppColors.onyx.withOpacity(0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isPaywall ? AppGradients.aurora : null,
                color: isPaywall ? null : AppColors.lotusRose.withOpacity(0.2),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isPaywall ? AppColors.obsidian : AppColors.lotusRose,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              friendlyDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.quartz,
              ),
            ),
            const SizedBox(height: 20),
            if (isPaywall && onShowPaywall != null)
              AnkhButton(
                label: 'Upgrade to Premium',
                icon: Icons.workspace_premium_outlined,
                onPressed: onShowPaywall,
              )
            else
              GhostButton(
                label: 'Try again',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}
