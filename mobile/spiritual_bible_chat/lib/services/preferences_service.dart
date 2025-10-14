import 'package:shared_preferences/shared_preferences.dart';

import '../models/onboarding_profile.dart';
import '../models/streak_state.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  static const _profileKey = 'onboarding_profile';
  static const _streakKey = 'streak_state';
  static const _nextReminderKey = 'next_reminder_at';

  final SharedPreferences _prefs;

  static Future<PreferencesService> instance() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  OnboardingProfile? loadProfile() {
    final encoded = _prefs.getString(_profileKey);
    return OnboardingProfile.decode(encoded);
  }

  StreakState loadStreak() {
    final encoded = _prefs.getString(_streakKey);
    return StreakState.decode(encoded);
  }

  DateTime? loadNextReminder() {
    final value = _prefs.getString(_nextReminderKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> saveProfile(OnboardingProfile profile) async {
    await _prefs.setString(_profileKey, profile.encode());
  }

  Future<void> saveStreak(StreakState streak) async {
    await _prefs.setString(_streakKey, streak.encode());
  }

  Future<void> saveNextReminder(DateTime dateTime) async {
    await _prefs.setString(_nextReminderKey, dateTime.toIso8601String());
  }

  Future<void> clearProfile() async {
    await _prefs.remove(_profileKey);
  }

  Future<void> clearStreak() async {
    await _prefs.remove(_streakKey);
  }

  Future<void> clearNextReminder() async {
    await _prefs.remove(_nextReminderKey);
  }
}
