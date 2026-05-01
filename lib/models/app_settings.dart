const _kDefaultPaymentMethods = ['Cash', 'Check', 'Direct Deposit', 'Venmo'];

class AppSettings {
  final double defaultRate;
  final String? billingName;
  final String? billingAddress;
  final String? billingPhone;
  final List<String> paymentMethods;

  const AppSettings({
    this.defaultRate = 35.0,
    this.billingName,
    this.billingAddress,
    this.billingPhone,
    this.paymentMethods = const ['Cash', 'Check', 'Direct Deposit', 'Venmo'],
  });

  AppSettings copyWith({
    double? defaultRate,
    String? billingName,
    bool clearBillingName = false,
    String? billingAddress,
    bool clearBillingAddress = false,
    String? billingPhone,
    bool clearBillingPhone = false,
    List<String>? paymentMethods,
  }) =>
      AppSettings(
        defaultRate: defaultRate ?? this.defaultRate,
        billingName: clearBillingName ? null : (billingName ?? this.billingName),
        billingAddress: clearBillingAddress ? null : (billingAddress ?? this.billingAddress),
        billingPhone: clearBillingPhone ? null : (billingPhone ?? this.billingPhone),
        paymentMethods: paymentMethods ?? this.paymentMethods,
      );

  Map<String, dynamic> toJson() => {
        'defaultRate': defaultRate,
        'billingName': billingName,
        'billingAddress': billingAddress,
        'billingPhone': billingPhone,
        'paymentMethods': paymentMethods,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        defaultRate: (j['defaultRate'] as num?)?.toDouble() ?? 35.0,
        billingName: j['billingName'] as String?,
        billingAddress: j['billingAddress'] as String?,
        billingPhone: j['billingPhone'] as String?,
        paymentMethods: j['paymentMethods'] != null
            ? List<String>.from(j['paymentMethods'] as List)
            : _kDefaultPaymentMethods,
      );
}
