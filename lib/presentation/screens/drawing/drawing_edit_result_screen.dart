import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/drawing_data.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_app_bar.dart';

class DrawingEditResultScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;
  final File? uploadedImage;

  const DrawingEditResultScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
    this.uploadedImage,
  });

  @override
  State<DrawingEditResultScreen> createState() =>
      _DrawingEditResultScreenState();
}

class _DrawingEditResultScreenState extends State<DrawingEditResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isProcessing = true;
  bool _processingFailed = false;
  bool _showComparison = false;
  bool _showEditOptions = false;
  EditOption? _selectedEditOption;
  List<EditOption> _availableEditOptions = [];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AppAnimations.createFadeController(vsync: this);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();

    // Load edit options for this drawing
    _loadEditOptions();

    // Simulate AI processing
    _simulateProcessing();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _loadEditOptions() {
    final drawing = DrawingData.getDrawingById(
      widget.categoryId,
      widget.drawingId,
    );
    if (drawing != null) {
      setState(() {
        _availableEditOptions = drawing.editOptions;
      });
    }
  }

  void _simulateProcessing() async {
    // TODO: Replace with actual AI processing
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() {
        _isProcessing = false;
        // Simulate success/failure (80% success rate for demo)
        _processingFailed = DateTime.now().millisecond % 5 == 0;
        // Show edit options after processing is complete
        _showEditOptions =
            !_processingFailed && _availableEditOptions.isNotEmpty;
      });

      if (!_processingFailed) {
        _slideController.forward();
      }
    }
  }

  void _retryProcessing() {
    setState(() {
      _isProcessing = true;
      _processingFailed = false;
    });
    _simulateProcessing();
  }

  void _toggleComparison() {
    setState(() {
      _showComparison = !_showComparison;
    });
  }

  void _saveDrawing() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Save functionality will be implemented soon! 💾'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _createStory() {
    context.push(
      '/drawings/${widget.categoryId}/${widget.drawingId}/story',
      extra: widget.uploadedImage,
    );
  }

  void _drawAnother() {
    context.push('/drawings/categories');
  }

  void _selectEditOption(EditOption option) {
    setState(() {
      _selectedEditOption = option;
    });
    _applyEditOption(option);
  }

  void _applyEditOption(EditOption option) async {
    // Show processing state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('edit_options.processing_edit'.tr()),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate edit processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('edit_options.edit_applied'.tr()),
          backgroundColor: AppColors.success,
        ),
      );

      // For now, just show the same image with a success message
      // In the future, this would apply the actual AI edit
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show full screen loading when processing
    if (_isProcessing) {
      return _buildProcessingView();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header
                CustomAppBar(
                  title: _processingFailed
                      ? 'app_bar.processing_failed'
                      : 'app_bar.enhanced_drawing',
                  subtitle: _processingFailed
                      ? 'ai_enhancement.try_again'
                      : 'ai_enhancement.artwork_enhanced',
                  emoji: _processingFailed ? '😔' : '✨',
                  showAnimation: !_processingFailed,
                ),

                // Main content
                _processingFailed ? _buildErrorView() : _buildResultView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return CustomLoadingWidget(
      message: 'ai_enhancement.processing_image',
      subtitle: 'ai_enhancement.this_may_take',
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'ai_enhancement.processing_failed'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ai_enhancement.error_enhancing'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _retryProcessing,
                  icon: const Icon(Icons.refresh),
                  label: Text('ai_enhancement.try_again'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _drawAnother,
                  icon: const Icon(Icons.palette),
                  label: Text('ai_enhancement.draw_another'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            // Enhanced image display
            Container(
              width: double.infinity,
              height: 500, // Fixed height for image
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

            // Comparison toggle
            if (!_showComparison)
              TextButton.icon(
                onPressed: _toggleComparison,
                icon: const Icon(Icons.compare, size: 20),
                label: Text('ai_enhancement.original_vs_enhanced'.tr()),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),

            const SizedBox(height: 16),

            // Edit options or action buttons
            SizedBox(
              height: _showEditOptions ? 400 : 200, // Fixed height for content
              child: _showEditOptions
                  ? _buildEditOptionsSection()
                  : _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_showComparison) {
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
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 8),
                                Text('ai_enhancement.original'.tr()),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'ai_enhancement.ai_enhanced'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.accent.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_fix_high,
                            size: 40,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text('ai_enhancement.enhanced'.tr()),
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

    // Single enhanced image view
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: widget.uploadedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                widget.uploadedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_fix_high,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ai_enhancement.enhanced_drawing_title'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ai_enhancement.artwork_enhanced'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'edit_options.choose_edit_option'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'edit_options.select_option_subtitle'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textDark.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Edit options grid
        Expanded(
          child: _availableEditOptions.isEmpty
              ? Center(
                  child: Text(
                    'edit_options.no_options_available'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _availableEditOptions.length,
                  itemBuilder: (context, index) {
                    final option = _availableEditOptions[index];
                    final isSelected = _selectedEditOption?.id == option.id;

                    return _buildEditOptionCard(option, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEditOptionCard(EditOption option, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectEditOption(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? option.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji
              Text(option.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),

              // Title
              Text(
                context.locale.languageCode == 'de'
                    ? option.titleDe
                    : option.titleEn,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? option.color : AppColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                context.locale.languageCode == 'de'
                    ? option.descriptionDe
                    : option.descriptionEn,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textDark.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
