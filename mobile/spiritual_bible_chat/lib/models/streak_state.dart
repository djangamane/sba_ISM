import 'dart:convert';

class StreakState {
  const StreakState({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
  });

  factory StreakState.initial() => const StreakState(
        currentStreak: 0,
        longestStreak: 0,
        lastCompletedDate: null,
      );

  factory StreakState.decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return StreakState.initial();
    }
    final json = jsonDecode(encoded) as Map<String, Object?>;
    return StreakState.fromJson(json);
  }

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  bool get hasCompletedToday {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    return lastCompletedDate!.year == now.year &&
        lastCompletedDate!.month == now.month &&
        lastCompletedDate!.day == now.day;
  }

  Map<String, Object?> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  static StreakState fromJson(Map<String, Object?> json) => StreakState(
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastCompletedDate: json['lastCompletedDate'] != null
            ? DateTime.tryParse(json['lastCompletedDate'] as String)
            : null,
      );

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
  }) =>
      StreakState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      );
}
