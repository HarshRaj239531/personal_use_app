class StudySessionModel {
  final String id;
  final String subject; // e.g. 'Flutter', 'DSA', 'Python', 'System Design'
  final String topic; // e.g. 'Bloc Pattern', 'Binary Search Trees'
  final int durationMinutes;
  final DateTime date;
  final int rating; // 1 to 5 mastery rating
  final String? notes;

  StudySessionModel({
    required this.id,
    required this.subject,
    required this.topic,
    required this.durationMinutes,
    required this.date,
    this.rating = 4,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'durationMinutes': durationMinutes,
      'date': date.toIso8601String(),
      'rating': rating,
      'notes': notes ?? '',
    };
  }

  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: map['id'] as String,
      subject: map['subject'] as String,
      topic: map['topic'] as String,
      durationMinutes: map['durationMinutes'] as int,
      date: DateTime.parse(map['date'] as String),
      rating: map['rating'] as int? ?? 4,
      notes: map['notes'] as String?,
    );
  }
}
