class IdeaModel {
  final String id;
  final String title;
  final String category; // 'Project', 'Startup', 'Feature', 'Content'
  final String priority; // 'High', 'Medium', 'Low'
  final String description;
  final String technologies; // 'Flutter, Bluetooth, AI'
  final String status; // 'Idea', 'Research', 'In Progress', 'Shipped'
  final DateTime createdAt;

  IdeaModel({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.description,
    required this.technologies,
    this.status = 'Idea',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'priority': priority,
      'description': description,
      'technologies': technologies,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory IdeaModel.fromMap(Map<String, dynamic> map) {
    return IdeaModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      priority: map['priority'] as String,
      description: map['description'] as String,
      technologies: map['technologies'] as String,
      status: map['status'] as String? ?? 'Idea',
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
