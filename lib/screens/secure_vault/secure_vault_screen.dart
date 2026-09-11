import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/life_os_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/secure_item_model.dart';
import '../../widgets/glass_card.dart';

class SecureVaultScreen extends StatefulWidget {
  const SecureVaultScreen({super.key});

  @override
  State<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends State<SecureVaultScreen> {
  final _pinController = TextEditingController();
  final Map<String, bool> _revealedSecrets = {};

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LifeOsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // PIN Authentication Lock Screen
    if (provider.isVaultLocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Encrypted Secure Vault', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.primaryLight),
                  ),
                  const SizedBox(height: 16),
                  Text('Secure Vault Locked', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your 4-digit Master PIN to unlock your encrypted credentials and keys.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    style: GoogleFonts.plusJakartaSans(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: TextStyle(letterSpacing: 8),
                    ),
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
                      onPressed: () {
                        final success = provider.unlockVault(_pinController.text.trim());
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid PIN! Default is 1234.')),
                          );
                        }
                      },
                      child: const Text('Unlock Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Default PIN: 1234', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Unlocked Vault View
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Vault', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Lock Vault',
            icon: const Icon(Icons.lock_rounded, color: AppColors.primaryLight),
            onPressed: () => provider.lockVault(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Add Secret'),
        onPressed: () => _showAddSecretDialog(context, provider),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vault Unlocked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Credentials & keys are stored locally on your device in encrypted format.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Protected Items (${provider.secureItems.length})',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (provider.secureItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Vault is empty. Add Wi-Fi passwords, API keys, or recovery codes.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.secureItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = provider.secureItems[index];
                  final isRevealed = _revealedSecrets[item.id] ?? false;

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                              onPressed: () => provider.deleteSecureItem(item.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (item.secondaryValue != null && item.secondaryValue!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Username / SSID: ${item.secondaryValue!}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isRevealed ? item.secretValue : '••••••••••••••••••••',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    letterSpacing: isRevealed ? 0 : 2,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                                onPressed: () {
                                  setState(() => _revealedSecrets[item.id] = !isRevealed);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryLight),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: item.secretValue));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Secret copied to clipboard!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(item.notes!, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black45)),
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

  void _showAddSecretDialog(BuildContext context, LifeOsProvider provider) {
    final titleCtrl = TextEditingController();
    final secretCtrl = TextEditingController();
    final secCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'API Key';

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
            Text('Add Secret / Key', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Secret Title', hintText: 'e.g. Gemini API Key, Home Wi-Fi'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['API Key', 'Wi-Fi', 'License', 'Credentials', 'Recovery Code']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => category = val!,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: secretCtrl,
              decoration: const InputDecoration(labelText: 'Secret Value (Password, Key, Token)', hintText: 'AIzaSy... or password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: secCtrl,
              decoration: const InputDecoration(labelText: 'Secondary Info (Optional)', hintText: 'SSID or Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (Optional)', hintText: 'Where this key is used'),
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
                  if (titleCtrl.text.trim().isEmpty || secretCtrl.text.trim().isEmpty) return;
                  await provider.addSecureItem(SecureItemModel(
                    id: const Uuid().v4(),
                    title: titleCtrl.text.trim(),
                    category: category,
                    secretValue: secretCtrl.text.trim(),
                    secondaryValue: secCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Store in Encrypted Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
