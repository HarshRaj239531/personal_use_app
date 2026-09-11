import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_card.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Generate last 7 days headers (e.g. M, T, W, T, F, S, S)
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Habit Tracker & Streaks', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Habit'),
        onPressed: () => _showAddHabitDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Momentum Glass Banner
            GlassCard(
              borderRadius: 20,
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF451A03), Color(0xFF1E1B4B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFFFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${provider.maxHabitStreak} Day Streak!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Consistency is your super-power. Don\'t break the chain.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7-Day Matrix Header
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Active Habits',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: last7Days.map((d) {
                      final dayLetter = DateFormat('E').format(d).substring(0, 1);
                      final isToday = DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(now);
                      return Column(
                        children: [
                          Text(
                            dayLetter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isToday ? AppColors.warning : Colors.grey,
                            ),
                          ),
                          Text(
                            DateFormat('d').format(d),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? AppColors.warning : Colors.grey,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Habits List
            if (provider.habits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No habits added yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.habits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final habit = provider.habits[index];
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      children: [
                        // Left: Habit Title & Streak
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${habit.streak} days',
                                    style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Right: 7 Days Circles
                        Expanded(
                          flex: 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: last7Days.map((d) {
                              final isCompleted = habit.isCompletedOn(d);
                              final isToday = DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(now);

                              return InkWell(
                                onTap: isToday ? () => provider.toggleHabitToday(habit) : null,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? AppColors.success
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                    border: isToday
                                        ? Border.all(color: AppColors.warning, width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isCompleted ? Icons.check_rounded : (isToday ? Icons.add_rounded : Icons.close_rounded),
                                      size: 14,
                                      color: isCompleted ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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

  void _showAddHabitDialog(BuildContext context, LifeOsProvider provider) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Daily Habit'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Habit Name', hintText: 'e.g., Coding, 3L Water, Reading'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await provider.addHabit(nameCtrl.text.trim(), 'check');
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create Habit'),
          ),
        ],
      ),
    );
  }
}
