import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings & Database', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      provider.userName.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.userName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'LifeOS Personal Operating System',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    onPressed: () => _showEditNameDialog(context, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Appearance & Preferences
            Text('Appearance & Security', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                    title: const Text('Dark Mode (Luxury OLED Cyber Theme)'),
                    subtitle: const Text('Ultra-sleek modern dark palette with violet accents'),
                    value: provider.isDarkMode,
                    activeColor: AppColors.primary,
                    onChanged: (_) => provider.toggleTheme(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.pin_rounded, color: AppColors.primary),
                    title: const Text('Vault PIN Code'),
                    subtitle: const Text('Update 4-digit PIN for Secure Vault & Documents'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showChangePinDialog(context, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Local SQLite Database Storage
            Text('Local SQLite Storage Engine', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storage_rounded, size: 20, color: AppColors.secondary),
                          SizedBox(width: 8),
                          Text('Database File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('ACTIVE (sqflite FFI)', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildDbStat('Tasks', '${provider.tasks.length}'),
                      _buildDbStat('Expenses', '${provider.expenses.length}'),
                      _buildDbStat('Study Logs', '${provider.studySessions.length}'),
                      _buildDbStat('Habits', '${provider.habits.length}'),
                      _buildDbStat('Jobs', '${provider.jobs.length}'),
                      _buildDbStat('Skills', '${provider.skills.length}'),
                      _buildDbStat('Notes', '${provider.notes.length}'),
                      _buildDbStat('Projects', '${provider.projects.length}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Export Backup Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Export JSON Backup'),
                          onPressed: () async {
                            final jsonStr = await provider.exportBackupJson();
                            Clipboard.setData(ClipboardData(text: jsonStr));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Database backup copied to clipboard in JSON format!')),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.upload_rounded, size: 18),
                          label: const Text('Restore Backup'),
                          onPressed: () => _showRestoreDialog(context, provider),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // App Information
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('LifeOS Version', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('v2.0.0 (Command Center)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Architecture', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('Offline-First SQLite FFI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Developer', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('Built for Harsh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildDbStat(String label, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, LifeOsProvider provider) {
    final ctrl = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Display Name'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Your Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await provider.updateUserName(ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, LifeOsProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Master PIN'),
        content: TextField(
          controller: ctrl,
          maxLength: 4,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New 4-digit PIN', hintText: 'e.g., 4321'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().length == 4) {
                await provider.setUserPin(ctrl.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated successfully!')));
                }
              }
            },
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, LifeOsProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from JSON Backup'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Paste JSON content here'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = await provider.importBackupJson(ctrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Backup restored successfully!' : 'Failed to parse JSON backup.')),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
