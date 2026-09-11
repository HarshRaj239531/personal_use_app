import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/glass_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Category calculation
    final Map<String, double> categorySums = {};
    for (var exp in provider.expenses.where((e) => e.type == 'expense')) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
    }

    // Task stats
    final totalTasks = provider.tasks.length;
    final completedTasks = provider.completedTasksCount;
    final taskRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics & Analytics Hub', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Productivity Score Card
            GlassCard(
              borderRadius: 20,
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFFFFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: (taskRate * 0.5 + (provider.maxHabitStreak / 20.0).clamp(0.0, 0.5)),
                          strokeWidth: 8,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Text(
                        '${((taskRate * 50) + (provider.maxHabitStreak * 2.5)).clamp(0, 100).toInt()}%',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LifeOS Productivity Index', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        const Text(
                          'Calculated from task completion rates, study sessions logged, and habit streaks.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Financial Breakdown
            Text(
              'Financial Flow Overview',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniMetric('Income', Formatters.currency(provider.totalIncomeThisMonth), AppColors.success),
                      _buildMiniMetric('Expenses', Formatters.currency(provider.totalExpenseThisMonth), AppColors.error),
                      _buildMiniMetric('Net Balance', Formatters.currency(provider.netBalance), AppColors.primaryLight),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...categorySums.entries.map((e) {
                    final pct = provider.totalExpenseThisMonth > 0 ? (e.value / provider.totalExpenseThisMonth) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(Formatters.currency(e.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Study & Learning Velocity
            Text(
              'Learning & Skill Development',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniMetric('Week Study', '${(provider.totalStudyMinutesThisWeek / 60).toStringAsFixed(1)} hrs', AppColors.secondary),
                      _buildMiniMetric('Tracked Skills', '${provider.skills.length}', AppColors.accent),
                      _buildMiniMetric('Peak Streak', '${provider.maxHabitStreak} Days', AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...provider.skills.take(4).map((s) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.currentLevel / 100.0,
                                minHeight: 6,
                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${s.currentLevel}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
