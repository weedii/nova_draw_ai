import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class FloatingLanguageSelector extends StatelessWidget {
  const FloatingLanguageSelector({super.key});

  void _changeLanguage(BuildContext context, String languageCode) async {
    await context.setLocale(Locale(languageCode));
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = context.locale.languageCode;

    return Positioned(
      top: 30,
      left: 1,
      child: PopupMenuButton<String>(
        icon: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.textDark.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              currentLanguage == 'de' ? '🇩🇪' : '🇺🇸',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        offset: const Offset(-20, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        onSelected: (languageCode) => _changeLanguage(context, languageCode),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'en',
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: currentLanguage == 'en'
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text('🇺🇸', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'English',
                          style: TextStyle(
                            fontWeight: currentLanguage == 'en'
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: currentLanguage == 'en'
                                ? AppColors.primary
                                : AppColors.textDark,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'EN',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (currentLanguage == 'en')
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuItem<String>(
            value: 'de',
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: currentLanguage == 'de'
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text('🇩🇪', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deutsch',
                          style: TextStyle(
                            fontWeight: currentLanguage == 'de'
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: currentLanguage == 'de'
                                ? AppColors.primary
                                : AppColors.textDark,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'DE',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (currentLanguage == 'de')
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
