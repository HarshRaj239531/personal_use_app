import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/study_session_model.dart';
import '../../widgets/glass_card.dart';
import '../time_tracker/time_tracker_screen.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalMinutes = provider.studySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);
    final weekHours = (provider.totalStudyMinutesThisWeek / 60).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Study & Learning Tracker', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Session'),
        onPressed: () => _showAddStudyDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Study Metrics Glass Card
            GlassCard(
              borderRadius: 20,
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF0C4A6E), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFFFFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Week Study', '$weekHours hrs', Icons.calendar_view_week_rounded, AppColors.secondary),
                  Container(width: 1, height: 40, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildStatColumn('Total Study', '$totalHours hrs', Icons.all_inclusive_rounded, AppColors.primaryLight),
                  Container(width: 1, height: 40, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildStatColumn('Sessions', '${provider.studySessions.length}', Icons.menu_book_rounded, AppColors.accent),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Start Live Timer Call-to-action
            GlassCard(
              padding: const EdgeInsets.all(16),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.timer_rounded, color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Study with Live Timer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Text('Track real-time focus & automatically boost skill %', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeTrackerScreen())),
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Recent Learning Sessions',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (provider.studySessions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No study sessions logged yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.studySessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = provider.studySessions[index];
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                session.subject,
                                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.formatDuration(session.durationMinutes * 60),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session.topic,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        if (session.notes != null && session.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.notes!,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: List.generate(5, (starIdx) {
                                return Icon(
                                  starIdx < session.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            Text(
                              Formatters.date(session.date),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ],
    );
  }

  void _showAddStudyDialog(BuildContext context, LifeOsProvider provider) {
    final subjectCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '60');
    final notesCtrl = TextEditingController();
    int rating = 4;

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
                Text('Log Study Session', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject', hintText: 'e.g., Flutter, DSA, Python'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topicCtrl,
                  decoration: const InputDecoration(labelText: 'Topic Studied', hintText: 'e.g., SQLite FFI, Graph BFS'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (Minutes)', hintText: '60'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Key Takeaways / Notes', hintText: 'Summary of what you learned'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Mastery Rating: '),
                    Row(
                      children: List.generate(5, (idx) {
                        return IconButton(
                          icon: Icon(
                            idx < rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                          ),
                          onPressed: () => setDialogState(() => rating = idx + 1),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final sub = subjectCtrl.text.trim();
                      final topic = topicCtrl.text.trim();
                      final dur = int.tryParse(durationCtrl.text.trim()) ?? 30;
                      if (sub.isEmpty) return;

                      await provider.addStudySession(StudySessionModel(
                        id: const Uuid().v4(),
                        subject: sub,
                        topic: topic.isEmpty ? 'General Study' : topic,
                        durationMinutes: dur,
                        date: DateTime.now(),
                        rating: rating,
                        notes: notesCtrl.text.trim(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save & Update Skill Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
