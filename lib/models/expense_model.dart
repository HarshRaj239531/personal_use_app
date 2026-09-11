import 'package:uuid/uuid.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String type; // 'expense' or 'income'
  final String category; // 'Food', 'Transport', 'Tech', 'Bills', 'Shopping', 'Education', 'Health', 'Salary', 'Other'
  final String paymentMode; // 'UPI', 'Cash', 'Card', 'NetBanking'
  final DateTime date;
  final String? notes;

  ExpenseModel({
    String? id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    String? paymentMode,
    DateTime? date,
    this.notes,
  })  : id = (id == null || id.isEmpty) ? const Uuid().v4() : id,
        paymentMode = paymentMode ?? 'UPI',
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'paymentMode': paymentMode,
      'date': date.toIso8601String(),
      'notes': notes ?? '',
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      paymentMode: map['paymentMode'] as String? ?? 'UPI',
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
