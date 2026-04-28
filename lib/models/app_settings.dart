class AppSettings {
  final double defaultRate;

  const AppSettings({this.defaultRate = 35.0});

  AppSettings copyWith({double? defaultRate}) =>
      AppSettings(defaultRate: defaultRate ?? this.defaultRate);

  Map<String, dynamic> toJson() => {'defaultRate': defaultRate};

  factory AppSettings.fromJson(Map<String, dynamic> j) =>
      AppSettings(defaultRate: (j['defaultRate'] as num?)?.toDouble() ?? 35.0);
}
