class MenuItem {
  const MenuItem({
    required this.id,
    required this.venueId,
    required this.eventId,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.stock,
    required this.createdAt,
  });

  final String id;
  final String venueId;
  final String eventId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String? category;
  final String? imageUrl;
  final bool isAvailable;
  final int stock;
  final DateTime createdAt;

  factory MenuItem.fromSupabase(Map<String, dynamic> row) => MenuItem(
        id: _string(row['id']),
        venueId: _string(row['venue_id']),
        eventId: _string(row['event_id']),
        name: _string(row['name']),
        description: _nullable(row['description']),
        price: _double(row['price']),
        currency: _string(row['currency'], 'USD'),
        category: _nullable(row['category']),
        imageUrl: _nullable(row['image_url']),
        isAvailable: row['is_available'] == true,
        stock: _int(row['stock']),
        createdAt: _date(row['created_at']),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'venue_id': venueId,
        'event_id': eventId,
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'category': category,
        'image_url': imageUrl,
        'is_available': isAvailable,
        'stock': stock,
        'created_at': createdAt.toIso8601String(),
      };

  MenuItem copyWith({
    String? id,
    String? venueId,
    String? eventId,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    int? stock,
    DateTime? createdAt,
  }) =>
      MenuItem(
        id: id ?? this.id,
        venueId: venueId ?? this.venueId,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        isAvailable: isAvailable ?? this.isAvailable,
        stock: stock ?? this.stock,
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
