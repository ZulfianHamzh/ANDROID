class ProductBranchPrice {
  final int id;
  final int productId;
  final int branchId;
  final int? priceClinic;
  final int? priceHomeVisit;

  ProductBranchPrice({
    required this.id,
    required this.productId,
    required this.branchId,
    this.priceClinic,
    this.priceHomeVisit,
  });

  factory ProductBranchPrice.fromJson(Map<String, dynamic> json) {
    return ProductBranchPrice(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      branchId: json['branch_id'] as int? ?? 0,
      priceClinic: json['price_clinic'] as int?,
      priceHomeVisit: json['price_home_visit'] as int?,
    );
  }
}
