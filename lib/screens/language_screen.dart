import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'id';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final settings = await SettingsService.load();
    if (!mounted) return;
    setState(() => _selectedLanguage = settings.languageCode);
  }

  Future<void> _selectLanguage(String code) async {
    final settings = SettingsService.current.copyWith(languageCode: code);
    await SettingsService.save(settings);
    BankMandiriApp.refreshSettings();
    if (!mounted) return;
    setState(() => _selectedLanguage = code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          code == 'id'
              ? 'Bahasa diubah ke Indonesia.'
              : 'Language changed to English.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'code': 'id', 'label': 'Indonesia (ID)', 'subtitle': 'Bahasa utama aplikasi'},
      {'code': 'en', 'label': 'English (EN)', 'subtitle': 'International language'},
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Bahasa',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final language = languages[index];
          final code = language['code'] as String;
          final isSelected = _selectedLanguage == code;
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              title: Text(
                language['label'] as String,
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                language['subtitle'] as String,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () => _selectLanguage(code),
            ),
          );
        },
      ),
    );
  }
}
