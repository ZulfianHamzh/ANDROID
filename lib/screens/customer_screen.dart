import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../providers/pos_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_form_field.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key, this.isPicker = false});

  /// Whether this screen is opened as a full-screen picker (e.g. from the
  /// payment dialog) rather than as a tab inside MainAppScreen. Shows an
  /// AppBar with a back button and provides a proper Material ancestor.
  final bool isPicker;

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  List<Customer> _customers = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final customers = await supabase.fetchCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Customer> get _filteredCustomers {
    if (_searchController.text.isEmpty) return _customers;
    final q = _searchController.text.toLowerCase();
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              (c.phone?.contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: widget.isPicker
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 2,
              leading: const BackButton(),
              title: const Text(
                'Pilih Pelanggan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari pelanggan...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: () => _showCustomerDialog(null),
                  backgroundColor: AppColors.primaryGreen,
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada pelanggan',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final c = _filteredCustomers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 18,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            title: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              [
                                c.phone,
                                c.address,
                              ].whereType<String>().join(' — '),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${c.totalVisits}x',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showCustomerDialog(c);
                                    if (v == 'delete') _deleteCustomer(c);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Hapus',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => _selectCustomer(c),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _selectCustomer(Customer customer) {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, customer);
    }
  }

  Future<void> _showCustomerDialog(Customer? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final isEdit = existing != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan',
          style: const TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(
              label: 'Nama',
              controller: nameCtrl,
              hint: 'Nama lengkap',
            ),
            const SizedBox(height: 10),
            AppFormField(
              label: 'Telepon',
              controller: phoneCtrl,
              hint: 'Nomor telepon',
            ),
            const SizedBox(height: 10),
            AppFormField(label: 'Alamat', controller: addrCtrl, hint: 'Alamat'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 13)),
          ),
          AppActionButton(
            label: isEdit ? 'Simpan' : 'Tambah',
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                final supabase = ref.read(supabaseServiceProvider);
                if (isEdit) {
                  await supabase.updateCustomer(
                    existing.copyWith(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty
                          ? null
                          : phoneCtrl.text.trim(),
                      address: addrCtrl.text.trim().isEmpty
                          ? null
                          : addrCtrl.text.trim(),
                    ),
                  );
                } else {
                  await supabase.addCustomer(
                    Customer(
                      id: 0,
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty
                          ? null
                          : phoneCtrl.text.trim(),
                      address: addrCtrl.text.trim().isEmpty
                          ? null
                          : addrCtrl.text.trim(),
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
    if (result == true) _loadCustomers();
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pelanggan', style: TextStyle(fontSize: 16)),
        content: Text(
          'Hapus ${customer.name}?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final supabase = ref.read(supabaseServiceProvider);
        await supabase.deleteCustomer(customer.id);
        _loadCustomers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }
}
