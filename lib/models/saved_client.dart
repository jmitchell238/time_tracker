class SavedClient {
  final String id;
  final String? name;
  final String? company;
  final String? phone;

  const SavedClient({
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

  factory SavedClient.fromJson(Map<String, dynamic> j) => SavedClient(
        id: j['id'] as String,
        name: j['name'] as String?,
        company: j['company'] as String?,
        phone: j['phone'] as String?,
      );
}
