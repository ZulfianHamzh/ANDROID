class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final int totalVisits;
  final int totalSpent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.totalVisits = 0,
    this.totalSpent = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      totalVisits: (json['total_visits'] as int?) ?? 0,
      totalSpent: (json['total_spent'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'total_visits': totalVisits,
    'total_spent': totalSpent,
  };

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    int? totalVisits,
    int? totalSpent,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
