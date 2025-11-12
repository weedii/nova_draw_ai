import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Image Cropper Utility Service
/// Provides functionality to crop images with customizable options
class ImageCropperService {
  /// Crop an image file with customizable UI and aspect ratio
  ///
  /// Parameters:
  /// - [imageFile]: The image file to crop
  ///
  /// Returns: Cropped image file or null if user cancels
  static Future<File?> cropImage({
    required File imageFile,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF6366F1), // Indigo color
            toolbarWidgetColor: const Color(0xFFFFFFFF), // White
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockDimensionSwapEnabled: true,
            resetAspectRatioEnabled: true,
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
