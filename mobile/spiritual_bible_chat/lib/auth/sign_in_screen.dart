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
        final response = await client.auth.signUp(email: email, password: password);
        if (response.session != null) {
          if (mounted) widget.onSignedIn();
        } else {
          setState(() {
            _info =
                'Account created! Check your email to confirm your address before signing in.';
          });
        }
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
        if (mounted) {
          widget.onSignedIn();
        }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to sync your streaks and preferences across devices.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              if (_info != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _info!,
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
                      onPressed:
                          _isLoading ? null : () => _signIn(isSignUp: false),
                      child: _isLoading
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
                    onPressed:
                        _isLoading ? null : () => _signIn(isSignUp: true),
                    child: const Text('Create account'),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : widget.onContinueAsGuest,
                  child: const Text('Continue as guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
