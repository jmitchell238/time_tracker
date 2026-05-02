import 'package:csv/csv.dart';

class CsvRow {
  final String jobName;
  final String date;
  final String startTime;
  final String endTime;
  final double hours;
  final double? rate;
  final String description;

  const CsvRow({
    required this.jobName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.hours,
    this.rate,
    required this.description,
  });
}

class CsvImportService {
  static List<CsvRow> parse(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(eol: '\n').convert(normalized);
    if (rows.length < 2) return [];

    final header = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
    final jobIdx     = header.indexOf('job');
    final inIdx      = header.indexOf('clocked in');
    final outIdx     = header.indexOf('clocked out');
    final durIdx     = header.indexOf('duration');
    final rateIdx    = header.indexOf('hourly rate');
    final commentIdx = header.indexOf('comment');

    if (jobIdx < 0 || inIdx < 0 || durIdx < 0) return [];

    final results = <CsvRow>[];
    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) continue;
      if (row.length <= jobIdx) continue;

      final jobName = row[jobIdx].toString().trim();
      if (jobName.isEmpty) continue;

      try {
        final (date, startTime) = _parseDateTime(row[inIdx].toString());

        final String endTime;
        if (outIdx >= 0 && outIdx < row.length && row[outIdx].toString().trim().isNotEmpty) {
          final (_, et) = _parseDateTime(row[outIdx].toString());
          endTime = et;
        } else {
          endTime = '00:00';
        }

        final hours = _parseDuration(row[durIdx].toString());
        final description = commentIdx >= 0 && commentIdx < row.length
            ? row[commentIdx].toString().trim()
            : '';

        double? rate;
        if (rateIdx >= 0 && rateIdx < row.length) {
          final rawRate = row[rateIdx].toString().replaceAll(r'$', '').trim();
          final parsed = double.tryParse(rawRate);
          if (parsed != null && parsed > 0) rate = parsed;
        }

        results.add(CsvRow(
          jobName: jobName,
          date: date,
          startTime: startTime,
          endTime: endTime,
          hours: hours,
          rate: rate,
          description: description,
        ));
      } catch (_) {
        continue;
      }
    }
    return results;
  }

  // Parses "M/D/YY H:MM AM/PM" → ('yyyy-MM-dd', 'HH:mm')
  static (String, String) _parseDateTime(String raw) {
    final trimmed = raw.trim();
    final spaceIdx = trimmed.indexOf(' ');
    if (spaceIdx < 0) throw FormatException('bad datetime: $raw');

    final datePart = trimmed.substring(0, spaceIdx);
    final timePart = trimmed.substring(spaceIdx + 1).trim();

    final dp = datePart.split('/');
    if (dp.length < 3) throw FormatException('bad date: $datePart');
    final month = int.parse(dp[0]);
    final day   = int.parse(dp[1]);
    int year    = int.parse(dp[2]);
    if (year < 100) year += 2000;

    final lastSpace = timePart.lastIndexOf(' ');
    final timeOnly  = lastSpace >= 0 ? timePart.substring(0, lastSpace) : timePart;
    final amPm      = lastSpace >= 0 ? timePart.substring(lastSpace + 1).toUpperCase() : '';

    final tp  = timeOnly.split(':');
    if (tp.length < 2) throw FormatException('bad time: $timeOnly');
    int hour  = int.parse(tp[0]);
    final min = int.parse(tp[1]);

    if (amPm == 'PM' && hour != 12) hour += 12;
    if (amPm == 'AM' && hour == 12) hour = 0;

    final dateStr = '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
    final timeStr = '${hour.toString().padLeft(2, '0')}:'
        '${min.toString().padLeft(2, '0')}';
    return (dateStr, timeStr);
  }

  // Parses "H:MM" or decimal hours → double
  static double _parseDuration(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h + m / 60.0;
    }
    return double.tryParse(trimmed) ?? 0.0;
  }
}
