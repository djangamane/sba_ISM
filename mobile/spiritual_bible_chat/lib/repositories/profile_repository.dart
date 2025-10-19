import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_profile.dart';

const Map<SpiritualGoal, String> _goalToDb = {
  SpiritualGoal.stressRelief: 'stress_relief',
  SpiritualGoal.learnBible: 'learn_bible',
  SpiritualGoal.manifestation: 'manifestation',
  SpiritualGoal.dailyInspiration: 'daily_inspiration',
  SpiritualGoal.other: 'other',
};

const Map<String, SpiritualGoal> _goalFromDb = {
  'stress_relief': SpiritualGoal.stressRelief,
  'learn_bible': SpiritualGoal.learnBible,
  'manifestation': SpiritualGoal.manifestation,
  'daily_inspiration': SpiritualGoal.dailyInspiration,
  'other': SpiritualGoal.other,
};

const Map<NevilleFamiliarity, String> _familiarityToDb = {
  NevilleFamiliarity.none: 'none',
  NevilleFamiliarity.curious: 'curious',
  NevilleFamiliarity.fan: 'fan',
};

const Map<String, NevilleFamiliarity> _familiarityFromDb = {
  'none': NevilleFamiliarity.none,
  'curious': NevilleFamiliarity.curious,
  'fan': NevilleFamiliarity.fan,
};

const Map<ContentPreference, String> _contentPreferenceToDb = {
  ContentPreference.directScripture: 'direct_scripture',
  ContentPreference.practicalAdvice: 'practical_advice',
  ContentPreference.guidedPrayer: 'guided_prayer',
  ContentPreference.affirmations: 'affirmations',
};

const Map<String, ContentPreference> _contentPreferenceFromDb = {
  'direct_scripture': ContentPreference.directScripture,
  'practical_advice': ContentPreference.practicalAdvice,
  'guided_prayer': ContentPreference.guidedPrayer,
  'affirmations': ContentPreference.affirmations,
};

const Map<ReminderSlot, String> _reminderSlotToDb = {
  ReminderSlot.morning: 'morning',
  ReminderSlot.midday: 'midday',
  ReminderSlot.evening: 'evening',
  ReminderSlot.gentle: 'gentle',
};

const Map<String, ReminderSlot> _reminderSlotFromDb = {
  'morning': ReminderSlot.morning,
  'midday': ReminderSlot.midday,
  'evening': ReminderSlot.evening,
  'gentle': ReminderSlot.gentle,
};

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

      final preferences = (data['content_preferences'] as List<dynamic>?) ?? [];

      final profile = OnboardingProfile(
        goal: _parseGoal(data['goal'] as String?),
        familiarity: _parseFamiliarity(data['familiarity'] as String?),
        contentPreferences: preferences
            .map((value) => _parseContentPreference(value as String?))
            .whereType<ContentPreference>()
            .toList(),
        reminderSlot: _parseReminderSlot(data['reminder_slot'] as String?),
        wantsStreaks: (data['wants_streaks'] as bool?) ?? true,
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
      'goal': _goalToDb[profile.goal],
      'familiarity': _familiarityToDb[profile.familiarity],
      'content_preferences': profile.contentPreferences
          .map((preference) => _contentPreferenceToDb[preference])
          .whereType<String>()
          .toList(),
      'reminder_slot': _reminderSlotToDb[profile.reminderSlot],
      'wants_streaks': profile.wantsStreaks,
      'next_reminder_at': nextReminder?.toIso8601String(),
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

SpiritualGoal _parseGoal(String? value) {
  if (value == null) return SpiritualGoal.dailyInspiration;
  return _goalFromDb[value] ?? SpiritualGoal.dailyInspiration;
}

NevilleFamiliarity _parseFamiliarity(String? value) {
  if (value == null) return NevilleFamiliarity.none;
  return _familiarityFromDb[value] ?? NevilleFamiliarity.none;
}

ContentPreference? _parseContentPreference(String? value) {
  if (value == null) return null;
  return _contentPreferenceFromDb[value];
}

ReminderSlot _parseReminderSlot(String? value) {
  if (value == null) return ReminderSlot.morning;
  return _reminderSlotFromDb[value] ?? ReminderSlot.morning;
}
