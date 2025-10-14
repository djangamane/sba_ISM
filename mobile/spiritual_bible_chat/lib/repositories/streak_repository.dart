import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/streak_state.dart';

class StreakRepository {
  StreakRepository(this._client);

  static const _table = 'streaks';

  final SupabaseClient _client;

  Future<StreakState?> fetch(String userId) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;

      return StreakState(
        currentStreak: (data['current_streak'] as int?) ?? 0,
        longestStreak: (data['longest_streak'] as int?) ?? 0,
        lastCompletedDate: data['last_completed_date'] != null
            ? DateTime.tryParse(data['last_completed_date'] as String)
            : null,
      );
    } catch (error, stackTrace) {
      debugPrint('StreakRepository.fetch failed: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> upsert(String userId, StreakState streak) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'current_streak': streak.currentStreak,
      'longest_streak': streak.longestStreak,
      'last_completed_date': streak.lastCompletedDate?.toIso8601String(),
    };

    try {
      await _client.from(_table).upsert(payload, onConflict: 'user_id');
    } catch (error, stackTrace) {
      debugPrint('StreakRepository.upsert failed: $error\n$stackTrace');
    }
  }

  Future<void> reset(String userId) async {
    try {
      await _client.from(_table).update({
        'current_streak': 0,
        'longest_streak': 0,
        'last_completed_date': null,
      }).eq('user_id', userId);
    } catch (error, stackTrace) {
      debugPrint('StreakRepository.reset failed: $error\n$stackTrace');
    }
  }
}
