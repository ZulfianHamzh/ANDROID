import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';

/// Repository for Authentication operations.
/// Directly communicates with Supabase — no offline fallback.
class AuthRepository {
  final SupabaseService _supabase;

  AuthRepository(this._supabase);

  Future<void> _log(String message) async {
    debugPrint('[Repo:Auth] $message');
  }

  /// Login — authenticate via Supabase.
  Future<AppUser?> login(String email, String password) async {
    await _log('login: $email');
    return await _supabase.signIn(email, password);
  }

  /// Get current user from remote session.
  Future<AppUser?> getCurrentUser() async {
    return await _supabase.getCurrentUser();
  }

  /// Logout.
  Future<void> logout() async {
    await _supabase.signOut();
  }

  /// Register a new user.
  Future<AppUser?> signUp(String email, String password, {
    required String username,
    required String displayName,
    required String role,
    int? branchId,
  }) async {
    return await _supabase.signUp(email, password,
      username: username,
      displayName: displayName,
      role: role,
      branchId: branchId,
    );
  }
}
