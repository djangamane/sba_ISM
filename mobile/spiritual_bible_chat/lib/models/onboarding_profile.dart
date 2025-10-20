import 'dart:convert';

enum IntentionFocus {
  innerCalm,
  sacredStudy,
  imaginalCreation,
  dailySpark,
  other,
}

enum GuidanceStyle {
  scripturePassages,
  practicalWisdom,
  guidedPrayer,
  affirmationsDeclarations,
  sacredHistory,
}

enum ClimateFeeling {
  grounded,
  concerned,
  overwhelmed,
  grieving,
  hopefulButTired,
}

enum JusticeTension {
  personal,
  familyCommunity,
  workplace,
  nationalGlobal,
  spiritualInstitutions,
  unsure,
}

enum ProtectionFocus {
  racialTrauma,
  politicalTurmoil,
  violenceInNews,
  helplessness,
  other,
}

enum SolidarityPractice {
  communityOrganizing,
  prayerOrRitual,
  teachingEducating,
  financialSupport,
  storytellingArt,
  seekingGuidance,
}

enum InnerAnchorFocus {
  bodyBreath,
  mindHeart,
  ancestorsLineage,
  creativityVoice,
  sacredAction,
}

enum ReminderSlot { morning, midday, evening, gentle }

class OnboardingProfile {
  const OnboardingProfile({
    required this.intention,
    required this.guidanceStyles,
    required this.innerAnchor,
    required this.reminderSlot,
    required this.wantsStreaks,
    required this.climateFeeling,
    required this.justiceTensions,
    required this.protectionFocus,
    required this.solidarityPractices,
    required this.collectiveTruth,
    this.intentionOther,
    this.protectionOther,
    this.isPremium = false,
  });

  final IntentionFocus intention;
  final String? intentionOther;
  final List<GuidanceStyle> guidanceStyles;
  final InnerAnchorFocus innerAnchor;
  final ReminderSlot reminderSlot;
  final bool wantsStreaks;
  final ClimateFeeling climateFeeling;
  final List<JusticeTension> justiceTensions;
  final List<ProtectionFocus> protectionFocus;
  final String? protectionOther;
  final List<SolidarityPractice> solidarityPractices;
  final String collectiveTruth;
  final bool isPremium;

  Map<String, Object?> toJson() => {
        'intention': intention.name,
        'intentionOther': intentionOther,
        'guidanceStyles': guidanceStyles.map((e) => e.name).toList(),
        'innerAnchor': innerAnchor.name,
        'reminderSlot': reminderSlot.name,
        'wantsStreaks': wantsStreaks,
        'climateFeeling': climateFeeling.name,
        'justiceTensions': justiceTensions.map((e) => e.name).toList(),
        'protectionFocus': protectionFocus.map((e) => e.name).toList(),
        'protectionOther': protectionOther,
        'solidarityPractices': solidarityPractices.map((e) => e.name).toList(),
        'collectiveTruth': collectiveTruth,
        'isPremium': isPremium,
      };

