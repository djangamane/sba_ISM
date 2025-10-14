import 'dart:convert';

enum SpiritualGoal {
  stressRelief,
  learnBible,
  manifestation,
  dailyInspiration,
  other,
}

enum NevilleFamiliarity {
  none,
  curious,
  fan,
}

enum ContentPreference {
  directScripture,
  practicalAdvice,
  guidedPrayer,
  affirmations,
}

enum ReminderSlot { morning, midday, evening, gentle }

class OnboardingProfile {
  const OnboardingProfile({
    required this.goal,
    required this.familiarity,
    required this.contentPreferences,
    required this.reminderSlot,
    required this.wantsStreaks,
    this.isPremium = false,
  });

  final SpiritualGoal goal;
  final NevilleFamiliarity familiarity;
  final List<ContentPreference> contentPreferences;
  final ReminderSlot reminderSlot;
  final bool wantsStreaks;
  final bool isPremium;

  Map<String, Object?> toJson() => {
        'goal': goal.name,
        'familiarity': familiarity.name,
        'contentPreferences': contentPreferences.map((e) => e.name).toList(),
        'reminderSlot': reminderSlot.name,
        'wantsStreaks': wantsStreaks,
        'isPremium': isPremium,
      };

  static OnboardingProfile fromJson(Map<String, Object?> json) =>
      OnboardingProfile(
        goal: SpiritualGoal.values.byName(json['goal'] as String),
        familiarity:
            NevilleFamiliarity.values.byName(json['familiarity'] as String),
        contentPreferences: (json['contentPreferences'] as List<dynamic>)
            .map((value) => ContentPreference.values.byName(value as String))
            .toList(),
        reminderSlot:
            ReminderSlot.values.byName(json['reminderSlot'] as String),
        wantsStreaks: json['wantsStreaks'] as bool,
        isPremium: json['isPremium'] as bool? ?? false,
      );

  static OnboardingProfile? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    return OnboardingProfile.fromJson(
        jsonDecode(encoded) as Map<String, Object?>);
  }

  String encode() => jsonEncode(toJson());

  OnboardingProfile copyWith({
    SpiritualGoal? goal,
    NevilleFamiliarity? familiarity,
    List<ContentPreference>? contentPreferences,
    ReminderSlot? reminderSlot,
    bool? wantsStreaks,
    bool? isPremium,
  }) {
    return OnboardingProfile(
      goal: goal ?? this.goal,
      familiarity: familiarity ?? this.familiarity,
      contentPreferences: contentPreferences ?? this.contentPreferences,
      reminderSlot: reminderSlot ?? this.reminderSlot,
      wantsStreaks: wantsStreaks ?? this.wantsStreaks,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
