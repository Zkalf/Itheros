// The pure parts of the pace report (plan 0066): medians, the table, the
// read of the last report and the mark on a big move. No sim runs here.
import 'package:test/test.dart';

import '../tool/pace_report.dart';

const _intro = '# Pace reports\n\nThe intro.\n';

String _report(String heading, Map<String, String> values) => [
  '## $heading',
  '',
  '| Measure | Value | Change |',
  '|---|---|---|',
  for (final e in values.entries) '| ${e.key} | ${e.value} | +0.0 |',
  '',
].join('\n');

void main() {
  group('the median', () {
    test('of an odd list is the middle value', () {
      expect(medianDays([30, 10, 20], missed: 106), 20);
    });

    test('of an even list is the mean of the two middle values', () {
      expect(medianDays([10, 40, 20, 30], missed: 106), 25);
    });

    test('counts a missed seed as the missed day', () {
      expect(medianDays([100, null, null], missed: 106), 106);
      expect(medianDays([90, 100, null, null], missed: 121), 110.5);
    });
  });

  group('the last report', () {
    test('is read from the newest report in the file', () {
      final file = [
        _intro,
        _report('2026-11-12 · abc1234 · 32 seeds', {
          'Mixed L30': '91.0',
          'Fight HP taken': '11.5%',
        }),
        _report('2026-11-01 · def5678 · 32 seeds', {'Mixed L30': '80.0'}),
      ].join('\n');
      expect(lastValues(file), {'Mixed L30': 91.0, 'Fight HP taken': 11.5});
    });

    test('is empty when the file has no report', () {
      expect(lastValues(_intro), isEmpty);
    });
  });

  group('the change', () {
    const day = PaceRow('Mixed L30', 90, day: true);

    test('of 5 days or more gets a mark', () {
      expect(changeCell(day, 85), '+5.0 ⚠');
      expect(changeCell(day, 96), '-6.0 ⚠');
    });

    test('of 4 days gets no mark', () {
      expect(changeCell(day, 86), '+4.0');
    });

    test('of a fight number never gets a mark', () {
      const rounds = PaceRow('Fight rounds', 20, day: false);
      expect(changeCell(rounds, 8), '+12.0');
    });

    test('is "new" for a measure that the last report lacks', () {
      expect(changeCell(day, null), 'new');
    });
  });

  group('the table', () {
    const rows = [
      PaceRow('Mixed L30', 90, day: true),
      PaceRow('Fight HP taken', 11.5, day: false, percent: true),
    ];

    test('of a first report has no change column', () {
      final table = reportTable('2026-11-11 · abc1234 · 32 seeds', rows, {});
      expect(table, contains('| Measure | Value |\n'));
      expect(table, isNot(contains('Change')));
      expect(table, contains('| Mixed L30 | 90.0 |'));
      expect(table, contains('| Fight HP taken | 11.5% |'));
    });

    test('of a later report shows the change', () {
      final table = reportTable('2026-11-11 · abc1234 · 32 seeds', rows, {
        'Mixed L30': 84,
        'Fight HP taken': 11,
      });
      expect(table, contains('| Measure | Value | Change |'));
      expect(table, contains('| Mixed L30 | 90.0 | +6.0 ⚠ |'));
      expect(table, contains('| Fight HP taken | 11.5% | +0.5 |'));
    });

    test('goes above the older reports, under the intro', () {
      final old = _report('2026-11-01 · def5678 · 32 seeds', {
        'Mixed L30': '80.0',
      });
      final file = withReport('$_intro\n$old', '## new\n\n| a |\n');
      expect(file.indexOf('The intro.'), lessThan(file.indexOf('## new')));
      expect(file.indexOf('## new'), lessThan(file.indexOf('## 2026-11-01')));
    });

    test('of the first report goes under the intro', () {
      final file = withReport(_intro, '## new\n\n| a |\n');
      expect(file, startsWith(_intro));
      expect(file, contains('## new'));
    });

    test('goes first in a file without an intro', () {
      final file = withReport('## old\n\n| b |\n', '## new\n\n| a |\n');
      expect(file.indexOf('## new'), lessThan(file.indexOf('## old')));
    });
  });
}
