import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/pos_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _savedKey = 'saved_login_emails';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  List<String> _savedEmails = [];

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
  }

  Future<void> _loadSavedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_savedKey) ?? [];
      if (mounted) setState(() => _savedEmails = list);
    } catch (e) {
      debugPrint('[Login] load saved emails error: $e');
    }
  }

  Future<void> _saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_savedKey) ?? [];
      list.remove(email);
      list.insert(0, email);
      await prefs.setStringList(_savedKey, list.take(10).toList());
      debugPrint('[Login] saved account: $email (${list.take(10).length} total)');
      if (mounted) setState(() => _savedEmails = list.take(10).toList());
    } catch (e) {
      debugPrint('[Login] save email error: $e');
    }
  }

  Future<void> _removeEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = (prefs.getStringList(_savedKey) ?? [])
          .where((e) => e != email)
          .toList();
      await prefs.setStringList(_savedKey, list);
      if (mounted) setState(() => _savedEmails = list);
    } catch (e) {
      debugPrint('[Login] remove email error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
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

    final error = await ref.read(posProvider.notifier).login(email, password);

    if (error != null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _saveEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          child: _buildBrandingPanel(),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBrandingPanel(compact: true),
            const SizedBox(height: 32),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingPanel({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 40,
        vertical: compact ? 20 : 40,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.08),
            AppColors.primaryGreen.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo container dengan efek floating
          Container(
            width: compact ? 100 : 150,
            height: compact ? 100 : 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 24 : 32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'lib/assets/logo-dhbh.png',
                width: compact ? 65 : 100,
                height: compact ? 65 : 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: compact ? 16 : 24),
          Text(
            'Point of Sale',
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            compact ? 'DHBH Spa & Wellness' : 'Sistem Kasir Terpadu untuk Bisnis Anda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.login,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Masuk ke akun Anda',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Akun Tersimpan (tampil paling atas agar mudah dipilih) ──
        if (_savedEmails.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.bookmark_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Akun Tersimpan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_savedEmails.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._savedEmails.map(_buildSavedAccountTile),
          const SizedBox(height: 20),
          // Divider dengan "atau"
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'atau masuk manual',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Email Field
        _buildInputField(
          hint: 'Email',
          controller: _emailController,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        // Password Field
        _buildInputField(
          hint: 'Password',
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade500,
                size: 18,
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Login Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.6),
              elevation: _isLoading ? 0 : 6,
              shadowColor: AppColors.primaryGreen.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Footer text
        Center(
          child: Text(
            'Dilindungi dengan enkripsi end-to-end',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAccountTile(String email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _emailController.text = email;
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar dengan gradient
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.primaryGreen.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.touch_app, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            'Klik untuk login cepat',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Hapus button
                _buildRemoveButton(email),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(String email) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showRemoveConfirmation(email),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.red.shade400,
            ),
          ),
        ),
      ),
    );
  }

  void _showRemoveConfirmation(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Akun?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.darkBlue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hapus "$email" dari daftar akun tersimpan?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda tetap dapat login dengan memasukkan email dan password secara manual.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeEmail(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    TextEditingController? controller,
    FocusNode? focusNode,
    IconData? icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (mounted) setState(() {});
        },
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasFocus ? AppColors.primaryGreen : Colors.grey.shade200,
                  width: hasFocus ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                keyboardType: keyboardType,
                style: const TextStyle(
                  color: AppColors.darkBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: icon != null
                      ? Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: hasFocus
                                ? AppColors.primaryGreen.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(13),
                              bottomLeft: Radius.circular(13),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: hasFocus
                                ? AppColors.primaryGreen
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                        )
                      : null,
                  suffixIcon: suffix,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}