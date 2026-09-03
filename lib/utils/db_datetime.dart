/// Helpers for timestamps returned by Postgres (timestamptz) via PostgREST / Supabase.
library;

/// Writes an app [DateTime] (any timezone) as UTC RFC3339 for [timestamptz] columns.
/// Using local-only ISO strings can confuse Postgres / PostgREST and causes date drift on re-fetch.
String workoutInstantToIsoUtc(DateTime d) => d.toUtc().toIso8601String();

/// Parses JSON values from Supabase (usually ISO strings; occasionally other types).
DateTime parseSupabaseTimestamptz(dynamic raw) {
  if (raw == null) return DateTime.now();
  if (raw is DateTime) {
    return raw.toLocal();
  }
  final s = raw.toString().trim();
  if (s.isEmpty) return DateTime.now();
  return parseTimestamptzToLocal(s);
}

/// Parses an ISO-8601 timestamp from the API into a local [DateTime] for UI and Hive.
///
/// Dart's [DateTime.parse] treats strings **without** an explicit timezone as **local**
/// wall-clock time. PostgREST sometimes omits the trailing `Z` while the value is still
/// UTC in the database, which shifts the instant by the device's UTC offset (e.g. −8h in China).
DateTime parseTimestamptzToLocal(String? raw) {
  if (raw == null || raw.isEmpty) {
    return DateTime.now();
  }
  final s = raw.trim();
  final parsed = DateTime.parse(s);

  if (!_stringLooksTimezoneNaive(s)) {
    return parsed.toLocal();
  }

  // Naive string: interpret numeric components as UTC wall clock, then convert to local.
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).toLocal();
}

/// Normalizes an instant to the device's **local** calendar date at 00:00.
/// Use for UI day keys and month grouping so UTC-stored [DateTime]s match the grid.
DateTime calendarDayLocal(DateTime instant) {
  final loc = instant.toLocal();
  return DateTime(loc.year, loc.month, loc.day);
}

bool _stringLooksTimezoneNaive(String s) {
  if (s.endsWith('Z') || s.endsWith('z')) return false;
  // Offset forms: +08:00, +0800, +08, -05:30
  if (RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s)) return false;
  if (RegExp(r'[+-]\d{4}$').hasMatch(s)) return false;
  if (RegExp(r'[+-]\d{2}$').hasMatch(s)) return false;
  return true;
}
