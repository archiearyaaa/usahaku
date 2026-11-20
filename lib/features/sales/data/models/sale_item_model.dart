/// Model detail item penjualan sesuai ARCHITECTURE.md tabel `sale_items`.
/// Menyimpan snapshot nama, harga satuan, dan harga modal saat transaksi dibuat.
class SaleItemModel {
  final int? id;
  final int? saleId;
  final int? productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int unitCost;
  final int lineTotal;

  const SaleItemModel({
    this.id,
    this.saleId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.unitCost = 0,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'unit_cost': unitCost,
      'line_total': lineTotal,
    };
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unit_price'] as num).toInt(),
      unitCost: (map['unit_cost'] as num?)?.toInt() ?? 0,
      lineTotal: (map['line_total'] as num).toInt(),
    );
  }

  SaleItemModel copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    int? quantity,
    int? unitPrice,
    int? unitCost,
    int? lineTotal,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }
}