  static OnboardingProfile fromJson(Map<String, Object?> json) {
    IntentionFocus parseIntention(String? value) {
      if (value == null || value.isEmpty) return IntentionFocus.innerCalm;
      switch (value) {
        case 'stress_relief':
        case 'stressRelief':
          return IntentionFocus.innerCalm;
        case 'learn_bible':
        case 'learnBible':
          return IntentionFocus.sacredStudy;
        case 'manifestation':
          return IntentionFocus.imaginalCreation;
        case 'daily_inspiration':
        case 'dailyInspiration':
          return IntentionFocus.dailySpark;
        case 'other':
          return IntentionFocus.other;
        default:
          return IntentionFocus.values.firstWhere(
            (item) => item.name == value,
            orElse: () => IntentionFocus.innerCalm,
          );
      }
    }

    List<T> parseList<T>(
      List<dynamic>? raw,
      List<T> Function(List<String>) converter,
    ) {
      if (raw == null) return const [];
      return converter(raw.map((e) => e.toString()).toList());
    }

    T parseEnum<T>(
      String? value,
      List<T> values,
      String Function(T) nameExtractor,
      T fallback,
    ) {
      if (value == null) return fallback;
      return values.firstWhere(
        (item) => nameExtractor(item) == value,
        orElse: () => fallback,
      );
    }

    List<GuidanceStyle> parseGuidance(List<dynamic>? raw) {
      if (raw == null) {
        return const [GuidanceStyle.scripturePassages];
      }
      return raw
          .map((value) {
            final stringValue = value.toString();
            switch (stringValue) {
              case 'direct_scripture':
              case 'directScripture':
                return GuidanceStyle.scripturePassages;
              case 'practical_advice':
              case 'practicalAdvice':
                return GuidanceStyle.practicalWisdom;
              case 'guided_prayer':
              case 'guidedPrayer':
                return GuidanceStyle.guidedPrayer;
              case 'affirmations':
                return GuidanceStyle.affirmationsDeclarations;
              default:
                return GuidanceStyle.values.firstWhere(
                  (item) => item.name == stringValue,
                  orElse: () => GuidanceStyle.scripturePassages,
                );
            }
          })
          .toSet()
          .toList();
    }

    List<JusticeTension> parseJustice(List<dynamic>? raw) {
      if (raw == null || raw.isEmpty) return const [];
      return raw
          .map((value) => JusticeTension.values.firstWhere(
                (item) => item.name == value,
                orElse: () => JusticeTension.unsure,
              ))
          .toSet()
          .toList();
    }

    List<ProtectionFocus> parseProtection(List<dynamic>? raw) {
      if (raw == null || raw.isEmpty) return const [];
      return raw
          .map((value) => ProtectionFocus.values.firstWhere(
                (item) => item.name == value,
                orElse: () => ProtectionFocus.other,
              ))
          .toSet()
          .toList();
    }

    List<SolidarityPractice> parseSolidarity(List<dynamic>? raw) {
      if (raw == null || raw.isEmpty) return const [];
      return raw
          .map((value) => SolidarityPractice.values.firstWhere(
                (item) => item.name == value,
                orElse: () => SolidarityPractice.seekingGuidance,
              ))
          .toSet()
          .toList();
    }

    final intention = parseIntention(
      (json['intention'] ?? json['goal']) as String?,
    );

    final guidanceStyles = parseGuidance(
      (json['guidanceStyles'] ?? json['contentPreferences']) as List<dynamic>?,
    );

    final innerAnchor = parseEnum<InnerAnchorFocus>(
      json['innerAnchor'] as String?,
      InnerAnchorFocus.values,
      (value) => value.name,
      InnerAnchorFocus.bodyBreath,
    );

    final reminder = parseEnum<ReminderSlot>(
      (json['reminderSlot'] ?? json['reminder_slot']) as String?,
      ReminderSlot.values,
      (value) => value.name,
      ReminderSlot.morning,
    );

    final rawClimate =
        (json['climateFeeling'] ?? json['familiarity']) as String?;
    final climate = () {
      switch (rawClimate) {
        case 'none':
        case 'grounded':
          return ClimateFeeling.grounded;
        case 'curious':
        case 'concerned':
          return ClimateFeeling.concerned;
        case 'fan':
        case 'hopefulButTired':
          return ClimateFeeling.hopefulButTired;
        case 'overwhelmed':
          return ClimateFeeling.overwhelmed;
        case 'grieving':
          return ClimateFeeling.grieving;
        default:
          if (rawClimate == null) return ClimateFeeling.grounded;
          return ClimateFeeling.values.firstWhere(
            (value) => value.name == rawClimate,
            orElse: () => ClimateFeeling.grounded,
          );
      }
    }();

    final justice = parseJustice(json['justiceTensions'] as List<dynamic>?);
    final protection =
        parseProtection(json['protectionFocus'] as List<dynamic>?);
    final solidarity =
        parseSolidarity(json['solidarityPractices'] as List<dynamic>?);

    final wantsStreaks =
        (json['wantsStreaks'] ?? json['wants_streaks']) as bool? ?? true;

    final collectiveTruth = (json['collectiveTruth'] as String?)?.trim() ?? '';

    return OnboardingProfile(
      intention: intention,
      intentionOther: json['intentionOther'] as String?,
      guidanceStyles: guidanceStyles.isEmpty
          ? [GuidanceStyle.scripturePassages]
          : guidanceStyles,
      innerAnchor: innerAnchor,
      reminderSlot: reminder,
      wantsStreaks: wantsStreaks,
      climateFeeling: climate,
      justiceTensions: justice,
      protectionFocus: protection,
      protectionOther: json['protectionOther'] as String?,
      solidarityPractices: solidarity,
      collectiveTruth: collectiveTruth,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  static OnboardingProfile? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    final Map<String, Object?> json =
        jsonDecode(encoded) as Map<String, Object?>;
    return OnboardingProfile.fromJson(json);
  }

  String encode() => jsonEncode(toJson());

  OnboardingProfile copyWith({
    IntentionFocus? intention,
    String? intentionOther,
    List<GuidanceStyle>? guidanceStyles,
    InnerAnchorFocus? innerAnchor,
    ReminderSlot? reminderSlot,
    bool? wantsStreaks,
    ClimateFeeling? climateFeeling,
    List<JusticeTension>? justiceTensions,
    List<ProtectionFocus>? protectionFocus,
    String? protectionOther,
    List<SolidarityPractice>? solidarityPractices,
    String? collectiveTruth,
    bool? isPremium,
  }) {
    return OnboardingProfile(
      intention: intention ?? this.intention,
      intentionOther: intentionOther ?? this.intentionOther,
      guidanceStyles: guidanceStyles ?? this.guidanceStyles,
      innerAnchor: innerAnchor ?? this.innerAnchor,
      reminderSlot: reminderSlot ?? this.reminderSlot,
      wantsStreaks: wantsStreaks ?? this.wantsStreaks,
      climateFeeling: climateFeeling ?? this.climateFeeling,
      justiceTensions: justiceTensions ?? this.justiceTensions,
      protectionFocus: protectionFocus ?? this.protectionFocus,
      protectionOther: protectionOther ?? this.protectionOther,
      solidarityPractices: solidarityPractices ?? this.solidarityPractices,
      collectiveTruth: collectiveTruth ?? this.collectiveTruth,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
