/// Where real-world steps come from.
///
/// Totals must be de-duplicated across devices (phone + watch), which is what
/// Health Connect's aggregate does (spec 0001 amendment 1).
abstract interface class StepSource {
  /// Total steps walked in `[start, end)`. Throws [StepSourceException] if
  /// the total can't be read; callers then apply nothing.
  Future<int> stepsBetween(DateTime start, DateTime end);
}

/// Availability and permission for a [StepSource].
abstract interface class StepPermissions {
  Future<bool> isAvailable();
  Future<bool> hasPermission();

  /// Shows the system permission prompt. Returns whether access was granted.
  Future<bool> requestPermission();
}

class StepSourceException implements Exception {
  StepSourceException(this.message);

  final String message;

  @override
  String toString() => 'StepSourceException: $message';
}
