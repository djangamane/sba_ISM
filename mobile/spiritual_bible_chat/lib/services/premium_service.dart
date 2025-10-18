import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/premium_state.dart';
import 'backend_profile_service.dart';
import 'paywall_service.dart';

class PremiumService {
  PremiumService._();

  static final PremiumService instance = PremiumService._();

  final ValueNotifier<PremiumState> state =
      ValueNotifier<PremiumState>(PremiumState.initial());

  final BackendProfileService _backendProfileService =
      const BackendProfileService();
  final PaywallService _paywallService = PaywallService();

  Future<void> configure() async {
    // No-op for web build; Stripe configuration handled via backend.
    final stripeKey = dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ??
        const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
    if (stripeKey.isEmpty) {
      debugPrint(
          'Stripe publishable key missing. Premium checkout will use demo upgrade fallback.');
    }
  }

  Future<void> logIn(String? userId) async {
    await refreshStatus();
  }

  Future<void> logOut() async {
    state.value = PremiumState.initial();
  }

  Future<void> refreshStatus() async {
    state.value = state.value.copyWith(isLoading: true, errorMessage: null);

    PremiumState? combined;
    Exception? failure;

    try {
      final backendState = await _backendProfileService.fetchPremiumState();
      combined = backendState;
    } catch (error) {
      failure = Exception(error.toString());
    }

    state.value = (combined ?? PremiumState.initial()).copyWith(
      isLoading: false,
      errorMessage: failure?.toString(),
    );
  }

  Future<bool> startPurchaseFlow() async {
    try {
      final checkoutUrl = await _paywallService.createStripeCheckoutSession();
      if (checkoutUrl == null) {
        return false;
      }
      final launched =
          await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
      return launched;
    } catch (error) {
      debugPrint('Stripe checkout launch failed: $error');
      rethrow;
    }
  }
}
