class Product {
  final int id;
  final int? itemNo;
  final String name;
  final int priceClinic;
  final int? priceHomeVisit;
  final bool isActive;
  final String category;
  final String? imageUrl;

  Product({
    required this.id,
    this.itemNo,
    required this.name,
    required this.priceClinic,
    this.priceHomeVisit,
    this.isActive = true,
    this.category = '',
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      itemNo: json['item_no'] as int?,
      name: json['name'] as String,
      priceClinic: json['price_clinic'] as int,
      priceHomeVisit: json['price_home_visit'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      category: json['category'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_no': itemNo,
    'name': name,
    'price_clinic': priceClinic,
    'price_home_visit': priceHomeVisit,
    'is_active': isActive,
    'category': category,
    'image_url': imageUrl,
  };

  Product copyWith({
    int? id,
    int? itemNo,
    String? name,
    int? priceClinic,
    int? priceHomeVisit,
    bool? isActive,
    String? category,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      itemNo: itemNo ?? this.itemNo,
      name: name ?? this.name,
      priceClinic: priceClinic ?? this.priceClinic,
      priceHomeVisit: priceHomeVisit ?? this.priceHomeVisit,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
