import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../exceptions/paywall_required_exception.dart';
import '../../models/onboarding_profile.dart';
import '../../utils/api_base.dart';

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
      const SnackBar(content: Text('Copied devotional to clipboard.')),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.verseReference,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.verseText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      devotional,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _copyToClipboard(devotional),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _future = _fetchDevotional();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate'),
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
    return const Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(),
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
    final description = error?.toString() ?? 'Unknown error';
    final icon = isPaywall ? Icons.workspace_premium_outlined : Icons.wifi_off;
    final iconColor =
        isPaywall ? theme.colorScheme.primary : theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Text(
              isPaywall ? 'Premium required' : 'Unable to load devotional',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (isPaywall && onShowPaywall != null)
              FilledButton.icon(
                onPressed: onShowPaywall,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Upgrade to Premium'),
              )
            else
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
          ],
        ),
      ),
    );
  }
}
