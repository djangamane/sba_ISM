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

    final premium =
        body['premium'] is Map ? body['premium'] as Map<String, dynamic> : null;
    final trial = premium?['trial'] is Map
        ? premium?['trial'] as Map<String, dynamic>
        : null;

    return PremiumState(
      isPremium: premium?['is_active'] == true,
      source: premium?['entitlement_source'] as String?,
      expiresAt: _parseDateTime(premium?['expires_at']),
      isTrial: trial?['is_trial'] == true,
      trialEndsAt: _parseDateTime(trial?['trial_ends_at']),
      isLoading: false,
    );
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
