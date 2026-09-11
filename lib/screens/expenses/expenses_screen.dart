import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';
import '../../widgets/glass_card.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredExpenses = _selectedFilter == 'All'
        ? provider.expenses
        : _selectedFilter == 'Expenses'
            ? provider.expenses.where((e) => e.type == 'expense').toList()
            : provider.expenses.where((e) => e.type == 'income').toList();

    // Category breakdown map
    final Map<String, double> categorySums = {};
    for (var exp in provider.expenses.where((e) => e.type == 'expense')) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense & Budget Tracker', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction'),
        onPressed: () => _showAddTransactionDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Overview Summary Card
            GlassCard(
              borderRadius: 20,
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFFFFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Net Cash Flow (This Month)',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(provider.netBalance),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: provider.netBalance >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBalanceColumn(
                        'Total Income',
                        Formatters.currency(provider.totalIncomeThisMonth),
                        AppColors.success,
                        Icons.arrow_downward_rounded,
                      ),
                      Container(width: 1, height: 35, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      _buildBalanceColumn(
                        'Total Spent',
                        Formatters.currency(provider.totalExpenseThisMonth),
                        AppColors.error,
                        Icons.arrow_upward_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Breakdown Section
            if (categorySums.isNotEmpty) ...[
              Text(
                'Top Spending Categories',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: categorySums.entries.map((entry) {
                    final percentage = provider.totalExpenseThisMonth > 0
                        ? (entry.value / provider.totalExpenseThisMonth)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(Formatters.currency(entry.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 6,
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Filter Tabs & Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedFilter,
                  underline: const SizedBox(),
                  items: ['All', 'Expenses', 'Income']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFilter = val!),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (filteredExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No transactions recorded yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredExpenses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final exp = filteredExpenses[index];
                  final isExp = exp.type == 'expense';

                  return GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isExp ? AppColors.error.withValues(alpha: 0.12) : AppColors.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExp ? Icons.north_east_rounded : Icons.south_west_rounded,
                            color: isExp ? AppColors.error : AppColors.success,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${exp.category} • ${exp.paymentMode}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    Formatters.dateShort(exp.date),
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isExp ? '-' : '+'}${Formatters.currency(exp.amount)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isExp ? AppColors.error : AppColors.success,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                          onPressed: () => provider.deleteExpense(exp.id),
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

  Widget _buildBalanceColumn(String label, String amount, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  void _showAddTransactionDialog(BuildContext context, LifeOsProvider provider) {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String type = 'expense';
    String category = 'Food';
    String paymentMode = 'UPI';

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
                Text('Add New Transaction', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Expense')),
                        selected: type == 'expense',
                        selectedColor: AppColors.error,
                        labelStyle: TextStyle(color: type == 'expense' ? Colors.white : null),
                        onSelected: (val) => setDialogState(() => type = 'expense'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Income')),
                        selected: type == 'income',
                        selectedColor: AppColors.success,
                        labelStyle: TextStyle(color: type == 'income' ? Colors.white : null),
                        onSelected: (val) => setDialogState(() => type = 'income'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title / Description', hintText: 'e.g., Grocery Store'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount (₹)', hintText: '500'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: ['Food', 'Transport', 'Tech', 'Bills', 'Shopping', 'Education', 'Salary', 'Health', 'Other']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => category = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: ['UPI', 'Cash', 'Card', 'NetBanking']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => paymentMode = val!),
                ),
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
                      final title = titleCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                      if (title.isEmpty || amt <= 0) return;

                      await provider.addExpense(ExpenseModel(
                        id: const Uuid().v4(),
                        title: title,
                        amount: amt,
                        type: type,
                        category: category,
                        paymentMode: paymentMode,
                        date: DateTime.now(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
