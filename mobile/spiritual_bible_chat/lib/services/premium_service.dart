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
  Uri? _monthlyCheckoutUri;
  Uri? _annualCheckoutUri;

  Future<void> configure() async {
    // No-op for web build; Stripe configuration handled via backend.
    final stripeKey = dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ??
        const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
    if (stripeKey.isEmpty) {
      debugPrint(
          'Stripe publishable key missing. Premium checkout will use demo upgrade fallback.');
    }

    final monthlyUrl = dotenv.maybeGet('STRIPE_CHECKOUT_MONTHLY') ??
        const String.fromEnvironment('STRIPE_CHECKOUT_MONTHLY', defaultValue: '');
    final annualUrl = dotenv.maybeGet('STRIPE_CHECKOUT_ANNUAL') ??
        const String.fromEnvironment('STRIPE_CHECKOUT_ANNUAL', defaultValue: '');

    _monthlyCheckoutUri = monthlyUrl.isNotEmpty ? Uri.tryParse(monthlyUrl) : null;
    _annualCheckoutUri = annualUrl.isNotEmpty ? Uri.tryParse(annualUrl) : null;
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

  Future<bool> startPurchaseFlow({bool annual = false}) async {
    try {
      final checkoutUrl = annual ? _annualCheckoutUri : _monthlyCheckoutUri;
      if (checkoutUrl != null) {
        final launched =
            await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
        return launched;
      }

      final apiCheckoutUrl =
          await _paywallService.createStripeCheckoutSession(planId: annual ? 'premium_annual' : 'premium_monthly');
      if (apiCheckoutUrl == null) {
        return false;
      }
      final launched =
          await launchUrl(apiCheckoutUrl, mode: LaunchMode.externalApplication);
      return launched;
    } catch (error) {
      debugPrint('Stripe checkout launch failed: $error');
      rethrow;
    }
  }
}
