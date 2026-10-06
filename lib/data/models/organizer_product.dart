class OrganizerProduct {
  const OrganizerProduct({
    required this.id,
    required this.eventId,
    required this.organizerId,
    required this.name,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.imageUrl,
    this.stockQuantity,
  });

  final String id;
  final String eventId;
  final String organizerId;
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final String currency;
  final int? stockQuantity;
  final bool isActive;
  final DateTime createdAt;

  bool get isAvailable =>
      isActive && (stockQuantity == null || stockQuantity! > 0);

  factory OrganizerProduct.fromJson(Map<String, dynamic> json) =>
      OrganizerProduct(
        id: json['id'].toString(),
        eventId: json['event_id'].toString(),
        organizerId: json['organizer_id'].toString(),
        name: json['name']?.toString() ?? 'Product',
        description: json['description']?.toString(),
        imageUrl: json['image_url']?.toString(),
        price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
        currency: json['currency']?.toString() ?? 'USD',
        stockQuantity: json['stock_quantity'] == null
            ? null
            : int.tryParse(json['stock_quantity'].toString()),
        isActive: json['is_active'] == true,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class ProductPreorder {
  const ProductPreorder({
    required this.id,
    required this.productId,
    required this.eventId,
    required this.organizerId,
    required this.userId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String productId;
  final String eventId;
  final String organizerId;
  final String userId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String currency;
  final String status;
  final DateTime createdAt;
  final String? notes;

  double get total => unitPrice * quantity;

  factory ProductPreorder.fromJson(Map<String, dynamic> json) {
    final product = json['organizer_products'];
    final productName = product is Map
        ? product['name']?.toString() ?? 'Product preorder'
        : json['product_name']?.toString() ?? 'Product preorder';
    return ProductPreorder(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      eventId: json['event_id'].toString(),
      organizerId: json['organizer_id'].toString(),
      userId: json['user_id'].toString(),
      productName: productName,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      notes: json['notes']?.toString(),
    );
  }
}
