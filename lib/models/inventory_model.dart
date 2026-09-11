class InventoryItemModel {
  final String id;
  final String name; // 'MacBook Pro', 'iPhone 15', 'Mechanical Keyboard'
  final String category; // 'Electronics', 'Documents', 'Valuables', 'Appliances'
  final double price;
  final DateTime purchaseDate;
  final DateTime? warrantyExpiry;
  final String? serialNumber;
  final String? notes;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.purchaseDate,
    this.warrantyExpiry,
    this.serialNumber,
    this.notes,
  });

  bool get hasActiveWarranty {
    if (warrantyExpiry == null) return false;
    return warrantyExpiry!.isAfter(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyExpiry': warrantyExpiry?.toIso8601String() ?? '',
      'serialNumber': serialNumber ?? '',
      'notes': notes ?? '',
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      warrantyExpiry: (map['warrantyExpiry'] as String?)?.isNotEmpty == true ? DateTime.parse(map['warrantyExpiry'] as String) : null,
      serialNumber: (map['serialNumber'] as String?)?.isEmpty ?? true ? null : map['serialNumber'] as String,
      notes: (map['notes'] as String?)?.isEmpty ?? true ? null : map['notes'] as String,
    );
  }
}
