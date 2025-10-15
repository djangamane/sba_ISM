import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String apiBaseUrl() {
  final fromEnv = dotenv.maybeGet('API_BASE_URL') ??
      const String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }

  final scheme = kIsWeb ? Uri.base.scheme : 'http';
  final host = kIsWeb
      ? Uri.base.host
      : (defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost');
  return '$scheme://$host:4000';
}

Future<Map<String, String>> authHeaders() async {
  final session = Supabase.instance.client.auth.currentSession;
  final token = session?.accessToken;
  return token != null ? {'Authorization': 'Bearer $token'} : {};
}
