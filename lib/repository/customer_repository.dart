import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';

/// Repository for Customer operations.
/// Reads and writes directly to Supabase — no local cache.
class CustomerRepository {
  final SupabaseService _supabase;

  CustomerRepository(this._supabase);

  Future<void> _log(String message) async {
    debugPrint('[Repo:Customer] $message');
  }

  /// Get customers from Supabase directly.
  Future<List<Customer>> getCustomers() async {
    await _log('getCustomers');
    return await _supabase.fetchCustomers();
  }

  /// Add a customer via Supabase.
  Future<Customer> addCustomer(Customer customer) async {
    await _log('addCustomer: ${customer.name}');
    return await _supabase.addCustomer(customer);
  }

  /// Update a customer via Supabase.
  Future<void> updateCustomer(Customer customer) async {
    await _log('updateCustomer: id=${customer.id}');
    await _supabase.updateCustomer(customer);
  }

  /// Delete a customer via Supabase.
  Future<void> deleteCustomer(int id) async {
    await _log('deleteCustomer: id=$id');
    await _supabase.deleteCustomer(id);
  }
}
