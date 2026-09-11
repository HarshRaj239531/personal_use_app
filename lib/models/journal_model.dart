class JournalModel {
  final String id;
  final DateTime date;
  final String mood; // 'Great', 'Good', 'Neutral', 'Down', 'Stressed'
  final String whatHappened;
  final String whatLearned;
  final String wentWell;
  final String couldImprove;

  JournalModel({
    required this.id,
    required this.date,
    this.mood = 'Good',
    required this.whatHappened,
    required this.whatLearned,
    required this.wentWell,
    required this.couldImprove,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'whatHappened': whatHappened,
      'whatLearned': whatLearned,
      'wentWell': wentWell,
      'couldImprove': couldImprove,
    };
  }

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    return JournalModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      mood: map['mood'] as String? ?? 'Good',
      whatHappened: map['whatHappened'] as String? ?? '',
      whatLearned: map['whatLearned'] as String? ?? '',
      wentWell: map['wentWell'] as String? ?? '',
      couldImprove: map['couldImprove'] as String? ?? '',
    );
  }
}
