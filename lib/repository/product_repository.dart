import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

/// Repository for Product operations.
/// Reads and writes directly to Supabase — no local cache.
class ProductRepository {
  final SupabaseService _supabase;

  ProductRepository(this._supabase);

  Future<void> _log(String message) async {
    debugPrint('[Repo:Product] $message');
  }

  /// Get products directly from Supabase.
  Future<List<Product>> getProducts() async {
    await _log('getProducts');
    return await _supabase.fetchProducts();
  }

  /// Add a product via Supabase.
  Future<Product> addProduct(Product product) async {
    await _log('addProduct: ${product.name}');
    return await _supabase.addProduct(product);
  }

  /// Update a product via Supabase.
  Future<void> updateProduct(Product product) async {
    await _log('updateProduct: id=${product.id}');
    await _supabase.updateProduct(product);
  }

  /// Delete a product via Supabase.
  Future<void> deleteProduct(int productId) async {
    await _log('deleteProduct: id=$productId');
    await _supabase.deleteProduct(productId);
  }
}
