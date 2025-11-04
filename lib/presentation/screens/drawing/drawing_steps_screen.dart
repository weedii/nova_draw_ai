import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/drawing_data.dart';
import '../../../providers/drawing_provider.dart';
import '../../animations/app_animations.dart';

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
  late AnimationController _sparkleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sparkleFloat;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AppAnimations.createFadeController(vsync: this);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _sparkleController = AppAnimations.createFloatController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _sparkleFloat = AppAnimations.createFloatAnimation(
      controller: _sparkleController,
      distance: 20.0,
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _sparkleController.dispose();
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
    // TODO: Navigate to completion screen or back to selection
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
              'great_job'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Comic Sans MS',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'drawing_complete'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                context.push('/drawings/categories');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Draw More!'),
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
              '${'step'.tr()} ${stepIndex + 1}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                fontFamily: 'Comic Sans MS',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use your imagination! 🎨',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    // Decode base64 image from API
    try {
      final bytes = base64Decode(stepData.stepImg);
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
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
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
                      'Failed to load image',
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
    } catch (e) {
      // Fallback to placeholder
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
            const Icon(Icons.error_outline, size: 80, color: AppColors.white),
            const SizedBox(height: 16),
            Text(
              'Image Error',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Loading screen while API generates steps
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'generating_tutorial'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: 'Comic Sans MS',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Loading content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'creating_drawing_steps'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textDark.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'please_wait'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark.withValues(alpha: 0.6),
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
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'error_occurred'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: 'Comic Sans MS',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
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
                          'failed_to_generate'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error ?? 'unknown_error'.tr(),
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
                            ElevatedButton.icon(
                              onPressed: () => provider.retryLoadSteps(),
                              icon: const Icon(Icons.refresh),
                              label: Text('retry'.tr()),
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

                            // Use static data button
                            ElevatedButton.icon(
                              onPressed: () => provider.useStaticDataFallback(),
                              icon: const Icon(Icons.offline_bolt),
                              label: Text('use_offline'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
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
                  'no_steps_available'.tr(),
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
                  'drawing_complete'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.push('/drawings/categories'),
                  child: Text('back_to_categories'.tr()),
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
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          // Back button
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),

                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'drawing_steps'.tr(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${'step'.tr()} ${currentStepIndex + 1} of ${steps.length}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textDark.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Decorative sparkle
                          AppAnimatedFloat(
                            animation: _sparkleFloat,
                            child: const Text(
                              '✨',
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                        ],
                      ),
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
                                '${'step'.tr()} ${currentStepIndex + 1}',
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
                              child: ElevatedButton(
                                onPressed: _previousStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.arrow_back, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Previous',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (provider.hasPreviousStep)
                            const SizedBox(width: 16),

                          // Next/Finish button
                          Expanded(
                            flex: provider.hasPreviousStep ? 1 : 1,
                            child: ElevatedButton(
                              onPressed: _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 8,
                                shadowColor: AppColors.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    !provider.hasNextStep
                                        ? 'finish_drawing'.tr()
                                        : 'next_step'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    !provider.hasNextStep
                                        ? Icons.check_circle
                                        : Icons.arrow_forward,
                                    size: 20,
                                  ),
                                ],
                              ),
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
