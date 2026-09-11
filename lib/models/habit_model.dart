import 'package:intl/intl.dart';

class HabitModel {
  final String id;
  final String name;
  final String iconName; // e.g. 'code', 'book', 'fitness', 'water', 'bed', 'edit', 'self_improvement'
  final int streak;
  final List<String> completedDates; // Format: 'yyyy-MM-dd'

  HabitModel({
    required this.id,
    required this.name,
    this.iconName = 'check',
    this.streak = 0,
    List<String>? completedDates,
  }) : completedDates = completedDates ?? [];

  bool isCompletedOn(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return completedDates.contains(dateStr);
  }

  bool isCompletedToday() {
    return isCompletedOn(DateTime.now());
  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? iconName,
    int? streak,
    List<String>? completedDates,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      streak: streak ?? this.streak,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'streak': streak,
      'completedDates': completedDates.join(','),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    final rawDates = map['completedDates'] as String? ?? '';
    final dates = rawDates.isEmpty ? <String>[] : rawDates.split(',').where((d) => d.trim().isNotEmpty).toList();
    return HabitModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['iconName'] as String? ?? 'check',
      streak: map['streak'] as int? ?? 0,
      completedDates: dates,
    );
  }
}
