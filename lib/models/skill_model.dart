class SkillModel {
  final String id;
  final String name; // 'Flutter', 'Laravel', 'Python', 'DSA', 'SQL', 'Git'
  final int currentLevel; // 0 - 100
  final int targetLevel; // 0 - 100
  final String? resources;
  final String? notes;
  final double practiceHours;

  SkillModel({
    required this.id,
    required this.name,
    required this.currentLevel,
    required this.targetLevel,
    this.resources,
    this.notes,
    this.practiceHours = 0.0,
  });

  SkillModel copyWith({
    String? id,
    String? name,
    int? currentLevel,
    int? targetLevel,
    String? resources,
    String? notes,
    double? practiceHours,
  }) {
    return SkillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      currentLevel: currentLevel ?? this.currentLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      resources: resources ?? this.resources,
      notes: notes ?? this.notes,
      practiceHours: practiceHours ?? this.practiceHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentLevel': currentLevel,
      'targetLevel': targetLevel,
      'resources': resources ?? '',
      'notes': notes ?? '',
      'practiceHours': practiceHours,
    };
  }

  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      id: map['id'] as String,
      name: map['name'] as String,
      currentLevel: map['currentLevel'] as int,
      targetLevel: map['targetLevel'] as int,
      resources: (map['resources'] as String?)?.isEmpty ?? true ? null : map['resources'] as String,
      notes: (map['notes'] as String?)?.isEmpty ?? true ? null : map['notes'] as String,
      practiceHours: (map['practiceHours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
