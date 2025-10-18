import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/premium_state.dart';
import '../utils/api_base.dart';

class BackendProfileService {
  const BackendProfileService();

  Future<PremiumState> fetchPremiumState() async {
    final uri = Uri.parse('${apiBaseUrl()}/api/v1/profile');
    final response = await http.get(uri, headers: await authHeaders());

    if (response.statusCode == 401 || response.statusCode == 403) {
      return PremiumState.initial();
    }

    if (response.statusCode >= 400) {
      throw Exception('Unable to load profile (${response.statusCode}).');
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    final premiumRaw = body['premium'];
    final Map<String, dynamic>? premium =
        premiumRaw is Map<String, dynamic> ? premiumRaw : null;

    final trialRaw = premium?['trial'];
    final Map<String, dynamic>? trial =
        trialRaw is Map<String, dynamic> ? trialRaw : null;

    return PremiumState(
      isPremium: premium?['is_active'] == true,
      source: premium?['entitlement_source'] as String?,
      expiresAt: _parseDateTime(premium?['expires_at']),
      isTrial: trial?['is_trial'] == true,
      trialEndsAt: _parseDateTime(trial?['trial_ends_at']),
      isLoading: false,
      planId: premium?['plan_id'] as String?,
      customerId: premium?['customer_id'] as String?,
    );
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
