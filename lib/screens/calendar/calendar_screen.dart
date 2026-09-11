import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/important_date_model.dart';
import '../../widgets/glass_card.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collect all unified events:
    // 1. Important dates
    // 2. Job interview dates
    // 3. Subscriptions renewals
    // 4. Tasks due
    final List<Map<String, dynamic>> unifiedEvents = [];

    for (var d in provider.importantDates) {
      unifiedEvents.add({
        'title': d.title,
        'date': d.date,
        'category': d.category,
        'notes': d.notes,
        'icon': Icons.event_rounded,
        'color': AppColors.primaryLight,
      });
    }

    for (var j in provider.jobs.where((j) => j.interviewDate != null)) {
      unifiedEvents.add({
        'title': '${j.company} Interview Round',
        'date': j.interviewDate!,
        'category': 'Interview',
        'notes': '${j.position} • ${j.location ?? ''}',
        'icon': Icons.mic_rounded,
        'color': Colors.amber,
      });
    }

    for (var s in provider.subscriptions.where((s) => s.isActive)) {
      unifiedEvents.add({
        'title': '${s.name} Renewal',
        'date': s.nextBillingDate,
        'category': 'Payment',
        'notes': '${Formatters.currency(s.amount)} (${s.billingCycle})',
        'icon': Icons.payment_rounded,
        'color': AppColors.success,
      });
    }

    for (var t in provider.tasks.where((t) => !t.isCompleted && t.dueDate != null)) {
      unifiedEvents.add({
        'title': t.title,
        'date': t.dueDate!,
        'category': 'Task Due',
        'notes': 'Priority: ${t.priority}',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.secondary,
      });
    }

    // Sort chronologically
    unifiedEvents.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return Scaffold(
      appBar: AppBar(
        title: Text('Unified Life Calendar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.event_available_rounded),
        label: const Text('Add Date'),
        onPressed: () => _showAddDateDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connected Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Combines deadlines, interviews, subscriptions & task due dates into one schedule.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Upcoming Timeline Events (${unifiedEvents.length})',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (unifiedEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No upcoming events scheduled.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: unifiedEvents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ev = unifiedEvents[index];
                  final dt = ev['date'] as DateTime;
                  final daysLeft = dt.difference(DateTime.now()).inDays;
                  final icon = ev['icon'] as IconData;
                  final color = ev['color'] as Color;

                  String countdownText = 'Today';
                  if (daysLeft == 1) countdownText = 'Tomorrow';
                  if (daysLeft > 1) countdownText = 'In $daysLeft days';
                  if (daysLeft < 0) countdownText = 'Overdue';

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ev['category'] as String,
                                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Formatters.dateShort(dt),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ev['title'] as String,
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              if (ev['notes'] != null && (ev['notes'] as String).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  ev['notes'] as String,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            countdownText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: daysLeft <= 1 ? AppColors.warning : const Color(0xFF94A3B8),
                            ),
                          ),
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

  void _showAddDateDialog(BuildContext context, LifeOsProvider provider) {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'Deadline';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

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
                Text('Add Important Date', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Event / Deadline Title', hintText: 'e.g., Exam, Document submission'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Deadline', 'Exam', 'Interview', 'Payment', 'Birthday', 'Event']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  title: Text('Date: ${Formatters.date(selectedDate)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes', hintText: 'Time or description'),
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
                      if (titleCtrl.text.trim().isEmpty) return;
                      await provider.addImportantDate(ImportantDateModel(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        date: selectedDate,
                        category: category,
                        notes: notesCtrl.text.trim(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add to Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
