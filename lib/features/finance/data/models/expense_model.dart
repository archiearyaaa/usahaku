/// Model pengeluaran usaha sesuai ARCHITECTURE.md tabel `expenses`.
class ExpenseModel {
  final int? id;
  final String title;
  final String
  category; // 'Bahan Baku', 'Operasional', 'Sewa', 'Gaji/Upah', 'Peralatan', 'Lainnya'
  final int amount; // Integer Rupiah
  final DateTime expenseDate;
  final String? note;
  final DateTime createdAt;

  const ExpenseModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toInt(),
      expenseDate: DateTime.parse(map['expense_date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ExpenseModel copyWith({
    int? id,
    String? title,
    String? category,
    int? amount,
    DateTime? expenseDate,
    String? note,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
