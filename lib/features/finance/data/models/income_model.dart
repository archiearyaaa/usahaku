/// Model pemasukan tambahan non-penjualan sesuai ARCHITECTURE.md tabel `income`.
class IncomeModel {
  final int? id;
  final String title;
  final String
  category; // 'Modal Awal', 'Pendapatan Lain', 'Suntikan Dana', 'Lainnya'
  final int amount; // Integer Rupiah
  final DateTime incomeDate;
  final String? note;
  final DateTime createdAt;

  const IncomeModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.incomeDate,
    this.note,
    required this.createdAt,
  });

  /// Apakah pemasukan ini merupakan modal awal
  bool get isInitialCapital => category.trim().toLowerCase() == 'modal awal';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'income_date': incomeDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toInt(),
      incomeDate: DateTime.parse(map['income_date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  IncomeModel copyWith({
    int? id,
    String? title,
    String? category,
    int? amount,
    DateTime? incomeDate,
    String? note,
    DateTime? createdAt,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      incomeDate: incomeDate ?? this.incomeDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
