import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/project_model.dart';
import '../../widgets/glass_card.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Project Manager', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
        onPressed: () => _showAddProjectDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Software Engineering Projects (${provider.projects.length})',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (provider.projects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No projects added yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final proj = provider.projects[index];
                  final isDone = proj.progress >= 100;

                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              proj.title,
                              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDone ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isDone ? 'COMPLETED' : '${proj.progress}% DONE',
                                style: TextStyle(
                                  color: isDone ? AppColors.success : AppColors.primaryLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          proj.description,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        // Tech Stack Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: proj.technologies.split(',').map((tech) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tech.trim(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: proj.progress / 100.0,
                            minHeight: 8,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation(isDone ? AppColors.success : AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (proj.githubUrl != null)
                              Row(
                                children: [
                                  const Icon(Icons.code_rounded, size: 14, color: AppColors.primaryLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    proj.githubUrl!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.primaryLight),
                                  ),
                                ],
                              )
                            else
                              const SizedBox(),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                                  onPressed: () {
                                    provider.updateProjectProgress(proj.id, proj.progress - 10);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
                                  onPressed: () {
                                    provider.updateProjectProgress(proj.id, proj.progress + 10);
                                  },
                                ),
                              ],
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

  void _showAddProjectDialog(BuildContext context, LifeOsProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final techCtrl = TextEditingController(text: 'Flutter, Dart, SQLite');
    final gitCtrl = TextEditingController(text: 'https://github.com/harsh/');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
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
            Text('Create Coding Project', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Project Name', hintText: 'e.g. LifeOS, HillGuard'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Short Description', hintText: 'What problem does this project solve?'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: techCtrl,
              decoration: const InputDecoration(labelText: 'Technologies (comma separated)', hintText: 'Flutter, Firebase, SQLite'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: gitCtrl,
              decoration: const InputDecoration(labelText: 'GitHub Repository URL', hintText: 'https://github.com/...'),
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
                  await provider.addProject(ProjectModel(
                    id: const Uuid().v4(),
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    technologies: techCtrl.text.trim(),
                    progress: 20,
                    githubUrl: gitCtrl.text.trim(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
