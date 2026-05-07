const _kDefaultPaymentMethods = ['Cash', 'Check', 'Direct Deposit', 'Venmo'];

class AppSettings {
  final double defaultRate;
  final String? billingName;
  final String? billingAddress;
  final String? billingPhone;
  final List<String> paymentMethods;
  /// One of 'dark', 'light', 'system'.
  final String themeMode;
  /// Index of the tab to open on launch: 0=Dashboard, 1=Jobs, 2=Log, 3=Invoices, 4=More.
  final int defaultTab;
  /// One of 'recent' or 'az'.
  final String defaultJobsSort;

  const AppSettings({
    this.defaultRate = 35.0,
    this.billingName,
    this.billingAddress,
    this.billingPhone,
    this.paymentMethods = const ['Cash', 'Check', 'Direct Deposit', 'Venmo'],
    this.themeMode = 'system',
    this.defaultTab = 0,
    this.defaultJobsSort = 'recent',
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
    String? themeMode,
    int? defaultTab,
    String? defaultJobsSort,
  }) =>
      AppSettings(
        defaultRate: defaultRate ?? this.defaultRate,
        billingName: clearBillingName ? null : (billingName ?? this.billingName),
        billingAddress: clearBillingAddress ? null : (billingAddress ?? this.billingAddress),
        billingPhone: clearBillingPhone ? null : (billingPhone ?? this.billingPhone),
        paymentMethods: paymentMethods ?? this.paymentMethods,
        themeMode: themeMode ?? this.themeMode,
        defaultTab: defaultTab ?? this.defaultTab,
        defaultJobsSort: defaultJobsSort ?? this.defaultJobsSort,
      );

  Map<String, dynamic> toJson() => {
        'defaultRate': defaultRate,
        'billingName': billingName,
        'billingAddress': billingAddress,
        'billingPhone': billingPhone,
        'paymentMethods': paymentMethods,
        'themeMode': themeMode,
        'defaultTab': defaultTab,
        'defaultJobsSort': defaultJobsSort,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        defaultRate: (j['defaultRate'] as num?)?.toDouble() ?? 35.0,
        billingName: j['billingName'] as String?,
        billingAddress: j['billingAddress'] as String?,
        billingPhone: j['billingPhone'] as String?,
        paymentMethods: j['paymentMethods'] != null
            ? List<String>.from(j['paymentMethods'] as List)
            : _kDefaultPaymentMethods,
        themeMode: j['themeMode'] as String? ?? 'system',
        defaultTab: (j['defaultTab'] as int?) ?? 0,
        defaultJobsSort: j['defaultJobsSort'] as String? ?? 'recent',
      );
}
