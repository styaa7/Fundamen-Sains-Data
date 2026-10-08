import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AdminTopicsScreen extends ConsumerStatefulWidget {
  const AdminTopicsScreen({super.key});

  @override
  ConsumerState<AdminTopicsScreen> createState() => _AdminTopicsScreenState();
}

class _AdminTopicsScreenState extends ConsumerState<AdminTopicsScreen> {
  final _searchController = TextEditingController();
  TopicStatus? _selectedStatus;
  List<TopicSubmission> _allTopics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final list = await service.fetchTopics(
        allowedStatuses: ['SUBMITTED', 'APPROVED', 'REVISION'],
      );
      if (mounted) {
        setState(() {
          _allTopics = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<TopicSubmission> get _filteredTopics {
    // Admin only sees SUBMITTED, APPROVED, REVISION (NO DRAFTS)
    var result = _allTopics.where((t) =>
        t.status == TopicStatus.submitted ||
        t.status == TopicStatus.approved ||
        t.status == TopicStatus.revision).toList();

    if (_selectedStatus != null) {
      result = result.where((t) => t.status == _selectedStatus).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((t) {
        final title = t.title.toLowerCase();
        final student = (t.studentName ?? '').toLowerCase();
        final lecturer = (t.lecturerName ?? '').toLowerCase();
        return title.contains(query) || student.contains(query) || lecturer.contains(query);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTopics;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Rekapitulasi Pengajuan Topik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari judul topik, mahasiswa, atau dosen...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.slate400),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip('Semua Status', null),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Diajukan', TopicStatus.submitted),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Disetujui', TopicStatus.approved),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Perlu Revisi', TopicStatus.revision),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Topic List
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LoadingShimmer(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTopics,
                    color: AppColors.primary,
                    child: filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 60),
                              EmptyStateView(
                                title: 'Tidak Ada Pengajuan Topik',
                                description: 'Tidak ada data usulan topik yang sesuai dengan filter pencarian.',
                                icon: Icons.folder_open_rounded,
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = filtered[index];

                              return InkWell(
                                onTap: () async {
                                  await context.push('/student/topic/detail/${item.id}');
                                  _loadTopics();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AppCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          StatusBadge.fromStatus(item.status.name.toUpperCase()),
                                          Text(
                                            AppDateFormat.formatMedium(item.createdAt),
                                            style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.school_outlined, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Mahasiswa: ${item.studentName ?? 'Mahasiswa'}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.badge_outlined, size: 14, color: AppColors.accent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Pembimbing: ${item.lecturerName ?? 'Belum Ditentukan'}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Buka Detail Evaluasi',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                                        ],
                                      ),
                                    ],
                                  ),
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

  Widget _buildStatusFilterChip(String label, TopicStatus? status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = status);
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
