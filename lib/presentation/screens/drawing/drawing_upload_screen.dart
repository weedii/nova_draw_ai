import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_cropper.dart';
import '../../../services/image_picker_service.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

class DrawingUploadScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;

  const DrawingUploadScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
  });

  @override
  State<DrawingUploadScreen> createState() => _DrawingUploadScreenState();
}

class _DrawingUploadScreenState extends State<DrawingUploadScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Image picker service instance
  final ImagePickerService _imagePickerService = ImagePickerService();

  // State for the picked image
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AppAnimations.createFadeController(vsync: this);
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Takes a photo using the device camera
  ///
  /// This method uses the ImagePickerService to open the camera,
  /// handles loading states, provides user feedback, and allows cropping.
  void _takePhoto() async {
    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });

      // Use the image picker service to take a photo
      final File? image = await _imagePickerService.pickFromCamera();

      if (image != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('upload.photo_taken_success'.tr()),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Open image cropper
        if (mounted) {
          final croppedImage = await ImageCropperService.cropImage(
            imageFile: image,
          );

          if (croppedImage != null) {
            // Successfully cropped image
            setState(() {
              _pickedImage = croppedImage;
              _isLoading = false;
            });
          } else {
            // User canceled cropping, use original image
            setState(() {
              _pickedImage = image;
              _isLoading = false;
            });
          }
        }
      } else {
        // User canceled or no image was taken
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('upload.photo_capture_canceled'.tr()),
              backgroundColor: AppColors.textDark.withValues(alpha: 0.7),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle errors (permissions, camera not available, etc.)
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'upload.error_prefix'.tr()} ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Picks an image from the device gallery
  ///
  /// This method uses the ImagePickerService to open the gallery,
  /// handles loading states, provides user feedback, and allows cropping.
  void _chooseFromGallery() async {
    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });

      // Use the image picker service to pick from gallery
      final File? image = await _imagePickerService.pickFromGallery();

      if (image != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('upload.image_selected_success'.tr()),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Open image cropper
        if (mounted) {
          final croppedImage = await ImageCropperService.cropImage(
            imageFile: image,
          );

          if (croppedImage != null) {
            // Successfully cropped image
            setState(() {
              _pickedImage = croppedImage;
              _isLoading = false;
            });
          } else {
            // User canceled cropping, use original image
            setState(() {
              _pickedImage = image;
              _isLoading = false;
            });
          }
        }
      } else {
        // User canceled or no image was selected
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('upload.image_selection_canceled'.tr()),
              backgroundColor: AppColors.textDark.withValues(alpha: 0.7),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle errors (permissions, gallery not available, etc.)
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'upload.error_prefix'.tr()} ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _uploadLater() {
    // Navigate back to categories
    context.pushReplacement('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header
                    CustomAppBar(
                      title: 'upload.upload_drawing',
                      subtitle: 'upload.upload_subtitle',
                      emoji: '✨',
                      showAnimation: true,
                    ),

                    // Main content
                    Expanded(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              // Description
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.auto_fix_high,
                                      size: 60,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'upload.upload_description'.tr(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textDark.withValues(
                                          alpha: 0.8,
                                        ),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Image preview or upload options
                              Expanded(
                                child: _pickedImage != null
                                    ? _buildImagePreview()
                                    : _buildUploadOptions(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Full-screen loading overlay for image processing
        if (_isLoading)
          CustomLoadingWidget(
            message: 'upload.preparing_upload',
            subtitle: 'common.just_a_moment',
          ),
      ],
    );
  }

  /// Builds the upload options widget (camera and gallery buttons)
  Widget _buildUploadOptions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Take Photo button
        SizedBox(
          height: 80,
          child: CustomButton(
            label: 'upload.take_photo',
            onPressed: _isLoading ? () {} : _takePhoto,
            backgroundColor: AppColors.primary,
            textColor: AppColors.white,
            icon: Icons.camera_alt,
            iconSize: 32,
            fontSize: 18,
            height: 80,
            borderRadius: 20,
            enabled: !_isLoading,
            isLoading: _isLoading,
          ),
        ),

        const SizedBox(height: 20),

        // Choose from Gallery button
        SizedBox(
          height: 80,
          child: CustomButton(
            label: 'upload.choose_from_gallery',
            onPressed: _isLoading ? () {} : _chooseFromGallery,
            backgroundColor: AppColors.secondary,
            textColor: AppColors.white,
            icon: Icons.photo_library,
            iconSize: 32,
            fontSize: 18,
            height: 80,
            borderRadius: 20,
            enabled: !_isLoading,
            isLoading: _isLoading,
          ),
        ),

        const SizedBox(height: 40),

        // Maybe Later button
        CustomButton(
          label: 'upload.upload_later',
          onPressed: _isLoading ? () {} : _uploadLater,
          variant: 'text',
          textColor: AppColors.textDark.withValues(alpha: 0.6),
          icon: Icons.skip_next,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  /// Builds the image preview widget when an image is selected
  Widget _buildImagePreview() {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(_pickedImage!, fit: BoxFit.contain),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Action buttons
        Column(
          children: [
            // Crop button
            CustomButton(
              label: 'upload.crop_image',
              onPressed: _isLoading
                  ? () {}
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      final croppedImage =
                          await ImageCropperService.cropImage(
                        imageFile: _pickedImage!,
                      );
                      if (croppedImage != null) {
                        setState(() {
                          _pickedImage = croppedImage;
                          _isLoading = false;
                        });
                      } else {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
              backgroundColor: AppColors.secondary,
              textColor: AppColors.white,
              icon: Icons.crop,
              borderRadius: 15,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 12),

            // Retake/Choose different and Upload buttons
            Row(
              children: [
                // Retake/Choose different image button
                Expanded(
                  child: CustomButton(
                    label: 'upload.choose_different',
                    onPressed: _isLoading
                        ? () {}
                        : () {
                            setState(() {
                              _pickedImage = null;
                            });
                          },
                    backgroundColor: AppColors.textDark.withValues(alpha: 0.7),
                    textColor: AppColors.white,
                    icon: Icons.refresh,
                    borderRadius: 15,
                    enabled: !_isLoading,
                  ),
                ),

                const SizedBox(width: 16),

                // Upload/Continue button
                Expanded(
                  child: CustomButton(
                    label: 'common.upload',
                    onPressed: _isLoading ? () {} : _uploadImage,
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.white,
                    icon: Icons.cloud_upload,
                    borderRadius: 15,
                    enabled: !_isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Handles the image upload process
  void _uploadImage() {
    if (_pickedImage == null) return;

    // TODO: Implement actual upload logic here
    // For now, just show a success message and navigate
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('upload.upload_success'.tr()),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to the next screen with the uploaded image
    context.push(
      '/drawings/${widget.categoryId}/${widget.drawingId}/edit-options',
      extra: _pickedImage, // Pass the image file
    );
  }

}
