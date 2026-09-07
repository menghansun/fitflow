/// Device clock helpers for workout form defaults.
library;

/// Kept as an async hook so callers do not need to change if timezone handling
/// is reintroduced later.
Future<void> ensureDeviceTimezoneInitialized() async {
  return;
}

/// Wall-clock [DateTime] for form defaults and labels.
DateTime deviceLocalNow() => DateTime.now();
