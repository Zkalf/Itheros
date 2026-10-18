import 'package:health/health.dart';

import 'step_source.dart';

/// Steps from Health Connect's de-duplicated aggregate. Never pass
/// `includeManualEntry: false`: the plugin then sums raw records without
/// de-duplication and double-counts phone + watch (see CLAUDE.md).
class HealthConnectStepSource implements StepSource, StepPermissions {
  HealthConnectStepSource([Health? health]) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];
  static const _access = [HealthDataAccess.READ];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> isAvailable() async {
    await _configure();
    return _health.isHealthConnectAvailable();
  }

  @override
  Future<bool> hasPermission() async {
    await _configure();
    return await _health.hasPermissions(_types, permissions: _access) ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await _configure();
    return _health.requestAuthorization(_types, permissions: _access);
  }

  @override
  Future<int> stepsBetween(DateTime start, DateTime end) async {
    if (!end.isAfter(start)) return 0;
    await _configure();
    final total = await _health.getTotalStepsInInterval(start, end);
    if (total == null) {
      throw StepSourceException('Health Connect returned no step total');
    }
    return total;
  }
}
