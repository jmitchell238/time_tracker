class TimeEntry {
  final String id;
  final String jobId;
  final String date;
  final String startTime;
  final String endTime;
  final double hours;
  final String description;
  final String? invoiceId;

  const TimeEntry({
    required this.id,
    required this.jobId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.hours,
    required this.description,
    this.invoiceId,
  });

  TimeEntry copyWith({
    String? jobId,
    String? date,
    String? startTime,
    String? endTime,
    double? hours,
    String? description,
    String? invoiceId,
    bool clearInvoice = false,
  }) {
    return TimeEntry(
      id: id,
      jobId: jobId ?? this.jobId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      invoiceId: clearInvoice ? null : (invoiceId ?? this.invoiceId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'hours': hours,
        'description': description,
        'invoiceId': invoiceId,
      };

  factory TimeEntry.fromJson(Map<String, dynamic> j) => TimeEntry(
        id: j['id'] as String,
        jobId: j['jobId'] as String,
        date: j['date'] as String,
        startTime: j['startTime'] as String? ?? '00:00',
        endTime: j['endTime'] as String? ?? '00:00',
        hours: (j['hours'] as num).toDouble(),
        description: j['description'] as String? ?? '',
        invoiceId: j['invoiceId'] as String?,
      );
}
