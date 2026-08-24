import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/primary_button.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('terms')), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.t('terms'), style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'AgriVision AI provides crop disease analysis support and recommendations. It does not replace professional agricultural advice. Use scan results responsibly and follow local pesticide safety guidance.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: strings.t('agree'),
                onTap: () async {
                  await ref.read(localSettingsProvider.notifier).saveAgreement();
                  if (context.mounted) context.go('/dashboard');
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.go('/login'),
                child: Text(strings.t('disagree'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
