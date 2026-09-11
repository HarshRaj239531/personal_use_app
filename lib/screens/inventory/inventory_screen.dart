import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/inventory_model.dart';
import '../../widgets/glass_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalWorth = provider.inventory.fold<double>(0.0, (sum, i) => sum + i.price);

    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Inventory & Assets', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.inventory_2_rounded),
        label: const Text('Add Asset'),
        onPressed: () => _showAddInventoryDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Asset Value Glass Card
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.devices_other_rounded, color: AppColors.secondary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Registered Physical Asset Worth', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.currency(totalWorth),
                          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.secondary),
                        ),
                        Text('${provider.inventory.length} devices, electronics, & items tracked', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Owned Electronics & Possessions',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (provider.inventory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No inventory items logged yet.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.inventory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = provider.inventory[index];
                  final inWarranty = item.hasActiveWarranty;

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Formatters.currency(item.price),
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(item.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Purchased: ${Formatters.date(item.purchaseDate)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (item.warrantyExpiry != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                inWarranty ? Icons.shield_rounded : Icons.shield_outlined,
                                size: 14,
                                color: inWarranty ? AppColors.success : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                inWarranty
                                    ? 'Under Warranty till ${Formatters.date(item.warrantyExpiry!)}'
                                    : 'Warranty Expired on ${Formatters.date(item.warrantyExpiry!)}',
                                style: TextStyle(fontSize: 11, color: inWarranty ? AppColors.success : Colors.grey),
                              ),
                            ],
                          ),
                        ],
                        if (item.serialNumber != null) ...[
                          const SizedBox(height: 4),
                          Text('S/N: ${item.serialNumber}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
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

  void _showAddInventoryDialog(BuildContext context, LifeOsProvider provider) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    String category = 'Electronics';

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
            Text('Register Asset / Device', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Device / Item Name', hintText: 'e.g. Dell XPS, Mechanical Keyboard'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Purchase Price (₹)', hintText: '75000'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Electronics', 'Valuables', 'Appliances', 'Gadgets', 'Documents']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => category = val!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: serialCtrl,
              decoration: const InputDecoration(labelText: 'Serial Number / S/N', hintText: 'e.g., OP12-884920'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final p = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                  await provider.addInventoryItem(InventoryItemModel(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    category: category,
                    price: p,
                    purchaseDate: DateTime.now(),
                    warrantyExpiry: DateTime.now().add(const Duration(days: 365)),
                    serialNumber: serialCtrl.text.trim(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Asset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
