class EventPartner {
  const EventPartner({
    required this.id,
    required this.eventId,
    required this.name,
    required this.tier,
    this.logoUrl,
    this.websiteUrl,
    required this.sortOrder,
  });

  final String id;
  final String eventId;
  final String name;
  final String tier;
  final String? logoUrl;
  final String? websiteUrl;
  final int sortOrder;

  factory EventPartner.fromSupabase(Map<String, dynamic> row) => EventPartner(
        id: row['id']?.toString() ?? '',
        eventId: row['event_id']?.toString() ?? '',
        name: row['name']?.toString() ?? '',
        tier: row['tier']?.toString() ?? 'partner',
        logoUrl: row['logo_url']?.toString(),
        websiteUrl: row['website_url']?.toString(),
        sortOrder: int.tryParse(row['sort_order']?.toString() ?? '') ?? 0,
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'event_id': eventId,
        'name': name,
        'tier': tier,
        'logo_url': logoUrl,
        'website_url': websiteUrl,
        'sort_order': sortOrder,
      };

  EventPartner copyWith({
    String? id,
    String? eventId,
    String? name,
    String? tier,
    String? logoUrl,
    String? websiteUrl,
    int? sortOrder,
  }) =>
      EventPartner(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        tier: tier ?? this.tier,
        logoUrl: logoUrl ?? this.logoUrl,
        websiteUrl: websiteUrl ?? this.websiteUrl,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
