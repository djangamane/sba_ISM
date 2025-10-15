import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/premium_state.dart';

const String _premiumEntitlementId = 'premium';

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  bool _configured = false;

  Future<void> configure(String apiKey) async {
    if (_configured) return;

    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
    _configured = true;
  }

  Future<void> logIn(String? appUserId) async {
    if (!_configured) return;
    if (appUserId == null || appUserId.isEmpty) {
      await Purchases.logOut();
    } else {
      await Purchases.logIn(appUserId);
    }
  }

  Future<PremiumState> currentStatus() async {
    if (!_configured) {
      return PremiumState.initial();
    }

    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.all[_premiumEntitlementId];
      final isPremium = entitlement?.isActive ?? false;
      final isTrial = entitlement?.periodType == PeriodType.trial;

      return PremiumState(
        isPremium: isPremium,
        source: entitlement?.productIdentifier,
        expiresAt: entitlement?.expirationDate,
        isTrial: isTrial,
        trialEndsAt: isTrial ? entitlement?.expirationDate : null,
        isLoading: false,
      );
    } on PlatformException catch (error) {
      return PremiumState.initial()
          .copyWith(errorMessage: error.message, isLoading: false);
    }
  }

  Future<bool> purchaseDefaultPackage() async {
    if (!_configured) return false;

    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current ??
          offerings.all.values.firstWhere(
            (element) => element.availablePackages.isNotEmpty,
            orElse: () => throw Exception('No offerings configured in RevenueCat.'),
          );

      final package = offering.monthly ??
          offering.availablePackages.firstWhere(
            (pkg) => pkg.packageType == PackageType.monthly,
            orElse: () => offering.availablePackages.isNotEmpty
                ? offering.availablePackages.first
                : throw Exception('No packages available for purchase.'),
          );

      final info = await Purchases.purchasePackage(package);
      return info.entitlements.active.containsKey(_premiumEntitlementId);
    } on PlatformException {
      rethrow;
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
