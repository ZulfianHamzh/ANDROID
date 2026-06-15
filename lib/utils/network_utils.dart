import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static const String _supabaseHost = 'jiunlvlcwsntjbyybszd.supabase.co';
  static const int _dnsTimeoutSeconds = 3;  // Must be less than HTTP client timeout (5s)

  /// Check if device has active internet connection
  static Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
      debugPrint('[Network] isOnline: $isConnected');
      return isConnected;
    } catch (e) {
      debugPrint('[Network] Error checking connectivity: $e');
      return false;
    }
  }

  /// Pre-flight DNS resolution check with timeout
  /// This prevents hanging on native socket lookup later
  static Future<bool> checkDnsResolution({String host = _supabaseHost}) async {
    try {
      debugPrint('[Network] DNS check: Attempting to resolve $host...');
      
      final addresses = await InternetAddress.lookup(host)
          .timeout(
            Duration(seconds: _dnsTimeoutSeconds),
            onTimeout: () {
              debugPrint('[Network] DNS timeout after $_dnsTimeoutSeconds seconds for $host');
              throw TimeoutException('DNS resolution timeout for $host');
            },
          );
      
      if (addresses.isEmpty) {
        debugPrint('[Network] DNS returned no addresses for $host');
        return false;
      }
      
      debugPrint('[Network] DNS OK: Resolved $host to ${addresses.first.address}');
      return true;
    } on TimeoutException {
      debugPrint('[Network] ❌ DNS timeout: Cannot resolve $host within $_dnsTimeoutSeconds seconds');
      return false;
    } on SocketException catch (e) {
      debugPrint('[Network] ❌ Socket error during DNS: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Network] ❌ DNS error: $e');
      return false;
    }
  }

  /// Verify connection to Supabase server with full pre-flight checks
  static Future<bool> canReachSupabase() async {
    try {
      // Step 1: Check basic connectivity
      final isOnline = await NetworkUtils.isOnline();
      if (!isOnline) {
        debugPrint('[Network] ❌ Device is offline');
        return false;
      }
      debugPrint('[Network] ✓ Device has connectivity');

      // Step 2: Check DNS resolution (prevents hanging later)
      final dnsOk = await checkDnsResolution();
      if (!dnsOk) {
        debugPrint('[Network] ❌ DNS resolution failed');
        return false;
      }
      debugPrint('[Network] ✓ DNS resolution OK');

      debugPrint('[Network] ✓ All checks passed');
      return true;
    } catch (e) {
      debugPrint('[Network] ❌ Error in canReachSupabase: $e');
      return false;
    }
  }
}
