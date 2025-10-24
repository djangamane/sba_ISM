import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen(
      {super.key, required this.onSignedIn, required this.onContinueAsGuest});

  final VoidCallback onSignedIn;
  final VoidCallback onContinueAsGuest;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn({required bool isSignUp}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
    });
    try {
      final client = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (isSignUp) {
        final response =
            await client.auth.signUp(email: email, password: password);
        if (response.session != null) {
          if (!mounted) return;
          widget.onSignedIn();
        } else {
          setState(() {
            _info =
                'Account created! Check your email to confirm your address before signing in.';
          });
        }
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
        if (!mounted) return;
        widget.onSignedIn();
      }
    } on AuthException catch (error) {
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      setState(() {
        _error = 'Unexpected error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 720 ? 64.0 : 24.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    32,
                    horizontalPadding,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter the inner temple',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.02,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'First time here? Ride as a guest to explore OMEGA’s guidance before you create an account.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _HighlightList(theme: theme),
                      const SizedBox(height: 24),
                      FilledButton.tonalIcon(
                        onPressed:
                            _isLoading ? null : widget.onContinueAsGuest,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Enter as a guest'),
                      ),
                      const SizedBox(height: 32),
                      _SignInCard(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        isLoading: _isLoading,
                        error: _error,
                        info: _info,
                        onSignIn: () => _signIn(isSignUp: false),
                        onCreateAccount: () => _signIn(isSignUp: true),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HighlightList extends StatelessWidget {
  const _HighlightList({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final textColor = theme.colorScheme.onSurface.withOpacity(0.78);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HighlightRow(
          icon: Icons.psychology_alt_outlined,
          title: 'Decode scripture without colonial distortion',
          color: theme.colorScheme.primary,
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        _HighlightRow(
          icon: Icons.favorite_outline,
          title: 'Daily Kemetic reflections & imaginal rituals',
          color: theme.colorScheme.secondary,
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        _HighlightRow(
          icon: Icons.auto_fix_high_outlined,
          title: 'Track streaks, sacred prompts, and breakthroughs',
          color: theme.colorScheme.tertiary,
          textColor: textColor,
        ),
      ],
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
          ),
        ),
      ],
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.error,
    required this.info,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? error;
  final String? info;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface.withOpacity(0.82),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Returning pilgrim',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.04,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to sync your streaks, rituals, and saved revelations.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (error != null)
              Text(
                error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            if (info != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  info!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading ? null : onSignIn,
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: isLoading ? null : onCreateAccount,
                  child: const Text('Create account'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'After creating an account, check your email for a confirmation link before signing in.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
