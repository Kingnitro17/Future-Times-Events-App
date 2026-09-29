class FtService {
  const FtService({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.imageUrl,
    required this.basePrice,
    required this.currency,
    required this.unit,
    required this.depositPercent,
    required this.totalQuantity,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String? description;
  final String category;
  final String? imageUrl;
  final double basePrice;
  final String currency;
  final String unit;
  final int depositPercent;
  final int totalQuantity;
  final bool isActive;
  final int sortOrder;

  factory FtService.fromSupabase(Map<String, dynamic> row) => FtService(
        id: row['id']?.toString() ?? '',
        name: row['name']?.toString() ?? '',
        description: row['description']?.toString(),
        category: row['category']?.toString() ?? '',
        imageUrl: row['image_url']?.toString(),
        basePrice: _asDouble(row['base_price']),
        currency: row['currency']?.toString() ?? 'USD',
        unit: row['unit']?.toString() ?? 'day',
        depositPercent: _asInt(row['deposit_percent'], fallback: 30),
        totalQuantity: _asInt(row['total_quantity'], fallback: 1),
        isActive: row['is_active'] == true,
        sortOrder: _asInt(row['sort_order']),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'image_url': imageUrl,
        'base_price': basePrice,
        'currency': currency,
        'unit': unit,
        'deposit_percent': depositPercent,
        'total_quantity': totalQuantity,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  FtService copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? imageUrl,
    double? basePrice,
    String? currency,
    String? unit,
    int? depositPercent,
    int? totalQuantity,
    bool? isActive,
    int? sortOrder,
  }) =>
      FtService(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        basePrice: basePrice ?? this.basePrice,
        currency: currency ?? this.currency,
        unit: unit ?? this.unit,
        depositPercent: depositPercent ?? this.depositPercent,
        totalQuantity: totalQuantity ?? this.totalQuantity,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  static double _asDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static int _asInt(Object? value, {int fallback = 0}) =>
      value is int ? value : int.tryParse('$value') ?? fallback;
}
