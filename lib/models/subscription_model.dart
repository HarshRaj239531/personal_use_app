class SubscriptionModel {
  final String id;
  final String name; // e.g. 'Netflix', 'Spotify', 'Domain', 'Cloud Storage'
  final double amount;
  final String billingCycle; // 'Monthly', 'Yearly', 'Quarterly'
  final DateTime nextBillingDate;
  final String category; // 'Entertainment', 'Cloud & Tech', 'Education', 'Productivity'
  final bool isActive;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    this.category = 'Cloud & Tech',
    this.isActive = true,
  });

  double get monthlyCost {
    if (billingCycle == 'Yearly') {
      return amount / 12;
    } else if (billingCycle == 'Quarterly') {
      return amount / 3;
    }
    return amount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'category': category,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      billingCycle: map['billingCycle'] as String,
      nextBillingDate: DateTime.parse(map['nextBillingDate'] as String),
      category: map['category'] as String? ?? 'Cloud & Tech',
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }
}
