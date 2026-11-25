class ArticleModel {
  final String id;
  final String name;
  final String brand; // Scribe, Norma, etc.
  final String classification; // Archivo o empaque, Artículos de escritura, etc.
  final double price; // Precio único

  ArticleModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.classification,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'classification': classification,
      'price': price,
    };
  }

  factory ArticleModel.fromMap(String id, Map<String, dynamic> map) {
    return ArticleModel(
      id: id,
      name: map['name'] ?? '',
      brand: map['brand'] ?? 'Genérica',
      classification: map['classification'] ?? 'General',
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}
