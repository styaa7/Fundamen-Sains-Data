import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'lecturer_student_detail_screen.dart';

class LecturerStudentsScreen extends ConsumerStatefulWidget {
  const LecturerStudentsScreen({super.key});

  @override
  ConsumerState<LecturerStudentsScreen> createState() => _LecturerStudentsScreenState();
}

class _LecturerStudentsScreenState extends ConsumerState<LecturerStudentsScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _theses = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua'; // 'Semua', 'Aktif', 'Selesai'

  static const List<String> _stageNames = [
    'Pengajuan Topik',
    'Proposal Skripsi',
    'Seminar Proposal',
    'Pengumpulan Data',
    'Analisis Data',
    'Penyusunan Naskah',
    'Seminar Hasil',
    'Sidang Akhir',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authControllerProvider).userProfile;
      final service = ref.read(supabaseServiceProvider);
      final list = await service.fetchLecturerTheses(user?.id ?? '');
      if (mounted) {
        setState(() {
          _theses = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTheses {
    final query = _searchController.text.trim().toLowerCase();

    return _theses.where((t) {
      final student = t['student_profile'];
      final name = (student?['full_name'] ?? '').toString().toLowerCase();
      final nim = (student?['identifier_number'] ?? '').toString().toLowerCase();
      final title = (t['title'] ?? '').toString().toLowerCase();

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          nim.contains(query) ||
          title.contains(query);

      final currentStage = t['current_stage_order'] as int? ?? 1;
      final progress = ((t['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0);
      final isCompleted = currentStage >= 8 && progress >= 100.0;

      if (_selectedFilter == 'Aktif') {
        return matchesQuery && !isCompleted;
      } else if (_selectedFilter == 'Selesai') {
        return matchesQuery && isCompleted;
      }
      return matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _theses.where((t) {
      final stage = t['current_stage_order'] as int? ?? 1;
      final p = ((t['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0);
      return !(stage >= 8 && p >= 100.0);
    }).length;

    final completedCount = _theses.length - activeCount;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mahasiswa Bimbingan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Daftar mahasiswa & pemantauan skripsi aktif',
              style: TextStyle(fontSize: 11.5, color: AppColors.slate500, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'Total Mahasiswa',
                      value: '${_theses.length}',
                      icon: Icons.people_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'Sedang Berjalan',
                      value: '$activeCount',
                      icon: Icons.timelapse_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'Lulus / Selesai',
                      value: '$completedCount',
                      icon: Icons.verified_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nama mahasiswa, NIM, atau topik...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.slate400),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400, size: 20),
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
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              const SizedBox(height: 12),

              // Filter Chips
              Row(
                children: [
                  _buildFilterChip('Semua', _theses.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Aktif', activeCount),
                  const SizedBox(width: 8),
                  _buildFilterChip('Selesai', completedCount),
                ],
              ),
              const SizedBox(height: 16),

              // List of Supervised Students
              if (_isLoading)
                const LoadingShimmer()
              else if (_filteredTheses.isEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: AppColors.slate100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_outline_rounded, size: 32, color: AppColors.slate400),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak Ada Mahasiswa Bimbingan Ditemukan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Tidak ada mahasiswa yang cocok dengan pencarian Anda.'
                              : 'Mahasiswa bimbingan akan muncul di sini setelah usulan topik disetujui.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredTheses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final thesis = _filteredTheses[index];
                    final student = thesis['student_profile'];
                    final studentName = student?['full_name'] ?? 'Mahasiswa';
                    final studentNim = student?['identifier_number'] ?? '-';
                    final currentStage = thesis['current_stage_order'] as int? ?? 1;
                    final progress = ((thesis['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0) / 100.0;
                    final isCompleted = currentStage >= 8 && progress >= 1.0;
                    final stageName = _stageNames.length >= currentStage
                        ? _stageNames[currentStage - 1]
                        : 'Tahap $currentStage';

                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => LecturerStudentDetailScreen(thesis: thesis),
                          ),
                        );
                        _loadStudents();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isCompleted
                                    ? AppColors.successLight
                                    : AppColors.primaryLight,
                                child: Text(
                                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'M',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'NIM: $studentNim',
                                      style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCompleted
                                        ? const Color(0xFFA7F3D0)
                                        : const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Text(
                                  isCompleted ? 'Selesai' : 'Tahap $currentStage / 8',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Topik Skripsi Judul
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 15, color: AppColors.slate400),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    thesis['title'] ?? 'Skripsi',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate800,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Progres Bar & Roadmap Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.route_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Roadmap: $stageName',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.slate100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? AppColors.success : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Action Link
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Pantau Topik & Roadmap',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.slate500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}
