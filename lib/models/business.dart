class Business {
  final String id;
  final String? name;
  final String? company;
  final String? phone;

  const Business({
    required this.id,
    this.name,
    this.company,
    this.phone,
  });

  String get displayName => company ?? name ?? '—';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'company': company,
        'phone': phone,
      };

  factory Business.fromJson(Map<String, dynamic> j) => Business(
        id: j['id'] as String,
        name: j['name'] as String?,
        company: j['company'] as String?,
        phone: j['phone'] as String?,
      );
}
