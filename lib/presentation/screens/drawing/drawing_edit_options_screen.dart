import 'dart:io';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/drawing_data.dart';
import '../../../services/actions/drawing_api_service.dart';
import '../../../services/actions/api_exceptions.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_app_bar.dart';

class DrawingEditOptionsScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;
  final File? uploadedImage;

  const DrawingEditOptionsScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
    this.uploadedImage,
  });

  @override
  State<DrawingEditOptionsScreen> createState() =>
      _DrawingEditOptionsScreenState();
}

class _DrawingEditOptionsScreenState extends State<DrawingEditOptionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isApplyingEdit = false;
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

    // Load edit options for this drawing
    _loadEditOptions();
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

  void _selectEditOption(EditOption option) {
    setState(() {
      _selectedEditOption = option;
    });
  }

  void _applyEditOption() async {
    if (_selectedEditOption == null || widget.uploadedImage == null) return;

    setState(() {
      _isApplyingEdit = true;
    });

    try {
      // Get the detailed AI prompt from the selected edit option
      final prompt = _selectedEditOption!.promptEn;

      // Call the API to edit the image
      final response = await DrawingApiService.editImage(
        imageFile: widget.uploadedImage!,
        prompt: prompt,
      );

      if (mounted && response.success) {
        // Decode base64 image to bytes
        final imageBytes = base64Decode(response.resultImage);

        // Navigate to the final result screen with the edited image
        context.pushReplacement(
          '/drawings/${widget.categoryId}/${widget.drawingId}/result',
          extra: {
            'uploadedImage': widget.uploadedImage,
            'editedImageBytes': imageBytes,
            'selectedEditOption': _selectedEditOption,
          },
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isApplyingEdit = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to edit image: ${e.message}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApplyingEdit = false;
        });

        // Show generic error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _skipEditing() {
    // Navigate to result screen without editing
    context.pushReplacement(
      '/drawings/${widget.categoryId}/${widget.drawingId}/result',
      extra: {
        'uploadedImage': widget.uploadedImage,
        'selectedEditOption': null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show applying edit loading
    if (_isApplyingEdit) {
      return _buildApplyingEditView();
    }

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
                    title: 'edit_options.choose_edit_option',
                    subtitle: 'edit_options.select_option_subtitle',
                    emoji: '🎨',
                    showAnimation: true,
                  ),

                  // Main content
                  _buildOptionsView(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyingEditView() {
    return CustomLoadingWidget(
      message: 'ai_enhancement.processing_image',
      subtitle: 'ai_enhancement.this_may_take',
    );
  }

  Widget _buildOptionsView() {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Original image display
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
                child: widget.uploadedImage != null
                    ? Image.file(
                        widget.uploadedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
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
                              const Icon(
                                Icons.image,
                                size: 60,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'edit_options.your_drawing'.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Edit options section
            _availableEditOptions.isEmpty
                ? _buildNoOptionsView()
                : _buildEditOptionsGrid(),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOptionsView() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.palette_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'edit_options.no_options_available'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOptionsGrid() {
    const cardHeight = 140.0; // Fixed height for all cards
    return Wrap(
      spacing: 12, // Horizontal spacing between items
      runSpacing: 12, // Vertical spacing between rows
      children: _availableEditOptions.map((option) {
        final isSelected = _selectedEditOption?.id == option.id;
        return SizedBox(
          width:
              (MediaQuery.of(context).size.width - 72) /
              2, // Half width minus padding and spacing
          height: cardHeight, // Fixed height for consistency
          child: _buildEditOptionCard(option, isSelected),
        );
      }).toList(),
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
            mainAxisSize: MainAxisSize.min,
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
        // Apply edit button (only show if option is selected)
        if (_selectedEditOption != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyEditOption,
              icon: const Icon(Icons.auto_fix_high),
              label: Text('edit_options.apply_edit'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedEditOption!.color,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 8,
                shadowColor: _selectedEditOption!.color.withValues(alpha: 0.3),
              ),
            ),
          ),

        if (_selectedEditOption != null) const SizedBox(height: 16),

        // Skip editing button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _skipEditing,
            icon: const Icon(Icons.skip_next),
            label: Text('edit_options.keep_original'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
