// backup_seed_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Shown exactly once right after wallet creation. The mnemonic is passed in
/// from the create-wallet flow and is never persisted anywhere outside
/// SecureStorageService — this screen only ever holds it in local widget state.
class BackupSeedScreen extends StatefulWidget {
  const BackupSeedScreen({super.key, required this.mnemonic, required this.onConfirmed});

  final String mnemonic;
  final VoidCallback onConfirmed;

  @override
  State<BackupSeedScreen> createState() => _BackupSeedScreenState();
}

class _BackupSeedScreenState extends State<BackupSeedScreen> {
  bool _revealed = false;
  bool _confirmedWrittenDown = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(' ');
    return Scaffold(
      appBar: AppBar(title: const Text('Back Up Your Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Never share this phrase. Anyone with it can take your funds. '
                      'Gold Wallet support will never ask for it.',
                      style: TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  _WordGrid(words: words, blurred: !_revealed),
                  if (!_revealed)
                    Positioned.fill(
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _revealed = true),
                          icon: const Icon(Icons.visibility_rounded),
                          label: const Text('Tap to reveal'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            CheckboxListTile(
              value: _confirmedWrittenDown,
              onChanged: (v) => setState(() => _confirmedWrittenDown = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.gold,
              title: const Text(
                "I've written down my recovery phrase and stored it somewhere safe.",
                style: TextStyle(fontSize: 13),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_revealed && _confirmedWrittenDown) ? widget.onConfirmed : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordGrid extends StatelessWidget {
  const _WordGrid({required this.words, required this.blurred});
  final List<String> words;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: words.length,
      itemBuilder: (context, i) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x22D4AF37)),
          ),
          alignment: Alignment.center,
          child: Text(
            blurred ? '••••' : '${i + 1}. ${words[i]}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
