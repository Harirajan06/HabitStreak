class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String? category;
  final int? stockQty;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.stockQty,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final int? priceCents = json['price_cents'] is int
        ? json['price_cents'] as int
        : (json['price_cents'] is String ? int.tryParse(json['price_cents']) : null);

    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (priceCents ?? 0) / 100.0,
      imageUrl: json['image_url'] as String?,
      category: json['category_id']?.toString(),
      stockQty: json['stock_qty'] is int ? json['stock_qty'] as int : null,
    );
  }
}
