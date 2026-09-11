import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/note_model.dart';
import '../../models/task_model.dart';
import '../../services/gemma_ai_service.dart';
import '../../widgets/glass_card.dart';

class GemmaChatScreen extends StatefulWidget {
  final String? initialPrompt;

  const GemmaChatScreen({super.key, this.initialPrompt});

  @override
  State<GemmaChatScreen> createState() => _GemmaChatScreenState();
}

class _GemmaChatScreenState extends State<GemmaChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<GemmaChatMessage> _messages = [];
  bool _isThinking = false;
  bool _isServerConnected = false;
  bool _modelFileFound = false;

  final List<Map<String, dynamic>> _quickPrompts = [
    {
      'icon': Icons.account_balance_wallet_rounded,
      'label': 'Audit Spending',
      'prompt': 'Can you do an audit of my monthly expenses and net savings?',
    },
    {
      'icon': Icons.menu_book_rounded,
      'label': 'DSA Study Sprint',
      'prompt': 'Create a focused DSA and coding study plan for me this week.',
    },
    {
      'icon': Icons.local_fire_department_rounded,
      'label': 'Check Habits',
      'prompt':
          'Review my habit consistency streaks and advise on how to maintain momentum.',
    },
    {
      'icon': Icons.flag_rounded,
      'label': 'Review OKRs',
      'prompt':
          'Analyze my active goals and key results. What is the next high impact action?',
    },
    {
      'icon': Icons.question_answer_rounded,
      'label': 'Mock Interview',
      'prompt':
          'Give me a challenging technical interview question on Flutter architecture with a model answer.',
    },
    {
      'icon': Icons.bolt_rounded,
      'label': 'Daily Focus',
      'prompt':
          'Give me a quick high-impact summary of what I should focus on today.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initChat();
    _checkOfflineEnvironment();
  }

  void _initChat() {
    _messages.add(
      GemmaChatMessage(
        role: 'assistant',
        content:
            '👋 **Hello Harsh! I am Gemma 4**, your on-device AI Copilot.\n\nI run **100% offline and locally** on your device without sending any data over the internet. I have real-time access to your local LifeOS database (Tasks, Expenses, Study Logs, Habits, Goals, and Career Pipeline).\n\nHow can I supercharge your productivity today?',
      ),
    );

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialPrompt!);
      });
    }
  }

  Future<void> _checkOfflineEnvironment() async {
    final aiService = GemmaAiService.instance;
    final modelExists = await aiService.checkLocalModelExists();
    final serverAlive = await aiService.pingLocalServer();

    if (mounted) {
      setState(() {
        _modelFileFound = modelExists;
        _isServerConnected = serverAlive;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _isThinking) return;

    if (presetText == null) {
      _textController.clear();
    }

    setState(() {
      _messages.add(GemmaChatMessage(role: 'user', content: text));
      _isThinking = true;
    });
    _scrollToBottom();

    final provider = context.read<LifeOsProvider>();

    try {
      final reply = await GemmaAiService.instance.askGemma(
        prompt: text,
        provider: provider,
        history: _messages,
      );

      if (mounted) {
        setState(() {
          _messages.add(GemmaChatMessage(role: 'assistant', content: reply));
          _isThinking = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            GemmaChatMessage(
              role: 'assistant',
              content:
                  '⚠️ **Offline Notice**: Unable to query the model right now. Running on-device fallback:\n\n$e',
            ),
          );
          _isThinking = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied response to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveAsNote(String content) async {
    final provider = context.read<LifeOsProvider>();
    final note = NoteModel(
      title:
          'Gemma 4 AI Insight - ${DateTime.now().day}/${DateTime.now().month}',
      content: content,
      category: 'AI Copilot',
      tags: ['Gemma4', 'OfflineAI'],
      id: '',
    );
    await provider.addNote(note);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved to Notes & Memos!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  void _createTaskFromInsight(String content) async {
    final provider = context.read<LifeOsProvider>();
    final firstLine = content
        .split('\n')
        .firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => 'Action from Gemma AI',
        )
        .replaceAll('*', '')
        .replaceAll('#', '')
        .trim();

    final task = TaskModel(
      title: firstLine.length > 50
          ? '${firstLine.substring(0, 47)}...'
          : firstLine,
      description: content,
      priority: 'high',
      category: 'Growth',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      id: '',
    );
    await provider.addTask(task);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added new high-priority Task in LifeOS!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showModelDetailsModal() {
    final aiService = GemmaAiService.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemma 4 Configuration',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '100% Offline On-Device AI Engine',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildConfigTile(
                icon: Icons.folder_zip_rounded,
                title: 'Model Architecture',
                subtitle: 'gemma-4-E4B-it (Q4_K_M GGUF - 4.97 GB)',
                trailing: _modelFileFound
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      )
                    : const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
              ),
              const SizedBox(height: 10),
              _buildConfigTile(
                icon: Icons.link_rounded,
                title: 'Local Server Endpoint',
                subtitle: '${aiService.localServerEndpoint} (Tap to change IP)',
                onTap: () => _showEditEndpointDialog(ctx),
                trailing: _isServerConnected
                    ? const Chip(
                        label: Text(
                          'ONLINE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppColors.success,
                        padding: EdgeInsets.zero,
                      )
                    : const Chip(
                        label: Text(
                          'OFFLINE ENGINE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                      ),
              ),
              const SizedBox(height: 10),
              _buildConfigTile(
                icon: Icons.shield_rounded,
                title: 'Privacy & Offline Mode',
                subtitle:
                    'Zero data leaves your device. SQLite database is processed completely locally on Android & Windows.',
                trailing: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _checkOfflineEnvironment();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isServerConnected
                                    ? 'Connected to local Gemma server!'
                                    : 'Using ultra-fast on-device RAG engine (100% offline)',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showEditEndpointDialog(BuildContext modalCtx) {
    final aiService = GemmaAiService.instance;
    final controller = TextEditingController(text: aiService.localServerEndpoint);

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return AlertDialog(
          title: const Text('Configure Local Server IP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If your PC is running LM Studio on the same Wi-Fi, enter your PC\'s Wi-Fi IP address (e.g. http://192.168.1.5:1234/v1). Otherwise leave default for 100% offline mode.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'http://192.168.1.X:1234/v1',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  await aiService.saveEndpoint(newUrl);
                  await _checkOfflineEnvironment();
                  if (mounted) {
                    Navigator.pop(dlgCtx);
                    Navigator.pop(modalCtx);
                    _showModelDetailsModal();
                  }
                }
              },
              child: const Text('Save & Test'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfigTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tileContent = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: tileContent,
      );
    }
    return tileContent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemma 4 Copilot',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isServerConnected
                            ? AppColors.success
                            : const Color(0xFF06B6D4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isServerConnected
                          ? 'GGUF Server Active'
                          : '100% On-Device Offline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Model Configuration',
            icon: const Icon(Icons.settings_suggest_rounded),
            onPressed: _showModelDetailsModal,
          ),
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              setState(() {
                _messages.clear();
                _initChat();
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Offline Badge Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.offline_bolt_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Offline Mode • No Internet Required • Private Local SQLite Context',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // Thinking / Processing Indicator
          if (_isThinking)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gemma 4 is reasoning locally...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

          // Quick Prompt Suggestion Carousel
          Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _quickPrompts[index];
                return ActionChip(
                  avatar: Icon(
                    item['icon'] as IconData,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    item['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onPressed: () => _handleSend(item['prompt'] as String),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Ask Gemma 4 anything offline...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _handleSend(),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(GemmaChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person_rounded, size: 16, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  child: SelectableText(
                    msg.content,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      height: 1.55,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Action Buttons for Assistant Message
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _copyToClipboard(msg.content),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _saveAsNote(msg.content),
                      icon: const Icon(Icons.note_add_rounded, size: 14),
                      label: const Text(
                        'Save Note',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primaryLight,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _createTaskFromInsight(msg.content),
                      icon: const Icon(Icons.add_task_rounded, size: 14),
                      label: const Text(
                        'Add Task',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
