class BugModel {
  final String id;
  final String title;
  final String? description;
  final String priority; // 'Critical', 'High', 'Medium', 'Low'
  final String status; // 'Open', 'In Progress', 'Fixed'
  final String? projectId;
  final String? projectName;
  final DateTime createdAt;

  BugModel({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'Medium',
    this.status = 'Open',
    this.projectId,
    this.projectName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'priority': priority,
      'status': status,
      'projectId': projectId ?? '',
      'projectName': projectName ?? '',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BugModel.fromMap(Map<String, dynamic> map) {
    return BugModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?)?.isEmpty ?? true ? null : map['description'] as String,
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'Open',
      projectId: (map['projectId'] as String?)?.isEmpty ?? true ? null : map['projectId'] as String,
      projectName: (map['projectName'] as String?)?.isEmpty ?? true ? null : map['projectName'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
