class VenueTable {
  const VenueTable({
    required this.id,
    required this.venueId,
    required this.eventId,
    required this.name,
    this.zone,
    required this.capacity,
    required this.price,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String venueId;
  final String eventId;
  final String name;
  final String? zone;
  final int capacity;
  final double price;
  final String currency;
  final String status;
  final DateTime createdAt;

  factory VenueTable.fromSupabase(Map<String, dynamic> row) => VenueTable(
        id: _string(row['id']),
        venueId: _string(row['venue_id']),
        eventId: _string(row['event_id']),
        name: _string(row['name']),
        zone: _nullable(row['zone']),
        capacity: _int(row['capacity']),
        price: _double(row['price']),
        currency: _string(row['currency'], 'USD'),
        status: _string(row['status'], 'available'),
        createdAt: _date(row['created_at']),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'venue_id': venueId,
        'event_id': eventId,
        'name': name,
        'zone': zone,
        'capacity': capacity,
        'price': price,
        'currency': currency,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  VenueTable copyWith({
    String? id,
    String? venueId,
    String? eventId,
    String? name,
    String? zone,
    int? capacity,
    double? price,
    String? currency,
    String? status,
    DateTime? createdAt,
  }) =>
      VenueTable(
        id: id ?? this.id,
        venueId: venueId ?? this.venueId,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        zone: zone ?? this.zone,
        capacity: capacity ?? this.capacity,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}

String _string(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;

String? _nullable(Object? value) => value?.toString();

int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

double _double(Object? value) =>
    double.tryParse(value?.toString() ?? '') ?? 0.0;

DateTime _date(Object? value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
