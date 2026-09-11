import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/wishlist_model.dart';
import '../../widgets/glass_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unpurchased = provider.wishlist.where((w) => !w.isPurchased).toList();
    final totalCost = unpurchased.fold<double>(0.0, (sum, w) => sum + w.price);

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping & Wishlist', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Add Item'),
        onPressed: () => _showAddWishDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wishlist Estimated Cost Glass Card
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primaryLight, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Wishlist Capital Target', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.currency(totalCost),
                          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                        ),
                        Text('${unpurchased.length} items planned for future purchase', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Target Items (${provider.wishlist.length})',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (provider.wishlist.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Wishlist is empty. Tap + to add items you desire!')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.wishlist.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = provider.wishlist[index];

                  Color priorityColor = Colors.grey;
                  String emoji = '🌱';
                  if (item.priority == 'High') {
                    priorityColor = AppColors.error;
                    emoji = '🔥';
                  } else if (item.priority == 'Medium') {
                    priorityColor = AppColors.warning;
                    emoji = '⚡';
                  }

                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isPurchased,
                          activeColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (_) => provider.toggleWishlistPurchased(item),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                                  color: item.isPurchased ? (isDark ? Colors.white38 : Colors.black38) : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$emoji ${item.priority}',
                                      style: TextStyle(fontSize: 10, color: priorityColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.category,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.currency(item.price),
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
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

  void _showAddWishDialog(BuildContext context, LifeOsProvider provider) {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String priority = 'High';
    String category = 'Tech';

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
            Text('Add Wishlist Item', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Sony WH-1000XM5, Monitor'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Estimated Price (₹)', hintText: '25000'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('🔥 High')),
                      DropdownMenuItem(value: 'Medium', child: Text('⚡ Medium')),
                      DropdownMenuItem(value: 'Low', child: Text('🌱 Low')),
                    ],
                    onChanged: (val) => priority = val!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Tech', 'Home', 'Fashion', 'Books', 'Tools']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => category = val!,
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
                  final p = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                  await provider.addWishlistItem(WishlistItemModel(
                    id: const Uuid().v4(),
                    title: titleCtrl.text.trim(),
                    price: p,
                    priority: priority,
                    category: category,
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save to Wishlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
