/// Local calendar days as `yyyy-mm-dd` keys.
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Local midnight at the start of [key]'s day.
DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

/// Local midnight [days] after [day]'s start (handles DST and month ends).
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);
