import 'package:uuid/uuid.dart';

class ActiveTimer {
  final String id;
  final String? jobId;
  final double? rateOverride;
  final DateTime startedAt;

  const ActiveTimer({
    required this.id,
    this.jobId,
    this.rateOverride,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'rateOverride': rateOverride,
        'startedAt': startedAt.toIso8601String(),
      };

  factory ActiveTimer.fromJson(Map<String, dynamic> json) => ActiveTimer(
        id: json['id'] as String? ?? Uuid().v4(),
        jobId: json['jobId'] as String?,
        rateOverride: (json['rateOverride'] as num?)?.toDouble(),
        startedAt: DateTime.parse(json['startedAt'] as String),
      );
}
