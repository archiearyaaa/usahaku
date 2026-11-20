/// Model pergerakan stok sesuai ARCHITECTURE.md tabel `stock_movements`.
/// `type`: 'in' (masuk), 'out' (keluar), 'adjustment' (penyesuaian).
class StockMovementModel {
  final int? id;
  final int materialId;
  final String type; // 'in', 'out', 'adjustment'
  final double quantity;
  final String? note;
  final DateTime movementDate;
  final DateTime createdAt;

  /// Helper join dari tabel materials (tidak disimpan ke DB)
  final String? materialName;
  final String? materialUnit;

  const StockMovementModel({
    this.id,
    required this.materialId,
    required this.type,
    required this.quantity,
    this.note,
    required this.movementDate,
    required this.createdAt,
    this.materialName,
    this.materialUnit,
  });

  /// Label tipe dalam Bahasa Indonesia
  String get typeLabel {
    switch (type) {
      case 'in':
        return 'Stok Masuk';
      case 'out':
        return 'Stok Keluar';
      case 'adjustment':
        return 'Penyesuaian';
      default:
        return type;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'material_id': materialId,
      'type': type,
      'quantity': quantity,
      'note': note,
      'movement_date': movementDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    return StockMovementModel(
      id: map['id'] as int?,
      materialId: (map['material_id'] as num).toInt(),
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      note: map['note'] as String?,
      movementDate: DateTime.parse(map['movement_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      materialName: map['material_name'] as String?,
      materialUnit: map['material_unit'] as String?,
    );
  }

  StockMovementModel copyWith({
    int? id,
    int? materialId,
    String? type,
    double? quantity,
    String? note,
    DateTime? movementDate,
    DateTime? createdAt,
    String? materialName,
    String? materialUnit,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      movementDate: movementDate ?? this.movementDate,
      createdAt: createdAt ?? this.createdAt,
      materialName: materialName ?? this.materialName,
      materialUnit: materialUnit ?? this.materialUnit,
    );
  }
}
