import 'step_source.dart';

/// In-memory step source for tests: step records with timestamps, which can
/// arrive late (backdated), like Garmin uploads.
class FakeStepSource implements StepSource, StepPermissions {
  FakeStepSource({
    this.available = true,
    this.granted = true,
    this.grantOnRequest = true,
  });

  bool available;
  bool granted;
  bool grantOnRequest;

  /// When set, the next [stepsBetween] call throws.
  bool failNext = false;

  final _records = <(DateTime, int)>[];

  void walk(DateTime at, int steps) => _records.add((at, steps));

  void clear() => _records.clear();

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<bool> requestPermission() async => granted = grantOnRequest;

  @override
  Future<int> stepsBetween(DateTime start, DateTime end) async {
    if (failNext) {
      failNext = false;
      throw StepSourceException('fake failure');
    }
    var total = 0;
    for (final (at, steps) in _records) {
      if (!at.isBefore(start) && at.isBefore(end)) total += steps;
    }
    return total;
  }
}
