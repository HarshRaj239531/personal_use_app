import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../widgets/glass_card.dart';

// Import All Screens
import 'dashboard/dashboard_screen.dart';
import 'expenses/expenses_screen.dart';
import 'study/study_screen.dart';
import 'time_tracker/time_tracker_screen.dart';
import 'tasks/tasks_screen.dart';
import 'notes/notes_screen.dart';
import 'goals/goals_screen.dart';
import 'habits/habits_screen.dart';
import 'jobs/jobs_screen.dart';
import 'skills/skills_screen.dart';
import 'projects/projects_screen.dart';
import 'bugs/bugs_screen.dart';
import 'ideas/ideas_screen.dart';
import 'resources/resources_screen.dart';
import 'interview_prep/interview_prep_screen.dart';
import 'journal/journal_screen.dart';
import 'documents/documents_screen.dart';
import 'subscriptions/subscriptions_screen.dart';
import 'wishlist/wishlist_screen.dart';
import 'inventory/inventory_screen.dart';
import 'secure_vault/secure_vault_screen.dart';
import 'calendar/calendar_screen.dart';
import 'calculators/calculators_screen.dart';
import 'analytics/analytics_screen.dart';
import 'settings/settings_screen.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LifeOS Hub', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategorySection(
              context,
              title: 'Core & Daily Productivity',
              subtitle: 'Daily focus, task management, learning, and cash flow',
              items: [
                _HubItem('Dashboard', 'Command center overview', Icons.dashboard_rounded, AppColors.primary, const DashboardScreen()),
                _HubItem('Expenses', 'Budget & transaction log', Icons.account_balance_wallet_rounded, AppColors.success, const ExpensesScreen()),
                _HubItem('Study Tracker', 'Learning sessions & ratings', Icons.menu_book_rounded, AppColors.secondary, const StudyScreen()),
                _HubItem('Time Tracker', 'Live stopwatch & pomodoro', Icons.timer_rounded, AppColors.primaryLight, const TimeTrackerScreen()),
                _HubItem('Tasks & Todos', 'Prioritized action items', Icons.check_circle_outline_rounded, AppColors.success, const TasksScreen()),
                _HubItem('Notes & Memos', 'Searchable thoughts & snippets', Icons.edit_note_rounded, Colors.purpleAccent, const NotesScreen()),
                _HubItem('Goals & OKRs', 'Hierarchical milestone tracking', Icons.flag_rounded, AppColors.primary, const GoalsScreen()),
                _HubItem('Habit Tracker', 'Consistency streaks matrix', Icons.local_fire_department_rounded, AppColors.warning, const HabitsScreen()),
              ],
            ),
            const SizedBox(height: 24),

            _buildCategorySection(
              context,
              title: 'Career & Developer Suite',
              subtitle: 'Job pipelines, tech stack competence, repos, and interview prep',
              items: [
                _HubItem('Job Tracker', 'Recruitment pipeline & CTC', Icons.work_rounded, AppColors.primary, const JobsScreen()),
                _HubItem('Skills Matrix', 'Competency levels & practice', Icons.psychology_rounded, AppColors.secondary, const SkillsScreen()),
                _HubItem('Project Manager', 'Coding projects & milestones', Icons.code_rounded, AppColors.primaryLight, const ProjectsScreen()),
                _HubItem('Bug Tracker', 'Mini Jira issue tracker', Icons.bug_report_rounded, AppColors.error, const BugsScreen()),
                _HubItem('Idea Bank', 'App concepts & startups', Icons.lightbulb_rounded, Colors.amber, const IdeasScreen()),
                _HubItem('Resource Library', 'Bookmarks, courses & docs', Icons.bookmark_rounded, AppColors.accent, const ResourcesScreen()),
                _HubItem('Interview Prep', 'Question bank & mock rounds', Icons.question_answer_rounded, AppColors.primary, const InterviewPrepScreen()),
              ],
            ),
            const SizedBox(height: 24),

            _buildCategorySection(
              context,
              title: 'Personal Life & Security',
              subtitle: 'Daily journals, certificates, subscriptions, and encrypted vault',
              items: [
                _HubItem('Daily Journal', 'Mood & structured reflections', Icons.auto_stories_rounded, AppColors.accent, const JournalScreen()),
                _HubItem('Document Vault', 'Marksheets & certificate registry', Icons.folder_shared_rounded, AppColors.primary, const DocumentsScreen()),
                _HubItem('Subscriptions', 'Recurring bills & burn rate', Icons.subscriptions_rounded, AppColors.primaryLight, const SubscriptionsScreen()),
                _HubItem('Wishlist', 'Target shopping & priorities', Icons.shopping_bag_rounded, AppColors.warning, const WishlistScreen()),
                _HubItem('Inventory', 'Personal electronics & warranty', Icons.inventory_2_rounded, AppColors.secondary, const InventoryScreen()),
                _HubItem('Secure Vault', 'PIN-locked passwords & API keys', Icons.lock_rounded, AppColors.error, const SecureVaultScreen()),
              ],
            ),
            const SizedBox(height: 24),

            _buildCategorySection(
              context,
              title: 'Utilities, Analytics & Settings',
              subtitle: 'Cross-module timelines, calculators, trends, and database backups',
              items: [
                _HubItem('Life Calendar', 'Unified schedule & countdowns', Icons.calendar_month_rounded, AppColors.primary, const CalendarScreen()),
                _HubItem('Calculators', 'EMI, Salary, GST & 8 tools', Icons.calculate_rounded, AppColors.secondary, const CalculatorsScreen()),
                _HubItem('Analytics', 'Productivity index & stats', Icons.insights_rounded, AppColors.success, const AnalyticsScreen()),
                _HubItem('Settings & DB', 'Backup, restore & dark mode', Icons.settings_rounded, Colors.grey, const SettingsScreen()),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<_HubItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  _HubItem(this.title, this.subtitle, this.icon, this.color, this.screen);
}
