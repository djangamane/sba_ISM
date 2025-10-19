import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class DailyVerse {
  const DailyVerse({
    required this.day,
    required this.reference,
    required this.text,
    required this.themes,
  });

  final int? day;
  final String reference;
  final String text;
  final List<String> themes;

  factory DailyVerse.fromJson(Map<String, dynamic> json) => DailyVerse(
        day: json['day'] as int?,
        reference: json['reference'] as String? ?? '',
        text: json['text'] as String? ?? '',
        themes: (json['theme'] as List<dynamic>?)
                ?.map((value) => value.toString())
                .toList() ??
            const [],
      );

  DailyVerse copyWith({
    int? day,
    String? reference,
    String? text,
    List<String>? themes,
  }) =>
      DailyVerse(
        day: day ?? this.day,
        reference: reference ?? this.reference,
        text: text ?? this.text,
        themes: themes ?? this.themes,
      );
}

class DailyVerseProvider {
  DailyVerseProvider._();

  static List<DailyVerse>? _cache;

  static Future<List<DailyVerse>> _ensureCache() async {
    if (_cache != null) {
      return _cache!;
    }
    final raw = await rootBundle.loadString('assets/daily_verses.json');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    _cache = jsonList
        .map((entry) => DailyVerse.fromJson(entry as Map<String, dynamic>))
        .where((verse) => verse.text.isNotEmpty)
        .toList();
    if (_cache!.isEmpty) {
      _cache = [
        const DailyVerse(
          day: null,
          reference: 'Psalm 46:10',
          text: '“Be still, and know that I am God.”',
          themes: [],
        )
      ];
    }
    return _cache!;
  }

  static Future<DailyVerse> verseForDate(DateTime date) async {
    final verses = await _ensureCache();
    if (verses.isEmpty) {
      return const DailyVerse(
        day: null,
        reference: 'Psalm 46:10',
        text: '“Be still, and know that I am God.”',
        themes: [],
      );
    }
    final normalized = DateTime(date.year, date.month, date.day);
    final index = (normalized.day - 1) % verses.length;
    return verses[index].copyWith(day: normalized.day);
  }
}
