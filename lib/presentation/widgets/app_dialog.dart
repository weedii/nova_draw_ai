import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/colors.dart';

/// Dialog type enum
enum DialogType {
  /// Info dialog (blue)
  info,

  /// Error dialog (red)
  error,

  /// Success dialog (green)
  success,

  /// Warning dialog (orange)
  warning,

  /// Confirmation dialog (with two buttons)
  confirmation,
}

/// Reusable dialog widget that handles info, errors, confirmation, success, and warnings
class AppDialog extends StatelessWidget {
  /// Type of dialog
  final DialogType type;

  /// Title of the dialog
  final String title;

  /// Message content
  final String message;

  /// Custom emoji/icon (optional)
  final String? emoji;

  /// Primary button text (for confirmation dialogs)
  final String? primaryButtonText;

  /// Secondary button text (for confirmation dialogs)
  final String? secondaryButtonText;

  /// Callback when primary button is pressed
  final VoidCallback? onPrimaryPressed;

  /// Callback when secondary button is pressed
  final VoidCallback? onSecondaryPressed;

  /// Whether dialog is dismissible by tapping outside
  final bool barrierDismissible;

  const AppDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.emoji,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.barrierDismissible = true,
  });

  /// Get color based on dialog type
  Color _getTypeColor() {
    switch (type) {
      case DialogType.info:
        return AppColors.primary;
      case DialogType.error:
        return AppColors.error;
      case DialogType.success:
        return AppColors.success;
      case DialogType.warning:
        return const Color(0xFFFFA500); // Orange
      case DialogType.confirmation:
        return AppColors.primary;
    }
  }

  /// Get default emoji based on dialog type
  String _getDefaultEmoji() {
    switch (type) {
      case DialogType.info:
        return 'ℹ️';
      case DialogType.error:
        return '❌';
      case DialogType.success:
        return '✅';
      case DialogType.warning:
        return '⚠️';
      case DialogType.confirmation:
        return '❓';
    }
  }

  /// Get background color for icon circle
  Color _getBackgroundColor() {
    return _getTypeColor().withValues(alpha: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();
    final displayEmoji = emoji ?? _getDefaultEmoji();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon/Emoji Circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(displayEmoji, style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: typeColor,
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

            // Buttons
            if (type == DialogType.confirmation)
              _buildConfirmationButtons(context, typeColor)
            else
              _buildSingleButton(context, typeColor),
          ],
        ),
      ),
    );
  }

  /// Build single button for info/error/success/warning dialogs
  Widget _buildSingleButton(BuildContext context, Color typeColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          onPrimaryPressed?.call();
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: typeColor,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Text(
          primaryButtonText ?? 'common.ok'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Comic Sans MS',
          ),
        ),
      ),
    );
  }

  /// Build two buttons for confirmation dialog
  Widget _buildConfirmationButtons(BuildContext context, Color typeColor) {
    return Row(
      children: [
        // Cancel/No Button
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              onSecondaryPressed?.call();
              Navigator.pop(context, false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textLight.withValues(alpha: 0.3),
              foregroundColor: AppColors.textDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Text(
              secondaryButtonText ?? 'common.cancel'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Comic Sans MS',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Confirm/Yes Button
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              onPrimaryPressed?.call();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Text(
              primaryButtonText ?? 'common.ok'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Comic Sans MS',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Static helper methods for easy usage
  // ============================================================================

  /// Show info dialog
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String? emoji,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppDialog(
        type: DialogType.info,
        title: title,
        message: message,
        emoji: emoji,
        primaryButtonText: buttonText,
        onPrimaryPressed: onPressed,
      ),
    );
  }

  /// Show error dialog
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String? emoji,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppDialog(
        type: DialogType.error,
        title: title,
        message: message,
        emoji: emoji,
        primaryButtonText: buttonText,
        onPrimaryPressed: onPressed,
      ),
    );
  }

  /// Show success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String? emoji,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppDialog(
        type: DialogType.success,
        title: title,
        message: message,
        emoji: emoji,
        primaryButtonText: buttonText,
        onPrimaryPressed: onPressed,
      ),
    );
  }

  /// Show warning dialog
  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String message,
    String? emoji,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppDialog(
        type: DialogType.warning,
        title: title,
        message: message,
        emoji: emoji,
        primaryButtonText: buttonText,
        onPrimaryPressed: onPressed,
      ),
    );
  }

  /// Show confirmation dialog (returns true if confirmed, false if cancelled)
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? emoji,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirmed,
    VoidCallback? onCancelled,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppDialog(
        type: DialogType.confirmation,
        title: title,
        message: message,
        emoji: emoji,
        primaryButtonText: confirmText,
        secondaryButtonText: cancelText,
        onPrimaryPressed: onConfirmed,
        onSecondaryPressed: onCancelled,
      ),
    );
  }
}
