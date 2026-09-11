class KeyResultModel {
  final String id;
  final String goalId;
  final String title;
  final double current;
  final double target;
  final String unit; // '%', 'tasks', 'companies', 'projects'

  KeyResultModel({
    required this.id,
    required this.goalId,
    required this.title,
    required this.current,
    required this.target,
    this.unit = '%',
  });

  double get progress => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'current': current,
      'target': target,
      'unit': unit,
    };
  }

  factory KeyResultModel.fromMap(Map<String, dynamic> map) {
    return KeyResultModel(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      title: map['title'] as String,
      current: (map['current'] as num).toDouble(),
      target: (map['target'] as num).toDouble(),
      unit: map['unit'] as String? ?? '%',
    );
  }
}

class GoalModel {
  final String id;
  final String title;
  final String category; // 'Career', 'Health', 'Finance', 'Learning', 'Personal'
  final DateTime targetDate;
  final List<KeyResultModel> keyResults;
  final bool isCompleted;

  GoalModel({
    required this.id,
    required this.title,
    required this.category,
    required this.targetDate,
    this.keyResults = const [],
    this.isCompleted = false,
  });

  double get overallProgress {
    if (keyResults.isEmpty) return isCompleted ? 1.0 : 0.0;
    final sum = keyResults.fold<double>(0.0, (acc, kr) => acc + kr.progress);
    return sum / keyResults.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'targetDate': targetDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, {List<KeyResultModel>? keyResults}) {
    return GoalModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      targetDate: DateTime.parse(map['targetDate'] as String),
      keyResults: keyResults ?? [],
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }
}
