import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AdminThesesOverviewScreen extends ConsumerStatefulWidget {
  const AdminThesesOverviewScreen({super.key});

  @override
  ConsumerState<AdminThesesOverviewScreen> createState() => _AdminThesesOverviewScreenState();
}

class _AdminThesesOverviewScreenState extends ConsumerState<AdminThesesOverviewScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _theses = [];
  bool _isLoading = true;

  final List<String> _stageNames = [
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
    _loadTheses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTheses() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final list = await service.fetchAdminTheses();
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

  double get _averageProgress {
    if (_theses.isEmpty) return 0.0;
    final sum = _theses.fold<double>(0.0, (acc, item) {
      final p = (item['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0;
      return acc + p;
    });
    return sum / _theses.length;
  }

  List<Map<String, dynamic>> get _filteredTheses {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _theses;

    return _theses.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      final student = (t['student_profile']?['full_name'] ?? '').toString().toLowerCase();
      final nim = (t['student_profile']?['identifier_number'] ?? '').toString().toLowerCase();
      final lecturer = (t['lecturer_profile']?['full_name'] ?? '').toString().toLowerCase();
      return title.contains(q) || student.contains(q) || nim.contains(q) || lecturer.contains(q);
    }).toList();
  }

  void _showThesisMilestonesModal(Map<String, dynamic> thesis) {
    final stages = (thesis['thesis_progress'] as List<dynamic>?) ?? [];
    stages.sort((a, b) => (a['stage_order'] as int).compareTo(b['stage_order'] as int));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              thesis['title'] ?? 'Skripsi Mahasiswa',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Mahasiswa: ${thesis['student_profile']?['full_name'] ?? '-'} • Pembimbing: ${thesis['lecturer_profile']?['full_name'] ?? '-'}',
              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            const Text('Monitoring 8 Tahapan Skripsi:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800)),
            const SizedBox(height: 10),
            if (stages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Data progres tahapan belum diinisialisasi untuk skripsi ini.', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
              )
            else
              ...stages.map((st) {
                final order = st['stage_order'] as int? ?? 1;
                final name = st['stage_name'] ?? (_stageNames.length >= order ? _stageNames[order - 1] : 'Tahap $order');
                final status = (st['status'] ?? 'NOT_STARTED').toString();
                final isDone = status == 'COMPLETED';
                final isInProgress = status == 'IN_PROGRESS';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFF0FDF4) : (isInProgress ? const Color(0xFFFEF3C7) : AppColors.slate50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone ? const Color(0xFFBBF7D0) : (isInProgress ? const Color(0xFFFDE68A) : AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? AppColors.success : (isInProgress ? AppColors.warning : AppColors.slate300),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check, size: 16, color: AppColors.white)
                              : Text('$order', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDone ? const Color(0xFF065F46) : (isInProgress ? const Color(0xFF92400E) : AppColors.slate600),
                          ),
                        ),
                      ),
                      Text(
                        isDone ? 'Selesai' : (isInProgress ? 'Berjalan' : 'Belum'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDone ? AppColors.success : (isInProgress ? AppColors.warning : AppColors.slate400),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTheses;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Monitoring Laju Kelulusan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // KPI Metric Banner
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Rata-rata Progress', style: TextStyle(fontSize: 11, color: AppColors.slate600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_averageProgress.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.school_outlined, size: 18, color: AppColors.success),
                            SizedBox(width: 6),
                            Text('Skripsi Berjalan', style: TextStyle(fontSize: 11, color: AppColors.slate600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_theses.length} Mahasiswa',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari judul skripsi, mahasiswa, atau dosen...',
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
          ),

          // Theses List
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LoadingShimmer(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTheses,
                    color: AppColors.primary,
                    child: filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 60),
                              EmptyStateView(
                                title: 'Belum Ada Data Skripsi',
                                description: 'Belum ada data skripsi berjalan yang sesuai dengan pencarian.',
                                icon: Icons.timeline_rounded,
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final progressPct = (item['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0;
                              final stageOrder = item['current_stage_order'] as int? ?? 1;
                              final stageName = _stageNames.length >= stageOrder ? _stageNames[stageOrder - 1] : 'Tahap $stageOrder';
                              final studentName = item['student_profile']?['full_name'] ?? 'Mahasiswa';
                              final nim = item['student_profile']?['identifier_number'] ?? '-';
                              final lecturerName = item['lecturer_profile']?['full_name'] ?? 'Dosen Pembimbing';

                              return InkWell(
                                onTap: () => _showThesisMilestonesModal(item),
                                borderRadius: BorderRadius.circular(16),
                                child: AppCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2FF),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Tahap #$stageOrder: $stageName',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                            ),
                                          ),
                                          Text(
                                            '${progressPct.toStringAsFixed(0)}%',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item['title'] ?? 'Skripsi Tanpa Judul',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Mahasiswa: $studentName ($nim)',
                                        style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                                      ),
                                      Text(
                                        'Pembimbing: $lecturerName',
                                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                      ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progressPct / 100.0,
                                          backgroundColor: AppColors.slate200,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text('Lihat Roadmap 8 Tahap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                          SizedBox(width: 4),
                                          Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
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
}
