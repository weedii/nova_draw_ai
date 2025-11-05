import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A service class that handles image picking functionality from camera and gallery.
///
/// This service provides a clean interface for picking images using the image_picker
/// package, with proper error handling and user-friendly feedback.
///
/// Example usage:
/// ```dart
/// final imageService = ImagePickerService();
/// final image = await imageService.pickFromGallery();
/// if (image != null) {
///   // Use the picked image
/// }
/// ```
class ImagePickerService {
  /// The ImagePicker instance used for picking images
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the device's photo gallery.
  ///
  /// Returns a [File] object if an image was successfully picked,
  /// or null if the user canceled the operation or an error occurred.
  ///
  /// This method handles:
  /// - Opening the gallery picker
  /// - Converting XFile to File for easier usage
  /// - Error handling for permission issues
  ///
  /// Throws [Exception] if there's a critical error during the picking process.
  Future<File?> pickFromGallery() async {
    try {
      // Open the gallery picker
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800, // Limit image size for better performance
        maxHeight: 1800,
        imageQuality: 85, // Compress image to reduce file size
      );

      // Check if user picked an image
      if (pickedFile != null) {
        // Convert XFile to File for easier usage throughout the app
        return File(pickedFile.path);
      }

      // User canceled the picker
      return null;
    } catch (e) {
      // Log the error for debugging
      debugPrint('Error picking image from gallery: $e');

      // Re-throw as a more user-friendly exception
      throw Exception('Failed to pick image from gallery. Please try again.');
    }
  }

  /// Picks an image using the device's camera.
  ///
  /// Returns a [File] object if a photo was successfully taken,
  /// or null if the user canceled the operation or an error occurred.
  ///
  /// This method handles:
  /// - Opening the camera
  /// - Converting XFile to File for easier usage
  /// - Error handling for permission issues
  ///
  /// Throws [Exception] if there's a critical error during the photo capture.
  Future<File?> pickFromCamera() async {
    try {
      // Open the camera
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800, // Limit image size for better performance
        maxHeight: 1800,
        imageQuality: 85, // Compress image to reduce file size
        preferredCameraDevice: CameraDevice.rear, // Use rear camera by default
      );

      // Check if user took a photo
      if (pickedFile != null) {
        // Convert XFile to File for easier usage throughout the app
        return File(pickedFile.path);
      }

      // User canceled the camera
      return null;
    } catch (e) {
      // Log the error for debugging
      debugPrint('Error taking photo with camera: $e');

      // Re-throw as a more user-friendly exception
      throw Exception(
        'Failed to take photo. Please check camera permissions and try again.',
      );
    }
  }

  /// Picks an image with custom options.
  ///
  /// This method provides more control over the image picking process.
  ///
  /// Parameters:
  /// - [source]: Whether to use camera or gallery
  /// - [maxWidth]: Maximum width of the picked image
  /// - [maxHeight]: Maximum height of the picked image
  /// - [imageQuality]: Quality of the image (0-100, where 100 is highest quality)
  ///
  /// Returns a [File] object if successful, null if canceled.
  Future<File?> pickImageWithOptions({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('Error picking image with custom options: $e');
      throw Exception('Failed to pick image. Please try again.');
    }
  }

  /// Shows a bottom sheet dialog allowing the user to choose between camera and gallery.
  ///
  /// This is a convenience method that presents both options to the user
  /// in a user-friendly dialog.
  ///
  /// Parameters:
  /// - [context]: The BuildContext for showing the dialog
  ///
  /// Returns a [File] object if an image was picked, null if canceled.
  Future<File?> showImagePickerDialog(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera option
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await pickFromCamera();
                      if (context.mounted) {
                        Navigator.pop(context, image);
                      }
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.camera_alt, size: 50),
                        SizedBox(height: 8),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  // Gallery option
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await pickFromGallery();
                      if (context.mounted) {
                        Navigator.pop(context, image);
                      }
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.photo_library, size: 50),
                        SizedBox(height: 8),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
