class Job {
  final String id;
  final String name;
  final String description;
  final double? rate;
  final bool isArchived;
  final DateTime createdAt;

  const Job({
    required this.id,
    required this.name,
    required this.description,
    this.rate,
    required this.isArchived,
    required this.createdAt,
  });

  Job copyWith({
    String? name,
    String? description,
    double? rate,
    bool clearRate = false,
    bool? isArchived,
  }) {
    return Job(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      rate: clearRate ? null : (rate ?? this.rate),
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rate': rate,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        rate: (j['rate'] as num?)?.toDouble(),
        isArchived: j['isArchived'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
