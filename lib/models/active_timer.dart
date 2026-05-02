import 'package:uuid/uuid.dart';

class ActiveTimer {
  final String id;
  final String? jobId;
  final double? rateOverride;
  final DateTime startedAt;
  final DateTime? breakStartedAt;
  final int totalBreakSeconds;

  const ActiveTimer({
    required this.id,
    this.jobId,
    this.rateOverride,
    required this.startedAt,
    this.breakStartedAt,
    this.totalBreakSeconds = 0,
  });

  bool get isOnBreak => breakStartedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'rateOverride': rateOverride,
        'startedAt': startedAt.toIso8601String(),
        'breakStartedAt': breakStartedAt?.toIso8601String(),
        'totalBreakSeconds': totalBreakSeconds,
      };

  factory ActiveTimer.fromJson(Map<String, dynamic> json) => ActiveTimer(
        id: json['id'] as String? ?? const Uuid().v4(),
        jobId: json['jobId'] as String?,
        rateOverride: (json['rateOverride'] as num?)?.toDouble(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        breakStartedAt: json['breakStartedAt'] != null
            ? DateTime.parse(json['breakStartedAt'] as String)
            : null,
        totalBreakSeconds: (json['totalBreakSeconds'] as int?) ?? 0,
      );

  ActiveTimer copyWith({
    String? id,
    String? jobId,
    double? rateOverride,
    DateTime? startedAt,
    DateTime? breakStartedAt,
    bool clearBreakStartedAt = false,
    int? totalBreakSeconds,
  }) =>
      ActiveTimer(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        rateOverride: rateOverride ?? this.rateOverride,
        startedAt: startedAt ?? this.startedAt,
        breakStartedAt:
            clearBreakStartedAt ? null : (breakStartedAt ?? this.breakStartedAt),
        totalBreakSeconds: totalBreakSeconds ?? this.totalBreakSeconds,
      );
}
