class ResourceModel {
  final String id;
  final String title;
  final String url;
  final String category; // 'Websites', 'YouTube', 'Articles', 'Documentation', 'GitHub', 'Courses', 'Interview'
  final String? description;
  final String? tags;
  final bool isFavorite;
  final bool isRead;

  ResourceModel({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    this.description,
    this.tags,
    this.isFavorite = false,
    this.isRead = false,
  });

  ResourceModel copyWith({
    String? id,
    String? title,
    String? url,
    String? category,
    String? description,
    String? tags,
    bool? isFavorite,
    bool? isRead,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      category: category ?? this.category,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'category': category,
      'description': description ?? '',
      'tags': tags ?? '',
      'isFavorite': isFavorite ? 1 : 0,
      'isRead': isRead ? 1 : 0,
    };
  }

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      category: map['category'] as String,
      description: (map['description'] as String?)?.isEmpty ?? true ? null : map['description'] as String,
      tags: (map['tags'] as String?)?.isEmpty ?? true ? null : map['tags'] as String,
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      isRead: (map['isRead'] as int? ?? 0) == 1,
    );
  }
}
