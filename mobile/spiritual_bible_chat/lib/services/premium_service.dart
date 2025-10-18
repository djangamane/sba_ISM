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
    await configure();

    final planId = annual ? 'premium_annual' : 'premium_monthly';

    try {
      final apiCheckoutUrl =
          await _paywallService.createStripeCheckoutSession(planId: planId);
      if (apiCheckoutUrl == null) {
        throw Exception('Checkout URL unavailable.');
      }
      final mode = kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
      final launched = await launchUrl(apiCheckoutUrl, mode: mode);
      if (!launched) {
        throw Exception('Unable to open checkout window. Please disable pop-up blockers and try again.');
      }
      return true;
    } catch (error) {
      debugPrint('Backend checkout failed: $error');
      final fallbackUrl = annual ? _annualCheckoutUri : _monthlyCheckoutUri;
      if (fallbackUrl != null) {
        final mode = kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
        final launched = await launchUrl(fallbackUrl, mode: mode);
        if (!launched) {
          throw Exception('Unable to open checkout window. Please disable pop-up blockers and try again.');
        }
        return true;
      }
      rethrow;
    }
  }

  Future<bool> openManageSubscription() async {
    await configure();
    try {
      final portalUrl = await _paywallService.createStripePortalSession();
      if (portalUrl == null) {
        throw Exception('Billing portal unavailable.');
      }
      return await launchUrl(portalUrl, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('Failed to open billing portal: $error');
      throw Exception('Unable to open billing portal right now.');
    }
  }
}
