import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/drawing_data.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_app_bar.dart';

class DrawingFinalResultScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;
  final File? uploadedImage;
  final Uint8List? editedImageBytes;
  final EditOption? selectedEditOption;

  const DrawingFinalResultScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
    this.uploadedImage,
    this.editedImageBytes,
    this.selectedEditOption,
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

  bool _showComparison = false;

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

  void _toggleComparison() {
    setState(() {
      _showComparison = !_showComparison;
    });
  }

  void _saveDrawing() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('final_result.save_functionality_coming'.tr()),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _createStory() {
    // Pass edited image if available, otherwise pass uploaded image
    final imageToPass = widget.editedImageBytes ?? widget.uploadedImage;
    
    context.push(
      '/drawings/${widget.categoryId}/${widget.drawingId}/story',
      extra: imageToPass,
    );
  }

  void _drawAnother() {
    context.push('/drawings/categories');
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

            const SizedBox(height: 16),

            // Comparison toggle (only if edit was applied)
            if (widget.selectedEditOption != null && !_showComparison)
              TextButton.icon(
                onPressed: _toggleComparison,
                icon: const Icon(Icons.compare, size: 20),
                label: Text('ai_enhancement.original_vs_enhanced'.tr()),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_showComparison && widget.selectedEditOption != null) {
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'ai_enhancement.original'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.border.withValues(alpha: 0.5),
                          AppColors.background.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: widget.uploadedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              widget.uploadedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'ai_enhancement.enhanced'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.selectedEditOption!.color.withValues(
                            alpha: 0.3,
                          ),
                          widget.selectedEditOption!.color.withValues(
                            alpha: 0.1,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: widget.editedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.memory(
                                  widget.editedImageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                // Overlay to simulate edit effect
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.selectedEditOption!.color
                                            .withValues(alpha: 0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),

                                // Edit option emoji overlay
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.selectedEditOption!.emoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.selectedEditOption!.emoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.auto_fix_high,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Single image view (enhanced or original)
    return widget.uploadedImage != null || widget.editedImageBytes != null
        ? Stack(
            children: [
              // Show edited image if available, otherwise show original
              if (widget.editedImageBytes != null)
                Image.memory(
                  widget.editedImageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else if (widget.uploadedImage != null)
                Image.file(
                  widget.uploadedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),

              // Edit option indicator
              if (widget.selectedEditOption != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      context.pushReplacement(
                        '/drawings/${widget.categoryId}/${widget.drawingId}/edit-options',
                        extra: widget.uploadedImage,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.selectedEditOption!.color.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: widget.selectedEditOption!.color.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.selectedEditOption!.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.auto_fix_high,
                            size: 16,
                            color: AppColors.white,
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
              child: ElevatedButton.icon(
                onPressed: _saveDrawing,
                icon: const Icon(Icons.download),
                label: Text('ai_enhancement.save_drawing'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _createStory,
                icon: const Icon(Icons.auto_stories),
                label: Text('ai_enhancement.create_story'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _drawAnother,
            icon: const Icon(Icons.palette),
            label: Text('ai_enhancement.draw_another'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}
