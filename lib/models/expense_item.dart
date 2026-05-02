class ExpenseItem {
  final String id;
  final String description;
  final double amount;
  final String date;
  final String purchasedBy; // 'James' or 'Whitney'
  final String? invoiceId;
  final String? businessId;
  final String? jobId;

  const ExpenseItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.purchasedBy,
    this.invoiceId,
    this.businessId,
    this.jobId,
  });

  ExpenseItem copyWith({
    String? description,
    double? amount,
    String? date,
    String? purchasedBy,
    String? invoiceId,
    bool clearInvoiceId = false,
    String? businessId,
    bool clearBusinessId = false,
    String? jobId,
    bool clearJobId = false,
  }) {
    return ExpenseItem(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      purchasedBy: purchasedBy ?? this.purchasedBy,
      invoiceId: clearInvoiceId ? null : (invoiceId ?? this.invoiceId),
      businessId: clearBusinessId ? null : (businessId ?? this.businessId),
      jobId: clearJobId ? null : (jobId ?? this.jobId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date,
        'purchasedBy': purchasedBy,
        'invoiceId': invoiceId,
        'businessId': businessId,
        'jobId': jobId,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
        id: j['id'] as String,
        description: j['description'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: j['date'] as String,
        purchasedBy: j['purchasedBy'] as String? ?? 'James',
        invoiceId: j['invoiceId'] as String?,
        businessId: j['businessId'] as String?,
        jobId: j['jobId'] as String?,
      );
}
