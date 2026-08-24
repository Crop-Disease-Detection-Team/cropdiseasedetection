import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/primary_button.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _selected = 'en';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('selectLanguage')), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(strings.t('selectLanguage'), style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (value) => setState(() => _selected = value ?? 'en'),
              child: Column(
                children: supportedLanguages.map((language) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: RadioListTile<String>(
                      value: language.code,
                      activeColor: AppColors.primary,
                      title: Text(language.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: strings.t('save'),
              onTap: () async {
                final settings = ref.read(localSettingsProvider.notifier);
                await settings.saveLanguage(_selected);
                final agreed = await settings.hasAgreement();
                if (context.mounted) context.go(agreed ? '/dashboard' : '/terms');
              },
            ),
          ],
        ),
      ),
    );
  }
}
