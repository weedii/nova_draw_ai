import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:nova_draw_ai/core/constants/colors.dart';
import 'package:easy_localization/easy_localization.dart';

/// Image Cropper Utility Service
/// Provides functionality to crop images with customizable options
class ImageCropperService {
  /// Crop an image file with customizable UI and aspect ratio
  ///
  /// Parameters:
  /// - [imageFile]: The image file to crop
  ///
  /// Returns: Cropped image file or null if user cancels
  static Future<File?> cropImage({required File imageFile}) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 90, // 100 is the maximum quality
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'image_cropper.crop_image'.tr(),
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: AppColors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            cropFrameColor: AppColors.primary,
            cropGridColor: AppColors.primary.withValues(alpha: 0.3),
            statusBarColor: AppColors.primary,
            activeControlsWidgetColor: AppColors.accent,
          ),
          IOSUiSettings(
            title: 'image_cropper.crop_image'.tr(),
            aspectRatioLockDimensionSwapEnabled: true,
            resetAspectRatioEnabled: true,
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
        print('✅ Image cropped successfully: ${croppedFile.path}');
        return File(croppedFile.path);
      } else {
        print('⚠️  Image cropping was cancelled by user');
        return null;
      }
    } catch (e) {
      print('❌ Error cropping image: $e');
      return null;
    }
  }
}
