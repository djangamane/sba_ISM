import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sign_in_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  static AuthGateState? of(BuildContext context) {
    return context.findAncestorStateOfType<AuthGateState>();
  }

  static void requestSignIn(BuildContext context) {
    of(context)?._requestSignIn();
  }

  static void continueAsGuest(BuildContext context) {
    of(context)?._continueAsGuestMode();
  }

  @override
  State<AuthGate> createState() => AuthGateState();
}

class AuthGateState extends State<AuthGate> {
  late final SupabaseClient _client;
  late final StreamSubscription<AuthState> _authSub;
  bool _continueAsGuest = false;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _authSub = _client.auth.onAuthStateChange.listen((event) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _client.auth.currentSession;
    if (_continueAsGuest) {
      return widget.child;
    }
    if (session == null) {
      return SignInScreen(
        onSignedIn: () => setState(() {}),
        onContinueAsGuest: () => setState(() => _continueAsGuest = true),
      );
    }
    return widget.child;
  }

  void _requestSignIn() {
    setState(() {
      _continueAsGuest = false;
    });
  }

  void _continueAsGuestMode() {
    setState(() {
      _continueAsGuest = true;
    });
  }
}
