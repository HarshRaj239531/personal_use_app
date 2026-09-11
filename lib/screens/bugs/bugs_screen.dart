import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/bug_model.dart';
import '../../widgets/glass_card.dart';

class BugsScreen extends StatefulWidget {
  const BugsScreen({super.key});

  @override
  State<BugsScreen> createState() => _BugsScreenState();
}

class _BugsScreenState extends State<BugsScreen> {
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredBugs = _selectedStatus == 'All'
        ? provider.bugs
        : provider.bugs.where((b) => b.status == _selectedStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Bug Tracker (Mini Jira)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.bug_report_rounded),
        label: const Text('Log Bug'),
        onPressed: () => _showAddBugDialog(context, provider),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: ['All', 'Open', 'In Progress', 'Fixed'].map((st) {
                final isSelected = _selectedStatus == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(st),
                    selected: isSelected,
                    selectedColor: AppColors.error,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                    onSelected: (val) => setState(() => _selectedStatus = st),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filteredBugs.isEmpty
                ? const Center(child: Text('No bugs logged matching this filter.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredBugs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bug = filteredBugs[index];
                      final isFixed = bug.status == 'Fixed';

                      Color priorityColor = Colors.grey;
                      if (bug.priority == 'Critical') priorityColor = Colors.redAccent;
                      if (bug.priority == 'High') priorityColor = AppColors.error;
                      if (bug.priority == 'Medium') priorityColor = AppColors.warning;

                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.pest_control_rounded, size: 18, color: AppColors.error),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        bug.priority,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                                      ),
                                    ),
                                    if (bug.projectName != null && bug.projectName!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${bug.projectName}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                                DropdownButton<String>(
                                  value: bug.status,
                                  underline: const SizedBox(),
                                  items: ['Open', 'In Progress', 'Fixed']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                                      .toList(),
                                  onChanged: (newVal) {
                                    if (newVal != null) {
                                      provider.updateBugStatus(bug.id, newVal);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bug.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                decoration: isFixed ? TextDecoration.lineThrough : null,
                                color: isFixed ? (isDark ? Colors.white38 : Colors.black38) : null,
                              ),
                            ),
                            if (bug.description != null && bug.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                bug.description!,
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Reported: ${Formatters.dateShort(bug.createdAt)}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddBugDialog(BuildContext context, LifeOsProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final projCtrl = TextEditingController(text: 'HillGuard');
    String priority = 'High';

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
                Text('Report Issue / Bug', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Bug Title', hintText: 'e.g., 401 on token expiration'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Steps / Description', hintText: 'Explain behavior and fix needed'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(labelText: 'Severity'),
                        items: const [
                          DropdownMenuItem(value: 'Critical', child: Text('🚨 Critical')),
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
                        controller: projCtrl,
                        decoration: const InputDecoration(labelText: 'Project', hintText: 'e.g. HillGuard'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      await provider.addBug(BugModel(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        priority: priority,
                        projectName: projCtrl.text.trim(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Log Bug', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
