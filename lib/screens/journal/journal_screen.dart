import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/journal_model.dart';
import '../../widgets/glass_card.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Daily Journal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Daily Reflection'),
        onPressed: () => _showAddJournalDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Past Reflections (${provider.journals.length})',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (provider.journals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No journal entries yet. Tap below to reflect on today!')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.journals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final entry = provider.journals[index];
                  final moodEmoji = _getMoodEmoji(entry.mood);

                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.date(entry.date),
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$moodEmoji Mood: ${entry.mood}',
                                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPromptItem('What happened today?', entry.whatHappened, isDark),
                        _buildPromptItem('What did I learn?', entry.whatLearned, isDark),
                        _buildPromptItem('What went well?', entry.wentWell, isDark),
                        _buildPromptItem('What could I improve?', entry.couldImprove, isDark),
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

  Widget _buildPromptItem(String question, String answer, bool isDark) {
    if (answer.trim().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(
            answer,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.3),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'Great':
        return '😊';
      case 'Good':
        return '🙂';
      case 'Neutral':
        return '😐';
      case 'Down':
        return '😔';
      case 'Stressed':
        return '😤';
      default:
        return '😊';
    }
  }

  void _showAddJournalDialog(BuildContext context, LifeOsProvider provider) {
    final happenedCtrl = TextEditingController();
    final learnedCtrl = TextEditingController();
    final wellCtrl = TextEditingController();
    final improveCtrl = TextEditingController();
    String mood = 'Great';

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Reflection Journal', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('How are you feeling today?', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Great', 'Good', 'Neutral', 'Down', 'Stressed'].map((m) {
                      final isSelected = mood == m;
                      return ChoiceChip(
                        label: Text('${_getMoodEmoji(m)} $m'),
                        selected: isSelected,
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                        onSelected: (val) => setDialogState(() => mood = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: happenedCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'What happened today?', hintText: 'Summary of activities, meetings, milestones'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: learnedCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'What did I learn?', hintText: 'Tech insights, life lessons, reading takeaways'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: wellCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'What went well?', hintText: 'Wins, focus periods, tasks finished'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: improveCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'What could I improve?', hintText: 'Habits to refine, distractions to avoid'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await provider.addJournalEntry(JournalModel(
                          id: const Uuid().v4(),
                          date: DateTime.now(),
                          mood: mood,
                          whatHappened: happenedCtrl.text.trim(),
                          whatLearned: learnedCtrl.text.trim(),
                          wentWell: wellCtrl.text.trim(),
                          couldImprove: improveCtrl.text.trim(),
                        ));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Reflection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
