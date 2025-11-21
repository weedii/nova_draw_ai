import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/colors.dart';

/// Beautiful error dialog for showing authentication errors
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? emoji;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji ?? '❌', style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
                fontFamily: 'Comic Sans MS',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // OK Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show error dialog with custom message
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? emoji,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          ErrorDialog(title: title, message: message, emoji: emoji),
    );
  }

  /// Show error dialog with a message
  /// Pure reusable component - just displays the error message as-is
  static Future<void> showError(
    BuildContext context,
    String errorMessage, {
    String? title,
    String? emoji,
  }) {
    return show(
      context,
      title: title ?? 'common.error'.tr(),
      message: errorMessage,
      emoji: emoji,
    );
  }
}
