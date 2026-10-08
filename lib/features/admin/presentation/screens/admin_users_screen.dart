import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _selectedRole = 'all'; // 'all', 'mahasiswa', 'dosen'
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final list = await service.fetchAdminUsers(
        roleFilter: _selectedRole == 'all' ? null : _selectedRole,
        searchQuery: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final idNumCtrl = TextEditingController(text: user['identifier_number'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone_number'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text('Edit Data Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Nama Lengkap',
                      controller: nameCtrl,
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: user['role'] == 'mahasiswa' ? 'NIM' : 'NIDN / NIP',
                      controller: idNumCtrl,
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Email Kampus',
                      controller: emailCtrl,
                      validator: (val) => val == null || !val.contains('@') ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Nomor Telepon (WhatsApp)',
                      controller: phoneCtrl,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        try {
                          await ref.read(supabaseServiceProvider).updateAdminUserProfile(
                                userId: user['id'] as String,
                                fullName: nameCtrl.text.trim(),
                                identifierNumber: idNumCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                phoneNumber: phoneCtrl.text.trim(),
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Data pengguna berhasil diperbarui!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _loadUsers();
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun ${user['full_name']} (${user['email']})? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 13, color: AppColors.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(supabaseServiceProvider).deleteAdminUserProfile(user['id'] as String);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengguna berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadUsers();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Kelola Mahasiswa & Dosen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadUsers(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, NIM, NIDN, atau email...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.slate400),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadUsers();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.slate50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRoleChip('Semua Role', 'all'),
                    const SizedBox(width: 8),
                    _buildRoleChip('Mahasiswa', 'mahasiswa'),
                    const SizedBox(width: 8),
                    _buildRoleChip('Dosen', 'dosen'),
                  ],
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LoadingShimmer(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    color: AppColors.primary,
                    child: _users.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 60),
                              EmptyStateView(
                                title: 'Pengguna Tidak Ditemukan',
                                description: 'Tidak ada data mahasiswa atau dosen yang cocok dengan kriteria pencarian.',
                                icon: Icons.people_outline_rounded,
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _users.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final u = _users[index];
                              final isStudent = u['role'] == 'mahasiswa';
                              final fullName = u['full_name'] ?? 'Tanpa Nama';
                              final idNum = u['identifier_number'] ?? '-';
                              final email = u['email'] ?? '-';

                              return AppCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: isStudent ? AppColors.primaryLight : AppColors.accentLight,
                                      child: Text(
                                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isStudent ? AppColors.primary : AppColors.accent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  fullName,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isStudent ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDF4),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isStudent ? const Color(0xFFC7D2FE) : const Color(0xFFBBF7D0),
                                                  ),
                                                ),
                                                child: Text(
                                                  isStudent ? 'Mahasiswa' : 'Dosen',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isStudent ? AppColors.primary : AppColors.success,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${isStudent ? 'NIM' : 'NIDN'}: $idNum • $email',
                                            style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.slate400),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showEditUserDialog(u);
                                        } else if (val == 'delete') {
                                          _confirmDeleteUser(u);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                              SizedBox(width: 8),
                                              Text('Edit Data', style: TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                              SizedBox(width: 8),
                                              Text('Hapus Pengguna', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildRoleChip(String label, String value) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = value);
        _loadUsers();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.slate100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}
