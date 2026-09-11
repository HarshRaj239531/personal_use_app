class WishlistItemModel {
  final String id;
  final String title; // 'Laptop', 'Headphones', 'Phone'
  final double price;
  final String priority; // 'High', 'Medium', 'Low'
  final String category; // 'Tech', 'Fashion', 'Home', 'Books', 'Tools'
  final String? url;
  final bool isPurchased;

  WishlistItemModel({
    required this.id,
    required this.title,
    required this.price,
    this.priority = 'Medium',
    this.category = 'Tech',
    this.url,
    this.isPurchased = false,
  });

  WishlistItemModel copyWith({
    String? id,
    String? title,
    double? price,
    String? priority,
    String? category,
    String? url,
    bool? isPurchased,
  }) {
    return WishlistItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      url: url ?? this.url,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'priority': priority,
      'category': category,
      'url': url ?? '',
      'isPurchased': isPurchased ? 1 : 0,
    };
  }

  factory WishlistItemModel.fromMap(Map<String, dynamic> map) {
    return WishlistItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      price: (map['price'] as num).toDouble(),
      priority: map['priority'] as String? ?? 'Medium',
      category: map['category'] as String? ?? 'Tech',
      url: (map['url'] as String?)?.isEmpty ?? true ? null : map['url'] as String,
      isPurchased: (map['isPurchased'] as int? ?? 0) == 1,
    );
  }
}
