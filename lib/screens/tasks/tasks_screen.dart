import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/task_model.dart';
import '../../widgets/glass_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final todayTasks = provider.tasks.where((t) {
      if (t.dueDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(t.dueDate!) == nowStr;
    }).toList();

    final upcomingTasks = provider.tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.isAfter(DateTime.now()) && DateFormat('yyyy-MM-dd').format(t.dueDate!) != nowStr;
    }).toList();

    final completedTasks = provider.tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks & Action Items', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'All (${provider.tasks.length})'),
            Tab(text: 'Today (${todayTasks.length})'),
            Tab(text: 'Upcoming (${upcomingTasks.length})'),
            Tab(text: 'Done (${completedTasks.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Task'),
        onPressed: () => _showAddTaskDialog(context, provider),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(provider.tasks, provider, isDark),
          _buildTaskList(todayTasks, provider, isDark),
          _buildTaskList(upcomingTasks, provider, isDark),
          _buildTaskList(completedTasks, provider, isDark),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> list, LifeOsProvider provider, bool isDark) {
    if (list.isEmpty) {
      return const Center(child: Text('No tasks found in this section.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = list[index];

        Color priorityColor = AppColors.success;
        String priorityIcon = '🌱';
        if (task.priority == 'High') {
          priorityColor = AppColors.error;
          priorityIcon = '🔥';
        } else if (task.priority == 'Medium') {
          priorityColor = AppColors.warning;
          priorityIcon = '⚡';
        }

        return GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isCompleted,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                onChanged: (_) => provider.toggleTask(task),
              ),
              const SizedBox(width: 8),
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
                        color: task.isCompleted ? (isDark ? Colors.white38 : Colors.black38) : null,
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$priorityIcon ${task.priority}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                          ),
                        ),
                        if (task.tag != null)
                          Container(
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
                        if (task.dueDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 10, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.dateShort(task.dueDate!),
                                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                onPressed: () => provider.deleteTask(task.id),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, LifeOsProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    String priority = 'High';
    DateTime selectedDate = DateTime.now();

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
                Text('Create New Task', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Task Title', hintText: 'What needs to be done?'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Optional Description', hintText: 'Details or sub-steps'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: const [
                          DropdownMenuItem(value: 'High', child: Text('🔥 High')),
                          DropdownMenuItem(value: 'Medium', child: Text('⚡ Medium')),
                          DropdownMenuItem(value: 'Low', child: Text('🌱 Low')),
                        ],
                        onChanged: (val) => setDialogState(() => priority = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: tagCtrl,
                        decoration: const InputDecoration(labelText: 'Tag / Label', hintText: 'Flutter, Work'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded, color: AppColors.primary),
                  title: Text('Due Date: ${Formatters.dateShort(selectedDate)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('Change'),
                  ),
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
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;

                      // Link to active goal if one exists
                      final goalId = provider.goals.isNotEmpty ? provider.goals.first.id : null;

                      await provider.addTask(TaskModel(
                        id: const Uuid().v4(),
                        title: title,
                        description: descCtrl.text.trim(),
                        priority: priority,
                        dueDate: selectedDate,
                        tag: tagCtrl.text.trim().isEmpty ? null : tagCtrl.text.trim(),
                        linkedGoalId: goalId,
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
