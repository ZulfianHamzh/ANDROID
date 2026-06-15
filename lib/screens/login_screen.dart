import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pos_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../services/local_database_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  List<Map<String, dynamic>> _offlineAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadOfflineAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadOfflineAccounts() async {
    try {
      final localDB = LocalDatabaseService();
      final accounts = await localDB.getAllAccounts();
      if (mounted) setState(() => _offlineAccounts = accounts);
    } catch (_) {}
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi email dan password')),
      );
      return;
    }
    setState(() => _isLoading = true);

    // Try online login first
    final error = await ref.read(posProvider.notifier).login(email, password);
    if (!mounted) return;

    // If online login failed with connection error, try offline
    if (error != null && _isConnectionError(error)) {
      debugPrint('[Login] Online failed, trying offline login...');
      final user = await ref.read(posProvider.notifier).offlineLogin(email, password);
      if (context.mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          ref.read(posProvider.notifier).loadProducts();
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login offline gagal. Periksa email/password.')),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ref.read(posProvider.notifier).loadProducts();
  }

  bool _isConnectionError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('offline') ||
        lower.contains('internet') ||
        lower.contains('koneksi') ||
        lower.contains('timeout') ||
        lower.contains('connection') ||
        lower.contains('server');
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    // Untuk layar 800x1280 gunakan layout dua kolom agar tidak terlalu memanjang
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  // Layout dua kolom untuk tablet 8-inch (800px lebar)
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Panel kiri — branding
        Expanded(
          child: Container(
            color: AppColors.primaryGreen.withValues(alpha: 0.07),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Image.asset(
                      'lib/assets/logo-dhbh.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Point of Sale',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Panel kanan — form login
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/logo-dhbh.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Masuk',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 6),
        Text('Silakan masuk ke akun Anda',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 24),
        _buildTextField('Email', controller: _emailController),
        const SizedBox(height: 12),
        _buildTextField('Password',
          controller: _passwordController,
          obscureText: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
              size: 18,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Login',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        if (_offlineAccounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          const Text('Akun tersimpan:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          ..._offlineAccounts.map((account) {
            final name = account['full_name'] as String? ?? '';
            final email = account['email'] as String? ?? '';
            return InkWell(
              onTap: () {
                _emailController.text = email;
                _passwordController.text = '';
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$name ($email)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextField(String hint, {
    TextEditingController? controller,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
