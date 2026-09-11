class ImportantDateModel {
  final String id;
  final String title; // 'College Fee Due', 'TCS Interview', 'Mom Birthday', 'AWS Free Tier Expiry'
  final DateTime date;
  final String category; // 'Exam', 'Interview', 'Payment', 'Birthday', 'Deadline', 'Event'
  final String? reminderTime;
  final String? notes;

  ImportantDateModel({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    this.reminderTime,
    this.notes,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'category': category,
      'reminderTime': reminderTime ?? '',
      'notes': notes ?? '',
    };
  }

  factory ImportantDateModel.fromMap(Map<String, dynamic> map) {
    return ImportantDateModel(
      id: map['id'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      reminderTime: (map['reminderTime'] as String?)?.isEmpty ?? true ? null : map['reminderTime'] as String,
      notes: (map['notes'] as String?)?.isEmpty ?? true ? null : map['notes'] as String,
    );
  }
}
