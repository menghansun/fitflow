/// Resolves "now" using the OS timezone database via [timezone] + [flutter_timezone].
/// Falls back to [DateTime.now] if initialization fails (e.g. unknown zone id).
library;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _deviceTzInitialized = false;

/// Call once from [main] after [WidgetsFlutterBinding.ensureInitialized].
Future<void> ensureDeviceTimezoneInitialized() async {
  if (_deviceTzInitialized) return;
  tzdata.initializeTimeZones();
  try {
    final id = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(id));
    _deviceTzInitialized = true;
  } catch (_) {
    _deviceTzInitialized = false;
  }
}

/// Wall-clock [DateTime] (local components, not UTC) for form defaults and labels.
DateTime deviceLocalNow() {
  if (_deviceTzInitialized) {
    final t = tz.TZDateTime.now(tz.local);
    return DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
      t.microsecond,
    );
  }
  return DateTime.now();
}
