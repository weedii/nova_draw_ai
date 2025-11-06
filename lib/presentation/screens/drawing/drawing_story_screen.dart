import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';

class DrawingStoryScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;
  final File? uploadedImage;

  const DrawingStoryScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
    this.uploadedImage,
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

  final FlutterTts _flutterTts = FlutterTts();
  Map? _currentVoice;
  bool _isSpeaking = false;
  bool _isPaused = false;
  List<Map> _availableVoices = [];
  String _currentLanguage = 'en';

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

    // Initialize TTS
    initTTS();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _sparkleController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void initTTS() async {
    try {
      // Get current app language
      _currentLanguage = context.locale.languageCode;

      // Set language based on app locale
      String ttsLanguage = _currentLanguage == 'de' ? 'de-DE' : 'en-US';
      await _flutterTts.setLanguage(ttsLanguage);

      // Set speech rate (0.0 to 1.0)
      await _flutterTts.setSpeechRate(0.5);

      // Set volume (0.0 to 1.0)
      await _flutterTts.setVolume(0.8);

      // Set pitch (0.5 to 2.0)
      await _flutterTts.setPitch(1.0);

      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
          });
        }
      });

      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('TTS Error: $msg'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });

      // Get available voices and set appropriate voice
      _flutterTts.getVoices
          .then((data) {
            try {
              _availableVoices = List<Map>.from(data);
              _setVoiceForCurrentLanguage();
            } catch (e) {
              print('Error setting up TTS voices: $e');
            }
          })
          .catchError((error) {
            print('Error getting TTS voices: $error');
          });
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  void _setVoiceForCurrentLanguage() {
    try {
      List<Map> languageVoices;

      if (_currentLanguage == 'de') {
        // Filter for German voices
        languageVoices = _availableVoices
            .where((voice) => voice["locale"].toString().startsWith("de"))
            .toList();
      } else {
        // Filter for English voices (default)
        languageVoices = _availableVoices
            .where((voice) => voice["locale"].toString().startsWith("en"))
            .toList();
      }

      if (languageVoices.isNotEmpty) {
        _currentVoice = languageVoices.first;
        _flutterTts.setVoice({
          "name": _currentVoice!["name"],
          "locale": _currentVoice!["locale"],
        });

        print(
          'TTS Voice set: ${_currentVoice!["name"]} (${_currentVoice!["locale"]})',
        );
      } else {
        print('No voices found for language: $_currentLanguage');
      }
    } catch (e) {
      print('Error setting voice for language $_currentLanguage: $e');
    }
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

  void _readStoryAloud() async {
    try {
      // Check if language has changed and update TTS settings
      String currentAppLanguage = context.locale.languageCode;
      if (currentAppLanguage != _currentLanguage) {
        _currentLanguage = currentAppLanguage;
        await _updateTTSLanguage();
      }

      if (_isSpeaking) {
        if (_isPaused) {
          // Resume speaking
          await _flutterTts.speak(_generatedStory);
          setState(() {
            _isPaused = false;
          });
        } else {
          // Pause speaking
          await _flutterTts.pause();
          setState(() {
            _isPaused = true;
          });
        }
      } else {
        // Start speaking
        if (_generatedStory.isNotEmpty) {
          setState(() {
            _isSpeaking = true;
            _isPaused = false;
          });

          await _flutterTts.speak(_generatedStory);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('story.no_story_to_read'.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle TTS errors gracefully
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'TTS not available. Please restart the app and try again.',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );

      print('TTS Error: $e');
    }
  }

  Future<void> _updateTTSLanguage() async {
    try {
      // Set language based on current app locale
      String ttsLanguage = _currentLanguage == 'de' ? 'de-DE' : 'en-US';
      await _flutterTts.setLanguage(ttsLanguage);

      // Update voice for the new language
      _setVoiceForCurrentLanguage();

      print('TTS language updated to: $ttsLanguage');
    } catch (e) {
      print('Error updating TTS language: $e');
    }
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
              height: 500,
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
                        icon: Icon(
                          _isSpeaking
                              ? (_isPaused ? Icons.play_arrow : Icons.pause)
                              : Icons.volume_up,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isSpeaking
                                  ? (_isPaused
                                        ? 'story.resume'.tr()
                                        : 'story.pause'.tr())
                                  : 'story.read_aloud'.tr(),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _currentLanguage.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSpeaking
                              ? AppColors.textDark
                              : AppColors.primary,
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
                    size: 60,
                    color: AppColors.primary,
                  ),
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
