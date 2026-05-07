import '../models/job.dart';
import '../models/time_entry.dart';

List<Job> sortJobsByRecent(List<Job> jobs, List<TimeEntry> entries) {
  String? latestDate(String jobId) {
    final dates = entries
        .where((e) => e.jobId == jobId)
        .map((e) => e.date)
        .toList();
    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  final withEntries = <({Job job, String date})>[];
  final withoutEntries = <Job>[];

  for (final job in jobs) {
    final d = latestDate(job.id);
    if (d != null) {
      withEntries.add((job: job, date: d));
    } else {
      withoutEntries.add(job);
    }
  }

  withEntries.sort((a, b) => b.date.compareTo(a.date));
  withoutEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return [...withEntries.map((x) => x.job), ...withoutEntries];
}

typedef JobGroup = ({String letter, List<Job> jobs});

List<JobGroup> groupJobsAlphabetically(List<Job> jobs) {
  final map = <String, List<Job>>{};

  for (final job in jobs) {
    final first = job.name.isNotEmpty ? job.name[0].toUpperCase() : '#';
    final letter = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
    map.putIfAbsent(letter, () => []).add(job);
  }

  for (final list in map.values) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  final letters = map.keys.toList()..sort((a, b) {
    if (a == '#') return 1;
    if (b == '#') return -1;
    return a.compareTo(b);
  });

  return letters.map((l) => (letter: l, jobs: map[l]!)).toList();
}
