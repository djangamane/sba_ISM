import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/premium_state.dart';
import 'backend_profile_service.dart';
import 'revenuecat_service.dart';

class PremiumService {
  PremiumService._();

  static final PremiumService instance = PremiumService._();

  final ValueNotifier<PremiumState> state =
      ValueNotifier<PremiumState>(PremiumState.initial());

  final BackendProfileService _backendProfileService =
      const BackendProfileService();
  bool _configured = false;

  Future<void> configure() async {
    if (_configured) return;

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      debugPrint('RevenueCat not configured: unsupported platform.');
      _configured = false;
      return;
    }

    final apiKey = dotenv.maybeGet('REVENUECAT_PUBLIC_API_KEY') ??
        const String.fromEnvironment('REVENUECAT_PUBLIC_API_KEY', defaultValue: '');

    if (apiKey.isEmpty) {
      debugPrint(
          'RevenueCat SDK key missing. Premium features will not initialize.');
      return;
    }

    await RevenueCatService.instance.configure(apiKey);
    _configured = true;
  }

  Future<void> logIn(String? userId) async {
    if (!_configured) {
      await configure();
    }

    await RevenueCatService.instance.logIn(userId);
    await refreshStatus();
  }

  Future<void> logOut() async {
    if (!_configured) return;
    await RevenueCatService.instance.logIn(null);
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

    String? rcError;
    if (_configured) {
      final rcState = await RevenueCatService.instance.currentStatus();
      rcError = rcState.errorMessage;
      if (combined == null) {
        combined = rcState;
      } else {
        combined = combined.copyWith(
          isPremium: combined.isPremium || rcState.isPremium,
          source: combined.source ?? rcState.source,
          expiresAt: combined.expiresAt ?? rcState.expiresAt,
          isTrial: combined.isTrial || rcState.isTrial,
          trialEndsAt: combined.trialEndsAt ?? rcState.trialEndsAt,
        );
      }
    }

    state.value = (combined ?? PremiumState.initial()).copyWith(
      isLoading: false,
      errorMessage: failure?.toString() ?? rcError,
    );
  }

  Future<bool> startPurchaseFlow() async {
    if (!_configured) {
      await configure();
    }

    if (!_configured) {
      return false;
    }

    final successful = await RevenueCatService.instance.purchaseDefaultPackage();
    await refreshStatus();
    return successful;
  }
}
