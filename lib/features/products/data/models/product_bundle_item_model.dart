/// Model item komponen penyusun produk paket (bundling).
/// Misalnya: Paket Misopa Komplit berisi 1 pcs Misopa + 1 gelas Es Teh.
class ProductBundleItemModel {
  final int? id;
  final int bundleProductId;
  final int itemProductId;
  final String itemName;
  final String itemUnit;
  final int itemCostPrice;
  final int itemStock;
  final int quantity; // Kuantitas item yang terpakai untuk 1 paket

  const ProductBundleItemModel({
    this.id,
    required this.bundleProductId,
    required this.itemProductId,
    required this.itemName,
    this.itemUnit = 'pcs',
    this.itemCostPrice = 0,
    this.itemStock = 0,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bundle_product_id': bundleProductId,
      'item_product_id': itemProductId,
      'quantity': quantity,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory ProductBundleItemModel.fromMap(Map<String, dynamic> map) {
    return ProductBundleItemModel(
      id: map['id'] as int?,
      bundleProductId: (map['bundle_product_id'] as num).toInt(),
      itemProductId: (map['item_product_id'] as num).toInt(),
      itemName: (map['item_name'] as String?) ?? '',
      itemUnit: (map['item_unit'] as String?) ?? 'pcs',
      itemCostPrice: (map['cost_price'] as num?)?.toInt() ?? 0,
      itemStock: (map['item_stock'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  ProductBundleItemModel copyWith({
    int? id,
    int? bundleProductId,
    int? itemProductId,
    String? itemName,
    String? itemUnit,
    int? itemCostPrice,
    int? itemStock,
    int? quantity,
  }) {
    return ProductBundleItemModel(
      id: id ?? this.id,
      bundleProductId: bundleProductId ?? this.bundleProductId,
      itemProductId: itemProductId ?? this.itemProductId,
      itemName: itemName ?? this.itemName,
      itemUnit: itemUnit ?? this.itemUnit,
      itemCostPrice: itemCostPrice ?? this.itemCostPrice,
      itemStock: itemStock ?? this.itemStock,
      quantity: quantity ?? this.quantity,
    );
  }
}
