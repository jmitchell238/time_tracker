class Job {
  final String id;
  final String name;
  final String description;
  final double? rate;
  final bool isArchived;
  final DateTime createdAt;
  final String? businessId;
  final String? categoryId;

  const Job({
    required this.id,
    required this.name,
    required this.description,
    this.rate,
    required this.isArchived,
    required this.createdAt,
    this.businessId,
    this.categoryId,
  });

  Job copyWith({
    String? name,
    String? description,
    double? rate,
    bool clearRate = false,
    bool? isArchived,
    String? businessId,
    bool clearBusinessId = false,
    String? categoryId,
    bool clearCategoryId = false,
  }) {
    return Job(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      rate: clearRate ? null : (rate ?? this.rate),
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      businessId: clearBusinessId ? null : (businessId ?? this.businessId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rate': rate,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'businessId': businessId,
        'categoryId': categoryId,
      };

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        rate: (j['rate'] as num?)?.toDouble(),
        isArchived: j['isArchived'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        businessId: j['businessId'] as String?,
        categoryId: j['categoryId'] as String?,
      );
}
