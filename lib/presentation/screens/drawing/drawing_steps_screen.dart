import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../models/ui_models.dart';
import '../../../providers/drawing_provider.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

class DrawingStepsScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;

  const DrawingStepsScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
  });

  @override
  State<DrawingStepsScreen> createState() => _DrawingStepsScreenState();
}

class _DrawingStepsScreenState extends State<DrawingStepsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AppAnimations.createFadeController(vsync: this);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final provider = context.read<DrawingProvider>();

    if (provider.hasNextStep) {
      // Only update provider state - no local setState needed
      provider.nextStep();

      // Animate slide transition
      _slideController.reset();
      _slideController.forward();
    } else {
      _finishDrawing();
    }
  }

  void _previousStep() {
    final provider = context.read<DrawingProvider>();

    if (provider.hasPreviousStep) {
      // Only update provider state - no local setState needed
      provider.previousStep();

      // Animate slide transition
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _finishDrawing() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 60, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'drawing_steps.great_job'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Comic Sans MS',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'drawing_steps.drawing_complete'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 20),

            // Upload Drawing Button (Primary action)
            CustomButton(
              label: 'upload.upload_drawing',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.push(
                  '/drawings/${widget.categoryId}/${widget.drawingId}/upload',
                );
              },
              backgroundColor: AppColors.primary,
              textColor: AppColors.white,
              icon: Icons.camera_alt,
              borderRadius: 12,
            ),

            const SizedBox(height: 12),

            // Draw More Button (Secondary action)
            CustomButton(
              label: 'common.draw_another',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.push('/drawings/categories');
              },
              backgroundColor: AppColors.white,
              textColor: AppColors.primary,
              borderColor: AppColors.primary,
              variant: 'outlined',
              icon: Icons.palette,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepImage(DrawingStep stepData, int stepIndex) {
    if (stepData.stepImg.isEmpty) {
      // Show placeholder when no image is available
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.accent.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.palette, size: 80, color: AppColors.white),
            const SizedBox(height: 16),
            Text(
              '${'common.step'.tr()} ${stepIndex + 1}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                fontFamily: 'Comic Sans MS',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'drawing_steps.use_imagination'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    // Load image from URL
    return Container(
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
        child: Image.network(
          stepData.stepImg,
          fit: BoxFit.contain,
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.error.withValues(alpha: 0.8),
                    AppColors.accent.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 80,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'drawing_steps.failed_load_image'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Loading screen while API generates steps
  Widget _buildLoadingScreen() {
    return CustomLoadingWidget(
      message: 'drawing_steps.generating_tutorial',
      subtitle: 'drawing_steps.please_wait',
      showBackButton: true,
      onBackPressed: () => context.pop(),
    );
  }

  // Error screen with retry option
  Widget _buildErrorScreen(DrawingProvider provider) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              CustomAppBar(
                title: 'app_bar.error_occurred',
                emoji: '😔',
                showAnimation: false,
              ),

              // Error content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'drawing_steps.failed_to_generate'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error ?? 'drawing_steps.unknown_error'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Retry button
                            Expanded(
                              child: CustomButton(
                                label: 'common.retry',
                                onPressed: () => provider.retryLoadSteps(),
                                backgroundColor: AppColors.primary,
                                textColor: AppColors.white,
                                icon: Icons.refresh,
                                borderRadius: 16,
                              ),
                            ),
                          ],
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
    );
  }

  // Empty screen (shouldn't happen normally)
  Widget _buildEmptyScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'drawing_steps.no_steps_available'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Completion screen when all steps are done
  Widget _buildCompletionScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'drawing_steps.drawing_complete'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.push('/drawings/categories'),
                  child: Text('drawings.back_to_categories'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, provider, child) {
        // Handle different states
        if (provider.stepsState == DrawingStepsState.loading) {
          return _buildLoadingScreen();
        }

        if (provider.stepsState == DrawingStepsState.error) {
          return _buildErrorScreen(provider);
        }

        if (provider.currentSteps.isEmpty) {
          return _buildEmptyScreen();
        }

        final currentStepIndex = provider.currentStepIndex;
        final steps = provider.currentSteps;

        if (currentStepIndex >= steps.length) {
          return _buildCompletionScreen();
        }

        final currentStepData = steps[currentStepIndex];
        final isGerman = context.locale.languageCode == 'de';
        final stepText = isGerman
            ? currentStepData.stepDe
            : currentStepData.stepEn;

        return Scaffold(
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
                      title: 'app_bar.drawing_steps',
                      subtitle:
                          '${'common.step'.tr()} ${currentStepIndex + 1} ${'common.of'.tr()} ${steps.length}',
                      emoji: '✨',
                      showAnimation: true,
                    ),

                    // Progress indicator
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: LinearProgressIndicator(
                        value: (currentStepIndex + 1) / steps.length,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Main content
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              // Step title and description
                              Text(
                                '${'common.step'.tr()} ${currentStepIndex + 1}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFamily: 'Comic Sans MS',
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Step instruction
                              Text(
                                stepText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textDark.withValues(
                                    alpha: 0.8,
                                  ),
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Step image
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: _buildStepImage(
                                      currentStepData,
                                      currentStepIndex,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Navigation buttons
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          // Previous button
                          if (provider.hasPreviousStep)
                            Expanded(
                              child: CustomButton(
                                label: 'drawing_steps.previous',
                                onPressed: _previousStep,
                                backgroundColor: AppColors.white,
                                textColor: AppColors.primary,
                                borderColor: AppColors.primary,
                                variant: 'outlined',
                                icon: Icons.arrow_back,
                                borderRadius: 16,
                              ),
                            ),

                          if (provider.hasPreviousStep)
                            const SizedBox(width: 16),

                          // Next/Finish button
                          Expanded(
                            flex: provider.hasPreviousStep ? 1 : 1,
                            child: CustomButton(
                              label: !provider.hasNextStep
                                  ? 'drawing_steps.finish_drawing'
                                  : 'drawing_steps.next_step',
                              onPressed: _nextStep,
                              backgroundColor: AppColors.primary,
                              textColor: AppColors.white,
                              icon: !provider.hasNextStep
                                  ? null
                                  : Icons.arrow_forward,
                              iconPosition: 'right',
                              borderRadius: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
