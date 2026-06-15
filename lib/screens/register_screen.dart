import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pos_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _branchesLoaded = false;
  String _selectedRole = 'kasir';
  int? _selectedBranchId;
  List<Map<String, dynamic>> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  void _loadBranches() async {
    final branches = await ref.read(supabaseServiceProvider).fetchBranches();
    if (mounted) {
      setState(() {
        _branches = branches;
        _branchesLoaded = true;
        if (branches.isNotEmpty) _selectedBranchId = branches[0]['id'] as int;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showSnackbar('Mohon isi semua field');
      return;
    }
    if (password.length < 6) {
      _showSnackbar('Password minimal 6 karakter');
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('[DHBH Register] signUp: email=$email, role=$_selectedRole, branch=$_selectedBranchId');

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final user = await supabase.signUp(
        email,
        password,
        username: email.split('@').first,
        displayName: name,
        role: _selectedRole,
        branchId: _selectedBranchId,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        _showSnackbar('Akun berhasil dibuat! Silakan login.');
        Navigator.pop(context);
      } else {
        _showSnackbar('Gagal membuat akun');
      }
    } catch (e) {
      debugPrint('[DHBH Register] ERROR: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar('Gagal: ${e.toString()}');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spaceXLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: ResponsiveUtils.screenHeight * 0.2,
                  width: ResponsiveUtils.screenWidth * 0.6,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ResponsiveUtils.radiusNormal),
                  ),
                  child: Center(
                    child: Text(
                      'Daftar Akun Baru',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.font2XLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spaceLarge),
                _buildTextField('Nama Lengkap', controller: _nameController),
                SizedBox(height: ResponsiveUtils.spaceNormal),
                _buildTextField('Email', controller: _emailController),
                SizedBox(height: ResponsiveUtils.spaceNormal),
                _buildTextField('Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                      size: ResponsiveUtils.iconSmall,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spaceNormal),
                _buildDropdown('Role', _selectedRole, ['kasir', 'admin'],
                  (v) { if (v != null) setState(() => _selectedRole = v); },
                ),
                SizedBox(height: ResponsiveUtils.spaceNormal),
                _buildBranchDropdown(),
                SizedBox(height: ResponsiveUtils.spaceXLarge),
                SizedBox(
                  width: ResponsiveUtils.buttonHeightLarge * 3.5,
                  height: ResponsiveUtils.buttonHeightNormal,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1000),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: ResponsiveUtils.iconNormal,
                            height: ResponsiveUtils.iconNormal,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Daftar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.fontLarge,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spaceNormal),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Sudah punya akun? Login',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.fontNormal,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spaceLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.gray,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item == 'kasir' ? 'Kasir' : 'Admin', style: const TextStyle(color: Colors.white)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBranchDropdown() {
    if (!_branchesLoaded) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
      );
    }
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedBranchId,
          isExpanded: true,
          dropdownColor: AppColors.gray,
          items: _branches.map((b) => DropdownMenuItem(
            value: b['id'] as int,
            child: Text(b['name'] as String, style: const TextStyle(color: Colors.white)),
          )).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedBranchId = v);
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {
    TextEditingController? controller,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 17),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
