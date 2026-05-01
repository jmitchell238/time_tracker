class ExpenseItem {
  final String id;
  final String description;
  final double amount;
  final String date;
  final String purchasedBy; // 'James' or 'Whitney'
  final String? invoiceId;

  const ExpenseItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.purchasedBy,
    this.invoiceId,
  });

  ExpenseItem copyWith({
    String? description,
    double? amount,
    String? date,
    String? purchasedBy,
    String? invoiceId,
    bool clearInvoiceId = false,
  }) {
    return ExpenseItem(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      purchasedBy: purchasedBy ?? this.purchasedBy,
      invoiceId: clearInvoiceId ? null : (invoiceId ?? this.invoiceId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date,
        'purchasedBy': purchasedBy,
        'invoiceId': invoiceId,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
        id: j['id'] as String,
        description: j['description'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: j['date'] as String,
        purchasedBy: j['purchasedBy'] as String? ?? 'James',
        invoiceId: j['invoiceId'] as String?,
      );
}
