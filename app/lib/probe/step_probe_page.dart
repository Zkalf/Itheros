// M1 step probe (plan 0001): proves Health Connect delivers steps on the test
// phone, and compares the de-duplicated aggregate with the plugin's
// manual-entry-filtered sum, which reads raw records without de-duplication.
// Replaced by the game UI in M5.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/health.dart';

class StepProbePage extends StatefulWidget {
  const StepProbePage({super.key});

  @override
  State<StepProbePage> createState() => _StepProbePageState();
}

class _StepProbePageState extends State<StepProbePage> {
  final Health _health = Health();
  Timer? _timer;

  String _status = 'Starting…';
  bool _authorized = false;
  _Window? _today;
  _Window? _lastHour;
  List<_SourceRow> _sources = [];
  DateTime? _refreshedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await _health.configure();
      final sdk = await _health.getHealthConnectSdkStatus();
      if (sdk != HealthConnectSdkStatus.sdkAvailable) {
        setState(() => _status = 'Health Connect not available: $sdk');
        return;
      }
      final granted = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      setState(() {
        _authorized = granted ?? false;
        _status = 'Health Connect available';
      });
      if (_authorized) _startRefreshing();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final ok = await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      setState(() => _authorized = ok);
      if (ok) _startRefreshing();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  void _startRefreshing() {
    _refresh();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final today = await _readWindow(midnight, now);
      final lastHour = await _readWindow(
        now.subtract(const Duration(hours: 1)),
        now,
      );
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: midnight,
        endTime: now,
      );
      final bySource = <String, _SourceRow>{};
      for (final p in points) {
        final key = '${p.sourceName} · ${p.recordingMethod.name}';
        final steps = (p.value as NumericHealthValue).numericValue.round();
        final row = bySource.putIfAbsent(key, () => _SourceRow(key));
        row.records++;
        row.steps += steps;
      }
      setState(() {
        _today = today;
        _lastHour = lastHour;
        _sources = bySource.values.toList()
          ..sort((a, b) => b.steps.compareTo(a.steps));
        _refreshedAt = now;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<_Window> _readWindow(DateTime start, DateTime end) async {
    final aggregate = await _health.getTotalStepsInInterval(start, end);
    final noManual = await _health.getTotalStepsInInterval(
      start,
      end,
      includeManualEntry: false,
    );
    return _Window(aggregate, noManual);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Step probe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_status, style: text.bodyLarge),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: text.bodyMedium?.copyWith(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          if (!_authorized)
            FilledButton(
              onPressed: _requestPermission,
              child: const Text('Allow step access'),
            )
          else ...[
            _WindowCard(title: 'Today', window: _today),
            _WindowCard(title: 'Last hour', window: _lastHour),
            const SizedBox(height: 16),
            Text('Records today by source', style: text.titleMedium),
            if (_sources.isEmpty) const Text('No records yet.'),
            for (final s in _sources)
              ListTile(
                dense: true,
                title: Text(s.key),
                trailing: Text('${s.steps} steps / ${s.records} records'),
              ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _refresh,
              child: const Text('Refresh'),
            ),
            if (_refreshedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Refreshed ${TimeOfDay.fromDateTime(_refreshedAt!).format(context)}'
                  ' · auto every 30 s · Health Connect batches about once a minute',
                  style: text.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Window {
  _Window(this.aggregate, this.noManual);

  /// Health Connect aggregate: de-duplicated across sources, includes manual entries.
  final int? aggregate;

  /// Plugin's filtered sum: excludes manual entries, but is not de-duplicated.
  final int? noManual;
}

class _SourceRow {
  _SourceRow(this.key);

  final String key;
  int records = 0;
  int steps = 0;
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({required this.title, required this.window});

  final String title;
  final _Window? window;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${window?.aggregate ?? '–'} steps',
              style: text.headlineMedium,
            ),
            Text(
              'Aggregate (de-duplicated). Without manual entries: '
              '${window?.noManual ?? '–'}',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
