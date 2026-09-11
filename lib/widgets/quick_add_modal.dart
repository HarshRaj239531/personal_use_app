import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../controllers/life_os_provider.dart';
import '../core/constants/app_colors.dart';
import '../models/expense_model.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../models/study_session_model.dart';
import '../models/idea_model.dart';

class QuickAddModal extends StatefulWidget {
  const QuickAddModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickAddModal(),
    );
  }

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  int _selectedType = 0; // 0: Task, 1: Expense, 2: Note, 3: Study, 4: Idea
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _extraController = TextEditingController();

  String _priority = 'Medium';
  String _category = 'Food';
  String _expenseType = 'expense';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<LifeOsProvider>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Action Hub',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip(0, '✅ Task', Icons.check_circle_outline),
                const SizedBox(width: 8),
                _buildTypeChip(1, '💰 Expense', Icons.account_balance_wallet_outlined),
                const SizedBox(width: 8),
                _buildTypeChip(2, '📝 Note', Icons.edit_note_outlined),
                const SizedBox(width: 8),
                _buildTypeChip(3, '📚 Study', Icons.menu_book_outlined),
                const SizedBox(width: 8),
                _buildTypeChip(4, '💡 Idea', Icons.lightbulb_outline),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedType == 0) ...[
            // Task Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title', hintText: 'e.g., Solve 2 Leetcode DP problems'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('🔥 High Priority')),
                      DropdownMenuItem(value: 'Medium', child: Text('⚡ Medium Priority')),
                      DropdownMenuItem(value: 'Low', child: Text('🌱 Low Priority')),
                    ],
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _extraController,
                    decoration: const InputDecoration(labelText: 'Tag / Label', hintText: 'e.g. Flutter, DSA'),
                  ),
                ),
              ],
            ),
          ] else if (_selectedType == 1) ...[
            // Expense Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Expense / Income Title', hintText: 'e.g., Grocery Shopping, Swiggy'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', hintText: '500'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Food', 'Transport', 'Tech', 'Bills', 'Shopping', 'Education', 'Salary']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Expense'),
                    value: 'expense',
                    groupValue: _expenseType,
                    onChanged: (val) => setState(() => _expenseType = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Income'),
                    value: 'income',
                    groupValue: _expenseType,
                    onChanged: (val) => setState(() => _expenseType = val!),
                  ),
                ),
              ],
            ),
          ] else if (_selectedType == 2) ...[
            // Note Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Note Title', hintText: 'e.g. App Architecture Thoughts'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Content', hintText: 'Write down key ideas, links, or notes...'),
            ),
          ] else if (_selectedType == 3) ...[
            // Study Session Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Subject', hintText: 'e.g. Flutter, DSA, Python'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Topic', hintText: 'e.g. Riverpod, Binary Trees'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (Minutes)', hintText: '60'),
            ),
          ] else if (_selectedType == 4) ...[
            // Idea Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Idea Title', hintText: 'e.g., Offline Mesh Chat App'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _extraController,
              decoration: const InputDecoration(labelText: 'Technologies', hintText: 'Flutter, BLE, Wi-Fi Direct'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Explain the core idea and solution...'),
            ),
          ],
          const SizedBox(height: 20),
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
                if (_titleController.text.trim().isEmpty) return;
                final nav = Navigator.of(context);
                const uuid = Uuid();
                if (_selectedType == 0) {
                  await provider.addTask(TaskModel(
                    id: uuid.v4(),
                    title: _titleController.text.trim(),
                    priority: _priority,
                    tag: _extraController.text.trim().isEmpty ? null : _extraController.text.trim(),
                    dueDate: DateTime.now(),
                  ));
                } else if (_selectedType == 1) {
                  final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
                  if (amt <= 0) return;
                  await provider.addExpense(ExpenseModel(
                    id: uuid.v4(),
                    title: _titleController.text.trim(),
                    amount: amt,
                    type: _expenseType,
                    category: _category,
                    paymentMode: 'UPI',
                    date: DateTime.now(),
                  ));
                } else if (_selectedType == 2) {
                  await provider.addNote(NoteModel(
                    id: uuid.v4(),
                    title: _titleController.text.trim(),
                    content: _descController.text.trim(),
                    category: 'General',
                  ));
                } else if (_selectedType == 3) {
                  final mins = int.tryParse(_amountController.text.trim()) ?? 45;
                  await provider.addStudySession(StudySessionModel(
                    id: uuid.v4(),
                    subject: _titleController.text.trim(),
                    topic: _descController.text.trim().isEmpty ? 'General Study' : _descController.text.trim(),
                    durationMinutes: mins,
                    date: DateTime.now(),
                    rating: 4,
                  ));
                } else if (_selectedType == 4) {
                  await provider.addIdea(IdeaModel(
                    id: uuid.v4(),
                    title: _titleController.text.trim(),
                    technologies: _extraController.text.trim().isEmpty ? 'Tech Stack' : _extraController.text.trim(),
                    description: _descController.text.trim(),
                    category: 'Project',
                    priority: 'High',
                  ));
                }
                if (mounted) nav.pop();
              },
              child: Text(
                'Save to LifeOS',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(int index, String title, IconData icon) {
    final isSelected = _selectedType == index;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedType = index);
      },
    );
  }
}
