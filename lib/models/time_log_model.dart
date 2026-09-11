class TimeLogModel {
  final String id;
  final String activity; // e.g. 'Flutter Study', 'DSA Practice', 'Project HillGuard', 'Job Prep'
  final String category; // 'Study', 'Project', 'Job', 'Reading', 'Other'
  final int durationSeconds;
  final DateTime date;
  final String? notes;

  TimeLogModel({
    required this.id,
    required this.activity,
    required this.category,
    required this.durationSeconds,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity': activity,
      'category': category,
      'durationSeconds': durationSeconds,
      'date': date.toIso8601String(),
      'notes': notes ?? '',
    };
  }

  factory TimeLogModel.fromMap(Map<String, dynamic> map) {
    return TimeLogModel(
      id: map['id'] as String,
      activity: map['activity'] as String,
      category: map['category'] as String,
      durationSeconds: map['durationSeconds'] as int,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
