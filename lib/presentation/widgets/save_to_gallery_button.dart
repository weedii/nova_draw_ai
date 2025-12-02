import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saver_gallery/saver_gallery.dart';
import '../../core/constants/colors.dart';
import 'custom_button.dart';

/// Display mode for the save button
enum SaveButtonDisplayMode {
  /// Show only the icon
  iconOnly,

  /// Show only the text
  textOnly,

  /// Show both icon and text
  both,
}

class SaveToGalleryButton extends StatefulWidget {
  /// The image URL to save
  final String imageUrl;

  /// Display mode for the button
  final SaveButtonDisplayMode displayMode;

  /// Background color of the button
  final Color? backgroundColor;

  /// Text color
  final Color? textColor;

  /// Border radius
  final double borderRadius;

  /// Padding around the button
  final EdgeInsets padding;

  /// Whether the button is floating (positioned at bottom-right)
  final bool isFloating;

  /// Callback when save is successful
  final VoidCallback? onSuccess;

  /// Callback when save fails
  final Function(String error)? onError;

  /// Font size for text
  final double fontSize;

  /// Icon size
  final double iconSize;

  /// Whether to show shadow
  final bool showShadow;

  const SaveToGalleryButton({
    super.key,
    required this.imageUrl,
    this.displayMode = SaveButtonDisplayMode.both,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.isFloating = false,
    this.onSuccess,
    this.onError,
    this.fontSize = 16,
    this.iconSize = 20,
    this.showShadow = true,
  });

  @override
  State<SaveToGalleryButton> createState() => _SaveToGalleryButtonState();
}

class _SaveToGalleryButtonState extends State<SaveToGalleryButton> {
  bool _isSaving = false;

  Future<void> _saveToGallery() async {
    if (_isSaving) return;

    try {
      setState(() => _isSaving = true);

      // Show loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gallery.saving_image'.tr()),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Download image from URL
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode != 200) {
        if (mounted) {
          final errorMsg = 'gallery.failed_to_save_image'.tr();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
          widget.onError?.call(errorMsg);
        }
        setState(() => _isSaving = false);
        return;
      }

      final imageBytes = response.bodyBytes;
      if (imageBytes.isEmpty) {
        if (mounted) {
          final errorMsg = 'gallery.no_image_to_save'.tr();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
          widget.onError?.call(errorMsg);
        }
        setState(() => _isSaving = false);
        return;
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'NovaDrawAI_$timestamp';

      // Save to gallery
      final result = await SaverGallery.saveImage(
        imageBytes,
        quality: 100,
        fileName: filename,
        androidRelativePath: 'Pictures/NovaDraw',
        skipIfExists: false,
      );

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('gallery.image_saved_successfully'.tr()),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          print('✅ Image saved successfully to gallery');
          widget.onSuccess?.call();
        } else {
          final errorMsg =
              result.errorMessage ?? 'gallery.failed_to_save_image'.tr();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('gallery.failed_to_save_image'.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
          print('❌ Failed to save image: $errorMsg');
          widget.onError?.call(errorMsg);
        }
      }
    } catch (e) {
      print('❌ Error saving image: $e');
      if (mounted) {
        final errorMsg = 'gallery.error_saving_image'.tr();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onError?.call(errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build button based on display mode
    final button = _buildButton();

    if (widget.isFloating) {
      return Positioned(bottom: 16, right: 16, child: button);
    }

    return button;
  }

  Widget _buildButton() {
    switch (widget.displayMode) {
      case SaveButtonDisplayMode.iconOnly:
        return _buildIconOnlyButton();
      case SaveButtonDisplayMode.textOnly:
        return _buildTextOnlyButton();
      case SaveButtonDisplayMode.both:
        return _buildBothButton();
    }
  }

  Widget _buildIconOnlyButton() {
    // For icon-only, use emoji as a workaround since CustomButton will show icon+text
    // We'll use a space as label and only show the icon
    return GestureDetector(
      onTap: _isSaving ? null : _saveToGallery,
      child: Container(
        width: widget.iconSize + 16,
        height: widget.iconSize + 16,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.success,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isSaving
              ? SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.textColor ?? AppColors.white,
                    ),
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  Icons.download,
                  color: widget.textColor ?? AppColors.white,
                  size: widget.iconSize,
                ),
        ),
      ),
    );
  }

  Widget _buildTextOnlyButton() {
    return CustomButton(
      label: 'gallery.save',
      onPressed: _isSaving ? () {} : _saveToGallery,
      backgroundColor: widget.backgroundColor ?? AppColors.success,
      textColor: widget.textColor ?? AppColors.white,
      isLoading: _isSaving,
      borderRadius: widget.borderRadius,
      padding: widget.padding,
      fontSize: widget.fontSize,
      iconSize: widget.iconSize,
      showShadow: widget.showShadow,
      enabled: !_isSaving,
      variant: 'filled',
    );
  }

  Widget _buildBothButton() {
    return CustomButton(
      label: 'gallery.save',
      onPressed: _isSaving ? () {} : _saveToGallery,
      backgroundColor: widget.backgroundColor ?? AppColors.success,
      textColor: widget.textColor ?? AppColors.white,
      icon: Icons.download,
      isLoading: _isSaving,
      borderRadius: widget.borderRadius,
      padding: widget.padding,
      fontSize: widget.fontSize,
      iconSize: widget.iconSize,
      showShadow: widget.showShadow,
      enabled: !_isSaving,
      variant: 'filled',
    );
  }
}
