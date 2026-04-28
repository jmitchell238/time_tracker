class Invoice {
  final String id;
  final String number;
  final String createdAt;
  final String? sentAt;
  final List<String> entryIds;
  final double totalHours;
  final double totalAmount;
  final String notes;

  const Invoice({
    required this.id,
    required this.number,
    required this.createdAt,
    this.sentAt,
    required this.entryIds,
    required this.totalHours,
    required this.totalAmount,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'createdAt': createdAt,
        'sentAt': sentAt,
        'entryIds': entryIds,
        'totalHours': totalHours,
        'totalAmount': totalAmount,
        'notes': notes,
      };

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id'] as String,
        number: j['number'] as String,
        createdAt: j['createdAt'] as String,
        sentAt: j['sentAt'] as String?,
        entryIds: List<String>.from(j['entryIds'] as List),
        totalHours: (j['totalHours'] as num).toDouble(),
        totalAmount: (j['totalAmount'] as num).toDouble(),
        notes: j['notes'] as String? ?? '',
      );
}
