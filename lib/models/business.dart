class Business {
  final String id;
  final String? name;
  final String? company;
  final String? phone;
  final String? address;

  const Business({
    required this.id,
    this.name,
    this.company,
    this.phone,
    this.address,
  });

  String get displayName => company ?? name ?? '—';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'company': company,
        'phone': phone,
        'address': address,
      };

  factory Business.fromJson(Map<String, dynamic> j) => Business(
        id: j['id'] as String,
        name: j['name'] as String?,
        company: j['company'] as String?,
        phone: j['phone'] as String?,
        address: j['address'] as String?,
      );
}
