import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:saver_gallery/saver_gallery.dart';
import '../../../core/constants/colors.dart';
import '../../../models/ui_models.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

class DrawingFinalResultScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;
  final String? originalImageUrl; // URL of the original uploaded image
  final String? editedImageUrl; // URL of the edited image
  final EditOption? selectedEditOption;
  final String? dbDrawingId; // Database Drawing record ID for re-editing

  const DrawingFinalResultScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
    this.originalImageUrl,
    this.editedImageUrl,
    this.selectedEditOption,
    this.dbDrawingId,
  });

  @override
  State<DrawingFinalResultScreen> createState() =>
      _DrawingFinalResultScreenState();
}

class _DrawingFinalResultScreenState extends State<DrawingFinalResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showEditedImage = true; // Track which image to display

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AppAnimations.createFadeController(vsync: this);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleImageView() {
    setState(() {
      _showEditedImage = !_showEditedImage;
    });
  }

  void _saveDrawing() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('final_result.saving_drawing'.tr()),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      // Get the image to save (prefer edited image if available)
      String? imageUrl = widget.editedImageUrl ?? widget.originalImageUrl;

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('final_result.no_image_to_save'.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Download image from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('final_result.failed_to_save_drawing'.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final imageBytes = response.bodyBytes;
      if (imageBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('final_result.no_image_to_save'.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Generate filename with timestamp (SaverGallery adds extension automatically)
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
              content: Text('final_result.drawing_saved_successfully'.tr()),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          print('✅ Drawing saved successfully to gallery');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('final_result.failed_to_save_drawing'.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
          print('❌ Failed to save drawing: ${result.errorMessage}');
        }
      }
    } catch (e) {
      print('❌ Error saving drawing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('final_result.error_saving_drawing'.tr()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _createStory() {
    // Pass the edited image URL if available, otherwise the original URL
    final imageUrl = widget.editedImageUrl ?? widget.originalImageUrl;

    if (imageUrl != null) {
      context.push(
        '/drawings/${widget.categoryId}/${widget.drawingId}/story',
        extra: {'imageUrl': imageUrl, 'dbDrawingId': widget.dbDrawingId},
      );
    }
  }

  void _drawAnother() {
    context.pushReplacement('/home');
  }

  void _editDrawingAgain() {
    // Pass the original image URL and database drawing ID for re-editing
    context.pushReplacement(
      '/drawings/${widget.categoryId}/${widget.drawingId}/edit-options',
      extra: {
        'originalImageUrl': widget.originalImageUrl,
        'dbDrawingId': widget.dbDrawingId,
      },
    );
  }

  String _getResultTitle() {
    if (widget.selectedEditOption != null) {
      return 'ai_enhancement.enhanced_drawing_title';
    }
    return 'final_result.your_amazing_drawing';
  }

  String _getResultSubtitle() {
    if (widget.selectedEditOption != null) {
      return 'ai_enhancement.artwork_enhanced';
    }
    return 'final_result.great_job_drawing';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header
                  CustomAppBar(
                    title: _getResultTitle(),
                    subtitle: _getResultSubtitle(),
                    emoji: widget.selectedEditOption != null ? '✨' : '🎨',
                    showAnimation: true,
                  ),

                  // Main content
                  _buildResultView(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Result image display
            Container(
              width: double.infinity,
              height: 500,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildImageDisplay(),
              ),
            ),

            const SizedBox(height: 24),

            // Edit option info (if applied)
            if (widget.selectedEditOption != null) _buildEditInfoCard(),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    // Single image view with switcher at bottom
    return widget.editedImageUrl != null || widget.originalImageUrl != null
        ? Stack(
            children: [
              // Show edited image if available and selected, otherwise show original
              if (_showEditedImage && widget.editedImageUrl != null)
                Image.network(
                  widget.editedImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.error.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    );
                  },
                )
              else if (!_showEditedImage && widget.originalImageUrl != null)
                Image.network(
                  widget.originalImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.error.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    );
                  },
                ),

              // Edit option emoji overlay (always displayed when edit is applied)
              if (widget.selectedEditOption != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      _editDrawingAgain();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.selectedEditOption!.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),

              // Image switcher at bottom (only if edit was applied)
              if (widget.selectedEditOption != null)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleImageView(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: !_showEditedImage
                                    ? widget.selectedEditOption!.color
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: !_showEditedImage
                                        ? AppColors.white
                                        : AppColors.textDark.withValues(
                                            alpha: 0.4,
                                          ),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'final_result.original'.tr(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: !_showEditedImage
                                          ? AppColors.white
                                          : AppColors.textDark.withValues(
                                              alpha: 0.4,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _toggleImageView(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: _showEditedImage
                                    ? widget.selectedEditOption!.color
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_fix_high,
                                    color: _showEditedImage
                                        ? AppColors.white
                                        : AppColors.textDark.withValues(
                                            alpha: 0.4,
                                          ),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'final_result.edited'.tr(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _showEditedImage
                                          ? AppColors.white
                                          : AppColors.textDark.withValues(
                                              alpha: 0.4,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          )
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.border.withValues(alpha: 0.5),
                  AppColors.background.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 60, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'final_result.your_amazing_drawing'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildEditInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.selectedEditOption!.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.selectedEditOption!.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.selectedEditOption!.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.selectedEditOption!.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.locale.languageCode == 'de'
                      ? widget.selectedEditOption!.titleDe
                      : widget.selectedEditOption!.titleEn,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.selectedEditOption!.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'edit_options.edit_applied'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: widget.selectedEditOption!.color,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'ai_enhancement.save_drawing',
                onPressed: _saveDrawing,
                backgroundColor: AppColors.success,
                textColor: AppColors.white,
                icon: Icons.download,
                borderRadius: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                label: 'common.create_story',
                onPressed: _createStory,
                backgroundColor: AppColors.accent,
                textColor: AppColors.white,
                icon: Icons.auto_stories,
                borderRadius: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomButton(
          label: 'common.draw_another',
          onPressed: _drawAnother,
          backgroundColor: AppColors.primary,
          textColor: AppColors.white,
          icon: Icons.palette,
          borderRadius: 16,
        ),
      ],
    );
  }
}
