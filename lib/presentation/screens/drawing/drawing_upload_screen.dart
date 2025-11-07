import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../services/image_picker_service.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_app_bar.dart';

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
  /// handles loading states, and provides user feedback.
  void _takePhoto() async {
    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });

      // Use the image picker service to take a photo
      final File? image = await _imagePickerService.pickFromCamera();

      if (image != null) {
        // Successfully picked an image
        setState(() {
          _pickedImage = image;
          _isLoading = false;
        });

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
  /// handles loading states, and provides user feedback.
  void _chooseFromGallery() async {
    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });

      // Use the image picker service to pick from gallery
      final File? image = await _imagePickerService.pickFromGallery();

      if (image != null) {
        // Successfully picked an image
        setState(() {
          _pickedImage = image;
          _isLoading = false;
        });

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
    context.push('/drawings/categories');
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
        _buildUploadButton(
          icon: Icons.camera_alt,
          label: 'upload.take_photo'.tr(),
          color: AppColors.primary,
          onPressed: _isLoading ? () {} : _takePhoto,
          isLoading: _isLoading,
        ),

        const SizedBox(height: 20),

        // Choose from Gallery button
        _buildUploadButton(
          icon: Icons.photo_library,
          label: 'upload.choose_from_gallery'.tr(),
          color: AppColors.secondary,
          onPressed: _isLoading ? () {} : _chooseFromGallery,
          isLoading: _isLoading,
        ),

        const SizedBox(height: 40),

        // Maybe Later button
        TextButton(
          onPressed: _isLoading ? null : _uploadLater,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textDark.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.skip_next, size: 20),
              const SizedBox(width: 8),
              Text(
                'upload.upload_later'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
        Row(
          children: [
            // Retake/Choose different image button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _pickedImage = null;
                        });
                      },
                icon: const Icon(Icons.refresh),
                label: Text('upload.choose_different'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark.withValues(alpha: 0.7),
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Upload/Continue button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadImage,
                icon: const Icon(Icons.cloud_upload),
                label: Text('upload.upload'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? color.withValues(alpha: 0.6) : color,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: isLoading ? 2 : 8,
          shadowColor: color.withValues(alpha: 0.3),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Comic Sans MS',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
