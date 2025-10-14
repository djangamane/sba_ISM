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
}
