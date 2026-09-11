class Invoice {
  final String id;
  final String number;
  final String createdAt;
  final String? sentAt;
  final List<String> entryIds;
  final List<String> expenseIds;
  final double totalHours;
  final double totalAmount;
  final double expensesTotal;
  final String notes;
  final String? clientName;
  final String? clientCompany;
  final String? clientPhone;
  final String? clientAddress;
  final String? billedBy;
  final String? paidAt;        // 'YYYY-MM-DD' — null means unpaid
  final String? paymentMethod; // 'Cash', 'Check', etc.

  const Invoice({
    required this.id,
    required this.number,
    required this.createdAt,
    this.sentAt,
    required this.entryIds,
    this.expenseIds = const [],
    required this.totalHours,
    required this.totalAmount,
    this.expensesTotal = 0,
    required this.notes,
    this.clientName,
    this.clientCompany,
    this.clientPhone,
    this.clientAddress,
    this.billedBy,
    this.paidAt,
    this.paymentMethod,
  });

  bool get isPaid => paidAt != null;

  Invoice copyWith({
    String? number,
    String? notes,
    String? clientName,
    bool clearClientName = false,
    String? clientCompany,
    bool clearClientCompany = false,
    String? clientPhone,
    bool clearClientPhone = false,
    String? clientAddress,
    bool clearClientAddress = false,
    String? billedBy,
    bool clearBilledBy = false,
    String? paidAt,
    bool clearPaidAt = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
  }) {
    return Invoice(
      id: id,
      number: number ?? this.number,
      createdAt: createdAt,
      sentAt: sentAt,
      entryIds: entryIds,
      expenseIds: expenseIds,
      totalHours: totalHours,
      totalAmount: totalAmount,
      expensesTotal: expensesTotal,
      notes: notes ?? this.notes,
      clientName: clearClientName ? null : (clientName ?? this.clientName),
      clientCompany: clearClientCompany ? null : (clientCompany ?? this.clientCompany),
      clientPhone: clearClientPhone ? null : (clientPhone ?? this.clientPhone),
      clientAddress: clearClientAddress ? null : (clientAddress ?? this.clientAddress),
      billedBy: clearBilledBy ? null : (billedBy ?? this.billedBy),
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
      paymentMethod: clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'createdAt': createdAt,
        'sentAt': sentAt,
        'entryIds': entryIds,
        'expenseIds': expenseIds,
        'totalHours': totalHours,
        'totalAmount': totalAmount,
        'expensesTotal': expensesTotal,
        'notes': notes,
        'clientName': clientName,
        'clientCompany': clientCompany,
        'clientPhone': clientPhone,
        'clientAddress': clientAddress,
        'billedBy': billedBy,
        'paidAt': paidAt,
        'paymentMethod': paymentMethod,
      };

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id'] as String,
        number: j['number'] as String,
        createdAt: j['createdAt'] as String,
        sentAt: j['sentAt'] as String?,
        entryIds: List<String>.from(j['entryIds'] as List),
        expenseIds: j['expenseIds'] != null
            ? List<String>.from(j['expenseIds'] as List)
            : const [],
        totalHours: (j['totalHours'] as num).toDouble(),
        totalAmount: (j['totalAmount'] as num).toDouble(),
        expensesTotal: (j['expensesTotal'] as num?)?.toDouble() ?? 0,
        notes: j['notes'] as String? ?? '',
        clientName: j['clientName'] as String?,
        clientCompany: j['clientCompany'] as String?,
        clientPhone: j['clientPhone'] as String?,
        clientAddress: j['clientAddress'] as String?,
        billedBy: j['billedBy'] as String?,
        paidAt: j['paidAt'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
      );
}
