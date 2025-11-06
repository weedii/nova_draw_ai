import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';

class DrawingStoryScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;

  const DrawingStoryScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
  });

  @override
  State<DrawingStoryScreen> createState() => _DrawingStoryScreenState();
}

class _DrawingStoryScreenState extends State<DrawingStoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sparkleFloat;

  bool _isGeneratingStory = true;
  bool _storyGenerationFailed = false;
  String _generatedStory = '';

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AppAnimations.createFadeController(vsync: this);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _sparkleFloat = AppAnimations.createFloatAnimation(
      controller: _sparkleController,
      distance: 25.0,
    );

    // Start animations
    _fadeController.forward();

    // Simulate AI story generation
    _generateStory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _generateStory() async {
    // TODO: Replace with actual AI story generation
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      setState(() {
        _isGeneratingStory = false;
        // Simulate success/failure (90% success rate for demo)
        _storyGenerationFailed = DateTime.now().millisecond % 10 == 0;

        if (!_storyGenerationFailed) {
          // Sample generated story - this would come from AI
          _generatedStory = _getSampleStory();
        }
      });

      if (!_storyGenerationFailed) {
        _slideController.forward();
      }
    }
  }

  String _getSampleStory() {
    // This would be replaced with actual AI-generated content
    return "Once upon a time, in a magical land filled with colors and wonder, there lived a special creation that came to life through the power of imagination. This beautiful artwork tells the story of creativity and joy, where every line and color has its own magical purpose. The artist's vision transformed simple shapes into something extraordinary, creating a masterpiece that brings smiles to everyone who sees it. This drawing represents the endless possibilities that exist when we let our creativity flow freely!";
  }

  void _retryStoryGeneration() {
    setState(() {
      _isGeneratingStory = true;
      _storyGenerationFailed = false;
      _generatedStory = '';
    });
    _generateStory();
  }

  void _readStoryAloud() {
    // TODO: Implement text-to-speech functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('story.read_aloud_coming_soon'.tr()),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _saveStory() {
    // TODO: Implement save story functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('story.save_coming_soon'.tr()),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareStory() {
    // TODO: Implement share story functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('story.share_coming_soon'.tr()),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _createAnotherStory() {
    context.push('/drawings/categories');
  }

  @override
  Widget build(BuildContext context) {
    // Show full screen loading when generating story
    if (_isGeneratingStory) {
      return _buildGeneratingView();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _storyGenerationFailed
                                      ? 'story.story_failed'.tr()
                                      : 'story.your_story'.tr(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppAnimatedFloat(
                                  animation: _sparkleFloat,
                                  child: Text(
                                    _storyGenerationFailed ? '😔' : '✨',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              textAlign: TextAlign.center,
                              _storyGenerationFailed
                                  ? 'story.try_again'.tr()
                                  : 'story.story_ready'.tr(),
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
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: _storyGenerationFailed
                      ? _buildErrorView()
                      : _buildStoryView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingView() {
    return CustomLoadingWidget(
      message: 'story.generating_story',
      subtitle: 'story.this_may_take',
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
              'story.story_failed'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'story.error_generating'.tr(),
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
                  onPressed: _retryStoryGeneration,
                  icon: const Icon(Icons.refresh),
                  label: Text('story.try_again'.tr()),
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
                  onPressed: _createAnotherStory,
                  icon: const Icon(Icons.palette),
                  label: Text('story.create_another'.tr()),
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

  Widget _buildStoryView() {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Drawing display
            Container(
              height: 400,
              width: double.infinity,
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
                child: _buildDrawingDisplay(),
              ),
            ),

            const SizedBox(height: 24),

            // Story content
            Container(
              height: 400,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_stories,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'story.your_story_title'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: 'Comic Sans MS',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _generatedStory,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                          height: 1.6,
                          fontFamily: 'Comic Sans MS',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _readStoryAloud,
                        icon: const Icon(Icons.volume_up),
                        label: Text('story.read_aloud'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
                        onPressed: _saveStory,
                        icon: const Icon(Icons.bookmark),
                        label: Text('story.save_story'.tr()),
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
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareStory,
                        icon: const Icon(Icons.share),
                        label: Text('story.share_story'.tr()),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createAnotherStory,
                        icon: const Icon(Icons.palette),
                        label: Text('story.create_another'.tr()),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingDisplay() {
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

      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_fix_high, size: 60, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'story.enhanced_artwork'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Comic Sans MS',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'story.your_masterpiece'.tr(),
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
