import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/daily_brief_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/metric_stat_card.dart';
import '../../widgets/quick_add_modal.dart';
import '../ai_assistant/gemma_chat_screen.dart';
import '../time_tracker/time_tracker_screen.dart';
import '../tasks/tasks_screen.dart';
import '../expenses/expenses_screen.dart';
import '../study/study_screen.dart';
import '../habits/habits_screen.dart';
import '../goals/goals_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final brief = provider.dailyBrief;
    final focusTasks = provider.tasks.take(4).toList();
    final activeHabits = provider.habits.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hub_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'LifeOS Command',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(provider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => provider.toggleTheme(),
          ),
          IconButton(
            tooltip: 'Quick Add',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => QuickAddModal.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.reloadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Daily Brief AI / Heuristic Card
              DailyBriefCard(brief: brief, userName: provider.userName),
              const SizedBox(height: 16),

              // 2. Gemma 4 AI Assistant Feature Spotlight
              GlassCard(
                borderRadius: 16,
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF172554)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  width: 1.2,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gemma 4 AI Copilot',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '100% Offline • Local SQLite Context',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF06B6D4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GemmaChatScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Chat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildAiChip(
                          context,
                          label: '📚 DSA Sprint',
                          prompt: 'Create a focused DSA and coding study plan for me this week.',
                        ),
                        _buildAiChip(
                          context,
                          label: '💰 Audit Budget',
                          prompt: 'Can you do an audit of my monthly expenses and net savings?',
                        ),
                        _buildAiChip(
                          context,
                          label: '🎤 Mock Interview',
                          prompt: 'Give me a challenging technical interview question on Flutter architecture with a model answer.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. High-Level Metric Stat Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  MetricStatCard(
                    title: 'Monthly Spend',
                    value: Formatters.currency(provider.totalExpenseThisMonth),
                    subtitle: 'Net: ${Formatters.currency(provider.netBalance)}',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppColors.primary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                  ),
                  MetricStatCard(
                    title: 'Learning Time',
                    value: '${(provider.totalStudyMinutesThisWeek / 60).toStringAsFixed(1)} hrs',
                    subtitle: '${provider.studySessions.length} sessions logged',
                    icon: Icons.menu_book_rounded,
                    accentColor: AppColors.secondary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyScreen())),
                  ),
                  MetricStatCard(
                    title: 'Focus Tasks',
                    value: '${provider.completedTasksCount} / ${provider.tasks.length}',
                    subtitle: '${provider.pendingTasksCount} pending tasks',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: AppColors.success,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())),
                  ),
                  MetricStatCard(
                    title: 'Habit Consistency',
                    value: '${provider.maxHabitStreak} Day Streak',
                    subtitle: '🔥 Peak Momentum',
                    icon: Icons.local_fire_department_rounded,
                    accentColor: AppColors.warning,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Live Active Timer / Quick Stopwatch Bar
              GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: provider.isTimerRunning
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        provider.isTimerRunning ? Icons.timer_rounded : Icons.timer_outlined,
                        color: provider.isTimerRunning ? AppColors.error : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.timerActivity,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            Formatters.formatTimerDigits(provider.timerSeconds),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: provider.isTimerRunning ? AppColors.primaryLight : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        provider.isTimerRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      onPressed: () {
                        if (provider.isTimerRunning) {
                          provider.pauseTimer();
                        } else {
                          provider.startTimer();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined, color: AppColors.warning, size: 30),
                      onPressed: () => provider.finishTimer(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TimeTrackerScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Today's Priority Focus Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Priority Focus',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (focusTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text('No tasks created yet. Tap + to add one!')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: focusTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = focusTasks[index];
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: task.isCompleted,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            onChanged: (_) => provider.toggleTask(task),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted
                                        ? (isDark ? Colors.white38 : Colors.black38)
                                        : null,
                                  ),
                                ),
                                if (task.tag != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      task.tag!,
                                      style: const TextStyle(fontSize: 10, color: AppColors.primaryLight),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (task.priority == 'High')
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // 6. Daily Habits Streak Ribbon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Habits & Streaks',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen())),
                    child: const Text('All Habits'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: activeHabits.map((h) {
                    final isDoneToday = h.isCompletedToday();
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 140,
                      child: GlassCard(
                        onTap: () => provider.toggleHabitToday(h),
                        padding: const EdgeInsets.all(12),
                        border: isDoneToday
                            ? Border.all(color: AppColors.success, width: 1.5)
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  isDoneToday ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isDoneToday ? AppColors.success : const Color(0xFF64748B),
                                  size: 20,
                                ),
                                Text(
                                  '${h.streak} 🔥',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              h.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDoneToday ? 'Completed' : 'Tap to mark',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDoneToday ? AppColors.success : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 7. Active Hierarchical OKRs / Goals Progress
              if (provider.goals.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target Objective (OKR)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                      child: const Text('Manage OKRs'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              provider.goals.first.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${(provider.goals.first.overallProgress * 100).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: provider.goals.first.overallProgress,
                          minHeight: 8,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...provider.goals.first.keyResults.map((kr) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '• ${kr.title}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                              Text(
                                '${kr.current.toInt()} / ${kr.target.toInt()} ${kr.unit}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiChip(BuildContext context, {required String label, required String prompt}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GemmaChatScreen(initialPrompt: prompt),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
