class InterviewQuestionModel {
  final String id;
  final String technology; // 'Flutter', 'Python', 'SQL', 'DSA', 'System Design'
  final String question;
  final String answer;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final bool isMastered;

  InterviewQuestionModel({
    required this.id,
    required this.technology,
    required this.question,
    required this.answer,
    this.difficulty = 'Medium',
    this.isMastered = false,
  });

  InterviewQuestionModel copyWith({
    String? id,
    String? technology,
    String? question,
    String? answer,
    String? difficulty,
    bool? isMastered,
  }) {
    return InterviewQuestionModel(
      id: id ?? this.id,
      technology: technology ?? this.technology,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      difficulty: difficulty ?? this.difficulty,
      isMastered: isMastered ?? this.isMastered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'technology': technology,
      'question': question,
      'answer': answer,
      'difficulty': difficulty,
      'isMastered': isMastered ? 1 : 0,
    };
  }

  factory InterviewQuestionModel.fromMap(Map<String, dynamic> map) {
    return InterviewQuestionModel(
      id: map['id'] as String,
      technology: map['technology'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      difficulty: map['difficulty'] as String? ?? 'Medium',
      isMastered: (map['isMastered'] as int? ?? 0) == 1,
    );
  }
}

class MockInterviewLogModel {
  final String id;
  final String company;
  final DateTime date;
  final String questionsAsked;
  final int performanceRating; // 1 - 10
  final String? thingsToImprove;

  MockInterviewLogModel({
    required this.id,
    required this.company,
    required this.date,
    required this.questionsAsked,
    required this.performanceRating,
    this.thingsToImprove,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'date': date.toIso8601String(),
      'questionsAsked': questionsAsked,
      'performanceRating': performanceRating,
      'thingsToImprove': thingsToImprove ?? '',
    };
  }

  factory MockInterviewLogModel.fromMap(Map<String, dynamic> map) {
    return MockInterviewLogModel(
      id: map['id'] as String,
      company: map['company'] as String,
      date: DateTime.parse(map['date'] as String),
      questionsAsked: map['questionsAsked'] as String,
      performanceRating: map['performanceRating'] as int,
      thingsToImprove: (map['thingsToImprove'] as String?)?.isEmpty ?? true ? null : map['thingsToImprove'] as String,
    );
  }
}
