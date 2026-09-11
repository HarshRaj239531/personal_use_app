class ProjectModel {
  final String id;
  final String title; // e.g. 'HillGuard', 'SlickSync', 'LifeOS'
  final String description;
  final String technologies; // 'Flutter, Dart, SQLite'
  final int progress; // 0 - 100
  final String? githubUrl;
  final String? liveUrl;
  final String status; // 'Planning', 'In Progress', 'Completed'

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.technologies,
    this.progress = 0,
    this.githubUrl,
    this.liveUrl,
    this.status = 'In Progress',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'technologies': technologies,
      'progress': progress,
      'githubUrl': githubUrl ?? '',
      'liveUrl': liveUrl ?? '',
      'status': status,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      technologies: map['technologies'] as String,
      progress: map['progress'] as int? ?? 0,
      githubUrl: (map['githubUrl'] as String?)?.isEmpty ?? true ? null : map['githubUrl'] as String,
      liveUrl: (map['liveUrl'] as String?)?.isEmpty ?? true ? null : map['liveUrl'] as String,
      status: map['status'] as String? ?? 'In Progress',
    );
  }
}
