/// Helpers for workout record screens: consistent local wall-clock defaults.
library;

import 'device_clock.dart';

/// Edit: normalize stored instant to local for pickers and labels.
/// New + calendar day passed: use that calendar date with **current device clock time**.
/// New + no calendar: [deviceLocalNow] (OS timezone, avoids UTC-only emulator clocks).
DateTime newWorkoutFormDateTime({
  DateTime? editSource,
  DateTime? calendarDay,
}) {
  if (editSource != null) {
    final e = editSource.toLocal();
    return DateTime(e.year, e.month, e.day, e.hour, e.minute, e.second,
        e.millisecond, e.microsecond);
  }
  final now = deviceLocalNow();
  if (calendarDay != null) {
    final d = calendarDay.toLocal();
    return DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second,
        now.millisecond, now.microsecond);
  }
  return now;
}
