import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/job_model.dart';
import '../../widgets/glass_card.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String _selectedStatus = 'All';

  final List<String> _statuses = [
    'All',
    'To Apply',
    'Applied',
    'Assessment',
    'Interview',
    'Waiting',
    'Selected',
    'Rejected'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredJobs = _selectedStatus == 'All'
        ? provider.jobs
        : provider.jobs.where((j) => j.status == _selectedStatus).toList();

    // Stats calculations
    final appliedCount = provider.jobs.where((j) => j.status == 'Applied').length;
    final assessmentCount = provider.jobs.where((j) => j.status == 'Assessment').length;
    final interviewCount = provider.jobs.where((j) => j.status == 'Interview').length;
    final selectedCount = provider.jobs.where((j) => j.status == 'Selected').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Job & Career Tracker', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Application'),
        onPressed: () => _showAddJobDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Funnel Metrics Overview
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Application Funnel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${provider.jobs.length} Total Applications', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFunnelStep('Applied', '$appliedCount', Colors.blue),
                      _buildFunnelStep('Assessments', '$assessmentCount', Colors.purple),
                      _buildFunnelStep('Interviews', '$interviewCount', Colors.amber),
                      _buildFunnelStep('Selected', '$selectedCount', AppColors.success),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                      onSelected: (val) => setState(() => _selectedStatus = status),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Job Cards List
            if (filteredJobs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No job applications matching this status.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredJobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  final statusColor = _getStatusColor(job.status);

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              job.company,
                              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                job.status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.position,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if (job.package != null && job.package!.isNotEmpty)
                              _buildInfoChip(Icons.currency_rupee_rounded, job.package!),
                            if (job.location != null && job.location!.isNotEmpty)
                              _buildInfoChip(Icons.location_on_outlined, job.location!),
                            _buildInfoChip(Icons.event_available_rounded, 'Applied: ${Formatters.dateShort(job.appliedDate)}'),
                            if (job.interviewDate != null)
                              _buildInfoChip(Icons.mic_rounded, 'Interview: ${Formatters.dateShort(job.interviewDate!)}', color: Colors.amber),
                          ],
                        ),
                        if (job.notes != null && job.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            job.notes!,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Quick Update Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Move Status: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            DropdownButton<String>(
                              value: job.status,
                              underline: const SizedBox(),
                              items: ['To Apply', 'Applied', 'Assessment', 'Interview', 'Waiting', 'Selected', 'Rejected']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (newStatus) {
                                if (newStatus != null) {
                                  provider.updateJobStatus(job.id, newStatus);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStep(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color ?? const Color(0xFF94A3B8))),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selected':
        return AppColors.success;
      case 'Interview':
        return Colors.amber;
      case 'Assessment':
        return Colors.purple;
      case 'Applied':
        return Colors.blue;
      case 'Rejected':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  void _showAddJobDialog(BuildContext context, LifeOsProvider provider) {
    final companyCtrl = TextEditingController();
    final posCtrl = TextEditingController();
    final pkgCtrl = TextEditingController(text: '₹12 LPA');
    final locCtrl = TextEditingController(text: 'Bangalore / Remote');
    final notesCtrl = TextEditingController();
    String status = 'Applied';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Job Application', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(labelText: 'Company', hintText: 'e.g., Google, Razorpay, TCS'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: posCtrl,
                  decoration: const InputDecoration(labelText: 'Position / Role', hintText: 'e.g., Flutter Engineer'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pkgCtrl,
                        decoration: const InputDecoration(labelText: 'Package / CTC', hintText: 'e.g., ₹16 LPA'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: locCtrl,
                        decoration: const InputDecoration(labelText: 'Location', hintText: 'Remote / Bangalore'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Initial Status'),
                  items: ['To Apply', 'Applied', 'Assessment', 'Interview', 'Waiting', 'Selected', 'Rejected']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => status = val!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes', hintText: 'Interview rounds, recruiter info, referral'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (companyCtrl.text.trim().isEmpty) return;
                      await provider.addJob(JobModel(
                        id: const Uuid().v4(),
                        company: companyCtrl.text.trim(),
                        position: posCtrl.text.trim().isEmpty ? 'Software Engineer' : posCtrl.text.trim(),
                        appliedDate: DateTime.now(),
                        status: status,
                        package: pkgCtrl.text.trim(),
                        location: locCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Job Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
