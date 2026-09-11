import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/glass_card.dart';

class TimeTrackerScreen extends StatefulWidget {
  const TimeTrackerScreen({super.key});

  @override
  State<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends State<TimeTrackerScreen> {
  final _activityController = TextEditingController(text: 'Flutter Architecture');
  String _category = 'Study';

  final List<String> _quickActivities = [
    'Flutter Study',
    'DSA Practice',
    'Job Prep',
    'HillGuard Project',
    'Reading Book',
    'Bug Fixing',
  ];

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final todayLogs = provider.timeLogs.where((l) => DateFormat('yyyy-MM-dd').format(l.date) == todayStr).toList();
    final todayTotalSeconds = todayLogs.fold<int>(0, (sum, l) => sum + l.durationSeconds) + (provider.isTimerRunning ? provider.timerSeconds : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Time Tracker & Pomodoro', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Live Big Timer Display
            GlassCard(
              borderRadius: 24,
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFFFFFFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              border: Border.all(
                color: provider.isTimerRunning ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: provider.isTimerRunning ? 2 : 1,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      provider.isTimerRunning ? '● SESSION ACTIVE' : 'STOPWATCH READY',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Formatters.formatTimerDigits(provider.timerSeconds),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.timerActivity,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      IconButton.filledTonal(
                        iconSize: 24,
                        padding: const EdgeInsets.all(14),
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => provider.resetTimer(),
                      ),
                      const SizedBox(width: 20),
                      // Play / Pause Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: provider.isTimerRunning ? AppColors.error : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                        onPressed: () {
                          if (provider.isTimerRunning) {
                            provider.pauseTimer();
                          } else {
                            provider.startTimer(
                              activity: _activityController.text.trim(),
                              category: _category,
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(provider.isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              provider.isTimerRunning ? 'Pause' : 'Start Focus',
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Finish / Save Button
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppColors.success),
                        iconSize: 24,
                        padding: const EdgeInsets.all(14),
                        icon: const Icon(Icons.check_rounded, color: Colors.white),
                        onPressed: () async {
                          await provider.finishTimer();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Session saved to Time Logs & Skill progress updated!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Activity Configuration & Quick Preset Chips
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Focus Subject / Activity', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _activityController,
                    decoration: const InputDecoration(labelText: 'Activity Name', hintText: 'e.g. Flutter Study'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Study', 'Project', 'Job', 'Reading', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Presets:', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _quickActivities.map((preset) {
                      return ActionChip(
                        label: Text(preset, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          _activityController.text = preset;
                          String cat = 'Study';
                          if (preset.contains('Project')) cat = 'Project';
                          if (preset.contains('Job')) cat = 'Job';
                          if (preset.contains('Reading')) cat = 'Reading';
                          setState(() => _category = cat);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's Total Productive Hours Banner
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Today\'s Productive Time', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        Text(
                          Formatters.formatDuration(todayTotalSeconds),
                          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Time Logs History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recorded Sessions', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${provider.timeLogs.length} total', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),

            if (provider.timeLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No recorded timer sessions yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.timeLogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = provider.timeLogs[index];
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.activity, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '${log.category} • ${Formatters.date(log.date)}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.formatDuration(log.durationSeconds),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
