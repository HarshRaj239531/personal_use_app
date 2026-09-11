class SecureItemModel {
  final String id;
  final String title; // e.g. 'Home Wi-Fi', 'Gemini API Key', 'Server SSH Key', 'GitHub Token'
  final String category; // 'API Key', 'Wi-Fi', 'License', 'Credentials', 'Recovery Code'
  final String secretValue;
  final String? secondaryValue; // e.g. Username or SSID
  final String? notes;
  final DateTime updatedAt;

  SecureItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.secretValue,
    this.secondaryValue,
    this.notes,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'secretValue': secretValue,
      'secondaryValue': secondaryValue ?? '',
      'notes': notes ?? '',
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SecureItemModel.fromMap(Map<String, dynamic> map) {
    return SecureItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      secretValue: map['secretValue'] as String,
      secondaryValue: (map['secondaryValue'] as String?)?.isEmpty ?? true ? null : map['secondaryValue'] as String,
      notes: (map['notes'] as String?)?.isEmpty ?? true ? null : map['notes'] as String,
      updatedAt: DateTime.parse(map['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
