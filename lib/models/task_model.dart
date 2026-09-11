class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String priority; // 'High', 'Medium', 'Low'
  final DateTime? dueDate;
  final bool isCompleted;
  final String? linkedGoalId;
  final String? linkedProjectId;
  final String? tag;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'Medium',
    this.dueDate,
    this.isCompleted = false,
    this.linkedGoalId,
    this.linkedProjectId,
    this.tag,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    String? linkedGoalId,
    String? linkedProjectId,
    String? tag,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      linkedProjectId: linkedProjectId ?? this.linkedProjectId,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'priority': priority,
      'dueDate': dueDate?.toIso8601String() ?? '',
      'isCompleted': isCompleted ? 1 : 0,
      'linkedGoalId': linkedGoalId ?? '',
      'linkedProjectId': linkedProjectId ?? '',
      'tag': tag ?? '',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?)?.isEmpty ?? true ? null : map['description'] as String,
      priority: map['priority'] as String? ?? 'Medium',
      dueDate: (map['dueDate'] as String?)?.isNotEmpty == true ? DateTime.parse(map['dueDate'] as String) : null,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      linkedGoalId: (map['linkedGoalId'] as String?)?.isEmpty ?? true ? null : map['linkedGoalId'] as String,
      linkedProjectId: (map['linkedProjectId'] as String?)?.isEmpty ?? true ? null : map['linkedProjectId'] as String,
      tag: (map['tag'] as String?)?.isEmpty ?? true ? null : map['tag'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
