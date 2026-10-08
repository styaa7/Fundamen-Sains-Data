import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ConsultationBookingScreen extends ConsumerStatefulWidget {
  const ConsultationBookingScreen({super.key});

  @override
  ConsumerState<ConsultationBookingScreen> createState() => _ConsultationBookingScreenState();
}

class _ConsultationBookingScreenState extends ConsumerState<ConsultationBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agendaController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _lecturers = [];
  String? _selectedLecturerId;

  @override
  void initState() {
    super.initState();
    _loadLecturers();
  }

  Future<void> _loadLecturers() async {
    try {
      final list = await ref.read(supabaseServiceProvider).fetchLecturers();
      if (mounted) {
        setState(() {
          _lecturers = list;
          if (list.isNotEmpty) {
            _selectedLecturerId = list.first['id'] as String;
          } else {
            _selectedLecturerId = '22222222-2222-2222-2222-222222222222';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedLecturerId = '22222222-2222-2222-2222-222222222222';
        });
      }
    }
  }

  @override
  void dispose() {
    _agendaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _endTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _handleBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      setState(() => _errorMessage = 'Jam selesai harus lebih besar dari jam mulai');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lecturerId = _selectedLecturerId ?? '22222222-2222-2222-2222-222222222222';

      await ref.read(supabaseServiceProvider).bookConsultation(
            lecturerId: lecturerId,
            scheduledStart: startDateTime,
            scheduledEnd: endDateTime,
            agenda: _agendaController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Permintaan jadwal bimbingan berhasil diajukan!'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception:', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Ajukan Jadwal Konsultasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Dosen Pembimbing
              const Text('Dosen Pembimbing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLecturerId ?? (_lecturers.isNotEmpty ? _lecturers.first['id'] : '22222222-2222-2222-2222-222222222222'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _lecturers.isNotEmpty
                        ? _lecturers.map((lec) {
                            return DropdownMenuItem<String>(
                              value: lec['id'] as String,
                              child: Text(
                                lec['full_name'] as String? ?? 'Dosen Pembimbing',
                                style: const TextStyle(fontSize: 14, color: AppColors.slate900),
                              ),
                            );
                          }).toList()
                        : const [
                            DropdownMenuItem<String>(
                              value: '22222222-2222-2222-2222-222222222222',
                              child: Text(
                                'Dr. Ir. Hendra Wijaya, M.T. (Dosen Pembimbing)',
                                style: TextStyle(fontSize: 14, color: AppColors.slate900),
                              ),
                            ),
                          ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLecturerId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tanggal
              const Text('Tanggal Konsultasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppDateFormat.formatFull(_selectedDate), style: const TextStyle(fontSize: 14, color: AppColors.slate900)),
                      const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Jam Mulai & Jam Selesai
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam Mulai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickStartTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_startTime.format(context), style: const TextStyle(fontSize: 14, color: AppColors.slate900)),
                                const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam Selesai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickEndTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_endTime.format(context), style: const TextStyle(fontSize: 14, color: AppColors.slate900)),
                                const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Agenda
              AppTextField(
                label: 'Agenda / Topik Pembahasan Konsultasi',
                hint: 'Contoh: Diskusi Bab 3 Metodologi Penelitian dan instrumen kuesioner...',
                controller: _agendaController,
                maxLines: 4,
                validator: (val) => (val == null || val.length < 10) ? 'Agenda minimal 10 karakter' : null,
              ),
              const SizedBox(height: 28),

              AppButton(
                label: 'Kirim Permintaan Konsultasi',
                onPressed: _handleBooking,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
