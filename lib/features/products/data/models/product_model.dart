class ProductModel {
  final int? id;
  final int? categoryId;
  final String? categoryName; // Helper join dari tabel categories
  final String name;
  final String? description;
  final int costPrice;
  final int sellingPrice;
  final int stock;
  final String unit; // Satuan produk: porsi, pcs, gelas, cup, buah, dll.
  final bool isBundle; // True jika merupakan menu paket / bundling stock
  final bool isActive;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    this.id,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    this.costPrice = 0,
    required this.sellingPrice,
    this.stock = 0,
    this.unit = 'porsi',
    this.isBundle = false,
    this.isActive = true,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'unit': unit,
      'is_active': isActive ? 1 : 0,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final bundleCount = (map['bundle_count'] as num?)?.toInt() ?? 0;
    final isBundle =
        bundleCount > 0 ||
        (map['is_bundle'] as int?) == 1 ||
        (map['is_bundle'] as bool?) == true;

    // Jika produk paket dan bundle_available_stock tersedia, gunakan stok paket terhitung
    final int effectiveStock;
    if (isBundle && map['bundle_available_stock'] != null) {
      effectiveStock = (map['bundle_available_stock'] as num).toInt();
    } else {
      effectiveStock = (map['stock'] as num?)?.toInt() ?? 0;
    }

    return ProductModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      costPrice: (map['cost_price'] as num?)?.toInt() ?? 0,
      sellingPrice: (map['selling_price'] as num?)?.toInt() ?? 0,
      stock: effectiveStock,
      unit: (map['unit'] as String?) ?? 'porsi',
      isBundle: isBundle,
      isActive: (map['is_active'] as int?) == 1,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ProductModel copyWith({
    int? id,
    int? categoryId,
    String? categoryName,
    String? name,
    String? description,
    int? costPrice,
    int? sellingPrice,
    int? stock,
    String? unit,
    bool? isBundle,
    bool? isActive,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      description: description ?? this.description,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      isBundle: isBundle ?? this.isBundle,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
