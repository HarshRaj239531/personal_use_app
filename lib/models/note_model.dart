import 'package:uuid/uuid.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final String category; // 'General', 'Work', 'Study', 'Code', 'Ideas'
  final bool isPinned;
  final String? colorHex;
  final List<String> tags;
  final DateTime updatedAt;

  NoteModel({
    String? id,
    required this.title,
    required this.content,
    this.category = 'General',
    this.isPinned = false,
    this.colorHex,
    List<String>? tags,
    DateTime? updatedAt,
  })  : id = (id == null || id.isEmpty) ? const Uuid().v4() : id,
        tags = tags ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    bool? isPinned,
    String? colorHex,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      colorHex: colorHex ?? this.colorHex,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'isPinned': isPinned ? 1 : 0,
      'colorHex': colorHex ?? '',
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String? ?? 'General',
      isPinned: (map['isPinned'] as int? ?? 0) == 1,
      colorHex: (map['colorHex'] as String?)?.isEmpty ?? true
          ? null
          : map['colorHex'] as String,
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
