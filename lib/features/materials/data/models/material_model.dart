/// Model bahan baku sesuai ARCHITECTURE.md tabel `materials`.
/// - `quantity` dan `minimumStock` bertipe `double` (REAL di SQLite)
///   karena bahan baku dapat dihitung dengan desimal (0.5 kg, 1.5 liter).
class MaterialModel {
  final int? id;
  final String name;
  final String unit;
  final double quantity;
  final double? minimumStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialModel({
    this.id,
    required this.name,
    required this.unit,
    this.quantity = 0,
    this.minimumStock,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Apakah stok berada di bawah batas minimum
  bool get isLowStock =>
      minimumStock != null && quantity < minimumStock! && minimumStock! > 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minimum_stock': minimumStock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: map['unit'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      minimumStock: (map['minimum_stock'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  MaterialModel copyWith({
    int? id,
    String? name,
    String? unit,
    double? quantity,
    double? minimumStock,
    bool clearMinimumStock = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minimumStock: clearMinimumStock
          ? null
          : (minimumStock ?? this.minimumStock),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
