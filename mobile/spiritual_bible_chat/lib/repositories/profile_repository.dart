import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_profile.dart';

class ProfileRecord {
  ProfileRecord(
      {required this.profile, this.nextReminderAt, this.premiumExpiresAt});

  final OnboardingProfile profile;
  final DateTime? nextReminderAt;
  final DateTime? premiumExpiresAt;
}

class ProfileRepository {
  ProfileRepository(this._client);

  static const _table = 'profiles';

  final SupabaseClient _client;

  Future<ProfileRecord?> fetch(String userId) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;

      final goalValue = data['goal'] as String?;
      OnboardingProfile? profile;

      if (goalValue != null && goalValue.trim().startsWith('{')) {
        try {
          profile = OnboardingProfile.fromJson(
            jsonDecode(goalValue) as Map<String, dynamic>,
          );
        } catch (error, stackTrace) {
          debugPrint(
              'ProfileRepository.decode profile failed: $error\n$stackTrace');
        }
      }

      profile ??= OnboardingProfile(
        intention: IntentionFocus.dailySpark,
        guidanceStyles: const [GuidanceStyle.scripturePassages],
        innerAnchor: InnerAnchorFocus.bodyBreath,
        reminderSlot: _parseReminderSlot(data['reminder_slot'] as String?),
        wantsStreaks: (data['wants_streaks'] as bool?) ?? true,
        climateFeeling: ClimateFeeling.grounded,
        justiceTensions: const [],
        protectionFocus: const [],
        solidarityPractices: const [],
        collectiveTruth: '',
        intentionOther: null,
        protectionOther: null,
        isPremium: (data['is_premium'] as bool?) ?? false,
      );

      final nextReminder = data['next_reminder_at'] != null
          ? DateTime.tryParse(data['next_reminder_at'] as String)
          : null;

      final premiumExpiresAt = data['premium_expires_at'] != null
          ? DateTime.tryParse(data['premium_expires_at'] as String)
          : null;

      return ProfileRecord(
        profile: profile,
        nextReminderAt: nextReminder,
        premiumExpiresAt: premiumExpiresAt,
      );
    } catch (error, stackTrace) {
      debugPrint('ProfileRepository.fetch failed: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> upsert(
    String userId,
    OnboardingProfile profile, {
    DateTime? nextReminder,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'goal': profile.encode(),
      'reminder_slot': profile.reminderSlot.name,
      'wants_streaks': profile.wantsStreaks,
      'next_reminder_at': nextReminder?.toIso8601String(),
      'is_premium': profile.isPremium,
    };

    try {
      await _client.from(_table).upsert(payload, onConflict: 'user_id');
    } catch (error, stackTrace) {
      debugPrint('ProfileRepository.upsert failed: $error\n$stackTrace');
    }
  }

  Future<void> updateReminder(String userId, DateTime nextReminder) async {
    try {
      await _client
          .from(_table)
          .update({'next_reminder_at': nextReminder.toIso8601String()}).eq(
              'user_id', userId);
    } catch (error, stackTrace) {
      debugPrint(
          'ProfileRepository.updateReminder failed: $error\n$stackTrace');
    }
  }
}

ReminderSlot _parseReminderSlot(String? value) {
  if (value == null) return ReminderSlot.morning;
  return ReminderSlot.values.firstWhere(
    (slot) => slot.name == value,
    orElse: () => ReminderSlot.morning,
  );
}
