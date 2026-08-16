import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pos_provider.dart' show supabaseServiceProvider;
import 'product_repository.dart';
import 'transaction_repository.dart';
import 'held_order_repository.dart';
import 'customer_repository.dart';
import 'auth_repository.dart';

// ─── REPOSITORY PROVIDERS ───────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ProductRepository(supabase);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return TransactionRepository(supabase);
});

final heldOrderRepositoryProvider = Provider<HeldOrderRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return HeldOrderRepository(supabase);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return CustomerRepository(supabase);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return AuthRepository(supabase);
});
