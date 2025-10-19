import 'package:flutter/material.dart';

import '../models/onboarding_profile.dart';

String reminderLabel(ReminderSlot slot) {
  switch (slot) {
    case ReminderSlot.morning:
      return 'Sunrise centering';
    case ReminderSlot.midday:
      return 'Midday reset';
    case ReminderSlot.evening:
      return 'Twilight wind-down';
    case ReminderSlot.gentle:
      return 'Only if I slip the rhythm';
  }
}

/// Returns the next scheduled reminder time based on the selected slot.
///
/// This is a stub implementation that simply computes the next local
/// occurrence of a preset time-of-day for each slot. Integrate with your
/// notification scheduler when ready.
DateTime nextReminderDate(ReminderSlot slot, {DateTime? from}) {
  final reference = from ?? DateTime.now();
  final times = <ReminderSlot, TimeOfDay>{
    ReminderSlot.morning: const TimeOfDay(hour: 7, minute: 30),
    ReminderSlot.midday: const TimeOfDay(hour: 12, minute: 30),
    ReminderSlot.evening: const TimeOfDay(hour: 20, minute: 0),
    ReminderSlot.gentle: const TimeOfDay(hour: 21, minute: 15),
  };

  final targetTime = times[slot] ?? const TimeOfDay(hour: 9, minute: 0);

  DateTime scheduled = DateTime(
    reference.year,
    reference.month,
    reference.day,
    targetTime.hour,
    targetTime.minute,
  );

  if (!scheduled.isAfter(reference)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  return scheduled;
}

String describeReminderDate(BuildContext context, DateTime? dateTime) {
  if (dateTime == null) {
    return 'No reminder set yet';
  }
  final localizations = MaterialLocalizations.of(context);
  final timeString = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime),
    alwaysUse24HourFormat: false,
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

  String dayLabel;
  if (scheduledDay == today) {
    dayLabel = 'today';
  } else if (scheduledDay == today.add(const Duration(days: 1))) {
    dayLabel = 'tomorrow';
  } else {
    dayLabel = localizations.formatShortDate(dateTime);
  }

  return '$dayLabel at $timeString';
}
