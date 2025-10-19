import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/api_base.dart';

class PaywallService {
  Future<void> requestDemoUpgrade() async {
    final uri = Uri.parse('${apiBaseUrl()}/api/v1/paywall/grant-demo');
    final response = await http.post(uri, headers: await authHeaders());
    if (response.statusCode >= 400) {
      String message = 'Unable to upgrade at this time.';
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        message = body['error'] as String? ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<Uri?> createStripeCheckoutSession(
      {String planId = 'premium_monthly'}) async {
    final uri = Uri.parse('${apiBaseUrl()}/api/v1/paywall/stripe-checkout');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ...await authHeaders(),
      },
      body: jsonEncode({'planId': planId}),
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final url = body['checkoutUrl'] as String?;
        if (url == null || url.isEmpty) {
          return null;
        }
        return Uri.tryParse(url);
      } catch (error) {
        throw Exception('Unexpected checkout response: $error');
      }
    }

    if (response.statusCode == 404 || response.statusCode == 501) {
      throw Exception(
          'Stripe checkout is not yet configured. Please contact support or use the demo upgrade.');
    }

    String message = 'Unable to start checkout.';
    try {
      final Map<String, dynamic> body = jsonDecode(response.body);
      message = body['error'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<Uri?> createStripePortalSession() async {
    final uri = Uri.parse('${apiBaseUrl()}/api/v1/stripe/portal');
    final response = await http.post(uri, headers: await authHeaders());
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final url = body['portalUrl'] as String?;
        if (url == null || url.isEmpty) {
          return null;
        }
        return Uri.tryParse(url);
      } catch (error) {
        throw Exception('Unexpected portal response: $error');
      }
    }

    String message = 'Unable to open billing portal.';
    try {
      final Map<String, dynamic> body = jsonDecode(response.body);
      message = body['error'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<void> logPaywallEvent(String event,
      {String? trigger, bool swallowErrors = true}) async {
    final uri = Uri.parse('${apiBaseUrl()}/api/v1/paywall/log');
    try {
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...await authHeaders(),
        },
        body: jsonEncode({
          'event': event,
          if (trigger != null) 'trigger': trigger,
        }),
      );
    } catch (error) {
      if (!swallowErrors) rethrow;
    }
  }
}
