import 'sale_item_model.dart';

/// Model transaksi penjualan sesuai ARCHITECTURE.md tabel `sales`.
class SaleModel {
  final int? id;
  final String invoiceNumber;
  final DateTime saleDate;
  final int subtotal;
  final int discount;
  final int total;
  final String paymentMethod; // 'Tunai', 'Transfer', 'QRIS'
  final int amountPaid;
  final int changeAmount;
  final String? note;
  final DateTime createdAt;

  /// Daftar item (berguna saat query dengan relasi `sale_items`)
  final List<SaleItemModel> items;

  const SaleModel({
    this.id,
    required this.invoiceNumber,
    required this.saleDate,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    this.changeAmount = 0,
    this.note,
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'sale_date': saleDate.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change_amount': changeAmount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SaleModel.fromMap(
    Map<String, dynamic> map, {
    List<SaleItemModel> items = const [],
  }) {
    return SaleModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      saleDate: DateTime.parse(map['sale_date'] as String),
      subtotal: (map['subtotal'] as num).toInt(),
      discount: (map['discount'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num).toInt(),
      paymentMethod: map['payment_method'] as String,
      amountPaid: (map['amount_paid'] as num).toInt(),
      changeAmount: (map['change_amount'] as num?)?.toInt() ?? 0,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
    );
  }

  SaleModel copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? saleDate,
    int? subtotal,
    int? discount,
    int? total,
    String? paymentMethod,
    int? amountPaid,
    int? changeAmount,
    String? note,
    DateTime? createdAt,
    List<SaleItemModel>? items,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      saleDate: saleDate ?? this.saleDate,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      changeAmount: changeAmount ?? this.changeAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
