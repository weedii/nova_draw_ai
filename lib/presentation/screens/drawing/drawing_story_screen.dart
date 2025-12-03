import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../services/actions/drawing_api_service.dart';
import '../../../services/actions/api_exceptions.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

class DrawingStoryScreen extends StatefulWidget {
  final String categoryId;
  final String drawingId;
  final dynamic drawingImage; // Can be File or Uint8List
  final String? imageUrl; // URL of the edited image from Spaces
  final String? dbDrawingId; // Database Drawing record ID

  const DrawingStoryScreen({
    super.key,
    required this.categoryId,
    required this.drawingId,
    this.drawingImage,
    this.imageUrl,
    this.dbDrawingId,
  });

  @override
  State<DrawingStoryScreen> createState() => _DrawingStoryScreenState();
}

class _DrawingStoryScreenState extends State<DrawingStoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isGeneratingStory = true;
  bool _storyGenerationFailed = false;
  String _generatedStory = '';
  String _storyTitle = '';
  String? _storyImageUrl; // Image URL from the story response

  // Story viewing/creation state
  bool _storyNotFound = false; // True if story doesn't exist (show empty state)
  bool _isFetchingExistingStory = false; // True when fetching existing story

  final FlutterTts _flutterTts = FlutterTts();
  Map? _currentVoice;
  bool _isSpeaking = false;
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

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();

    // Defer context-dependent operations(both are using context.locale) to after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStory();
      initTTS();
    });
  }

  Future<void> _initializeStory() async {
    // If we have dbDrawingId and imageUrl, try to fetch existing story first
    if (widget.dbDrawingId != null && widget.imageUrl != null) {
      await _fetchExistingStory();
    } else {
      // No drawing ID or image URL, generate new story
      _generateStory();
    }
  }

  Future<void> _fetchExistingStory() async {
    try {
      setState(() {
        _isFetchingExistingStory = true;
        _isGeneratingStory = true;
        _storyGenerationFailed = false;
      });

      final story = await DrawingApiService.fetchStoryForImage(
        widget.dbDrawingId!,
        widget.imageUrl!,
      );

      if (mounted) {
        if (story != null) {
          // Get current app language
          String currentLanguage = context.locale.languageCode;

          // Select story text and title based on current app language
          String storyText = currentLanguage == 'de'
              ? (story['story_text_de'] ?? '')
              : (story['story_text_en'] ?? '');
          String storyTitle = currentLanguage == 'de'
              ? (story['title_de'] ?? '')
              : (story['title_en'] ?? '');

          // TODO: Handle missing story content (empty title or text)
          if (storyText.isEmpty || storyTitle.isEmpty) {
            print('⚠️ Story has missing content (title or text)');
            print("------------------------------------");
            print(storyTitle);
            print(storyText);
            print("------------------------------------");
            setState(() {
              _storyGenerationFailed = true;
              _isGeneratingStory = false;
              _isFetchingExistingStory = false;
            });
            return;
          }

          // Story exists - display it
          setState(() {
            _isGeneratingStory = false;
            _isFetchingExistingStory = false;
            _generatedStory = storyText;
            _storyTitle = storyTitle;
            _storyImageUrl = story['image_url'];
          });
          // Trigger slide animation for story display
          _slideController.forward();
        } else {
          // Story doesn't exist - show empty state
          setState(() {
            _storyNotFound = true;
            _isGeneratingStory = false;
            _isFetchingExistingStory = false;
          });
        }
      }
    } on ApiException catch (e) {
      // TODO: Handle specific API errors:
      // - 404: Story not found (show empty state)
      // - 401: Unauthorized (redirect to login)
      // - 403: Forbidden (show permission error)
      // - 500: Server error (show retry option)
      // - Network timeout (show connection error)
      print('❌ API Error fetching story: ${e.message}');
      if (mounted) {
        setState(() {
          _storyGenerationFailed = true;
          _isGeneratingStory = false;
          _isFetchingExistingStory = false;
        });
      }
    } catch (e) {
      // TODO: Handle other errors:
      // - JSON parsing errors
      // - Invalid response format
      // - Missing required fields
      print('❌ Unexpected error fetching story: $e');
      if (mounted) {
        setState(() {
          _storyGenerationFailed = true;
          _isGeneratingStory = false;
          _isFetchingExistingStory = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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

      // Set up completion handler - called when TTS finishes speaking
      _flutterTts.setCompletionHandler(() {
        print('✅ TTS completed speaking - resetting state');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      // Set up cancel handler - called when TTS is stopped
      _flutterTts.setCancelHandler(() {
        print('🛑 TTS cancelled - resetting state');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
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
      Map? selectedVoice;

      if (_currentLanguage == 'de') {
        // Use German voice: de-DE-language (de-DE)
        selectedVoice = _availableVoices.firstWhere(
          (voice) =>
              voice["name"] == "de-DE-language" &&
              voice["locale"].toString() == "de-DE",
          orElse: () =>
              _availableVoices
                  .where((voice) => voice["locale"].toString().startsWith("de"))
                  .firstOrNull ??
              {},
        );
      } else {
        // Use English voice: en-us-x-tpc-local (en-US)
        selectedVoice = _availableVoices.firstWhere(
          (voice) =>
              voice["name"] == "en-us-x-tpc-local" &&
              voice["locale"].toString() == "en-US",
          orElse: () =>
              _availableVoices
                  .where((voice) => voice["locale"].toString().startsWith("en"))
                  .firstOrNull ??
              {},
        );
      }

      if (selectedVoice.isNotEmpty) {
        _currentVoice = selectedVoice;
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
    // Check if we have an image URL or image data to generate story from
    if (widget.imageUrl == null && widget.drawingImage == null) {
      if (mounted) {
        setState(() {
          _isGeneratingStory = false;
          _storyGenerationFailed = true;
        });
      }
      return;
    }

    try {
      // Get current app language
      String currentLanguage = context.locale.languageCode;

      // Call the API to generate bilingual story
      // Pass imageUrl if available (from edited image), otherwise pass imageData
      final response = await DrawingApiService.createStory(
        imageData: widget.drawingImage,
        imageUrl: widget.imageUrl,
        drawingId: widget.dbDrawingId,
      );

      if (mounted) {
        // Select story text and title based on current app language
        String storyText = currentLanguage == 'de'
            ? response.storyTextDe
            : response.storyTextEn;
        String storyTitle = currentLanguage == 'de'
            ? response.titleDe
            : response.titleEn;

        setState(() {
          _isGeneratingStory = false;
          _storyGenerationFailed = false;
          _generatedStory = storyText;
          _storyTitle = storyTitle;
          _storyImageUrl = response.imageUrl; // Store image URL from response
        });

        _slideController.forward();
      }
    } on ApiException catch (e) {
      // TODO: Handle specific API errors:
      // - 400: Invalid image (show user-friendly message)
      // - 401: Unauthorized (redirect to login)
      // - 413: Image too large (show size limit message)
      // - 429: Rate limited (show retry after message)
      // - 500: Server error (show retry option)
      // - Network timeout (show connection error)
      print('❌ Story generation failed: ${e.message}');
      if (mounted) {
        setState(() {
          _isGeneratingStory = false;
          _storyGenerationFailed = true;
        });
      }
    } catch (e) {
      // TODO: Handle other errors:
      // - JSON parsing errors
      // - Invalid response format
      // - Missing required fields in response
      // - Image validation errors
      print('❌ Unexpected error during story generation: $e');
      if (mounted) {
        setState(() {
          _isGeneratingStory = false;
          _storyGenerationFailed = true;
        });
      }
    }
  }

  void _retryOnFailure() {
    setState(() {
      _isGeneratingStory = true;
      _storyGenerationFailed = false;
      _generatedStory = '';
      _storyTitle = '';
    });

    _fetchExistingStory();
  }

  void _generateNewStory() {
    // Generate a new story for the same image
    setState(() {
      _isGeneratingStory = true;
      _storyGenerationFailed = false;
      _generatedStory = '';
      _storyTitle = '';
      _isFetchingExistingStory = false;
    });
    _slideController.reset();
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
        // Currently speaking - user wants to stop
        print('🛑 Stopping TTS...');
        await _flutterTts.stop();
        setState(() {
          _isSpeaking = false;
        });
      } else {
        // Start speaking from the beginning
        if (_generatedStory.isNotEmpty) {
          print('🔊 Starting TTS...');
          setState(() {
            _isSpeaking = true;
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
      print('❌ TTS Error: $e');
      setState(() {
        _isSpeaking = false;
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

  void _createAnotherStory() {
    context.pushReplacement('/home');
  }

  @override
  Widget build(BuildContext context) {
    // Show full screen loading when generating story
    if (_isGeneratingStory) {
      return _buildGeneratingView();
    }

    // Show empty state if story not found
    if (_storyNotFound) {
      return _buildEmptyStoryState();
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
                CustomAppBar(
                  title: _storyGenerationFailed
                      ? 'app_bar.story_failed'
                      : 'app_bar.your_story',
                  subtitle: _storyGenerationFailed
                      ? 'story.try_again'
                      : 'story.story_ready',
                  emoji: _storyGenerationFailed ? '😔' : '✨',
                  showAnimation: !_storyGenerationFailed,
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
      message: _isFetchingExistingStory
          ? 'story.loading_story'
          : 'story.generating_story',
      subtitle: _isFetchingExistingStory
          ? 'story.loading_story_subtitle'
          : 'common.this_may_take',
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with animation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),

            // Error title
            Text(
              _isFetchingExistingStory
                  ? 'story.error_loading_story'.tr()
                  : 'story.story_failed'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            Text(
              _isFetchingExistingStory
                  ? 'story.error_loading_story_message'.tr()
                  : 'story.error_generating'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _retryOnFailure,
                icon: const Icon(Icons.refresh),
                label: Text('story.try_again'.tr()),
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStoryState() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                CustomAppBar(
                  title: 'story.no_story_yet',
                  subtitle: 'story.create_one_now',
                  emoji: '📖',
                  showAnimation: true,
                ),
                // Empty state content
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: widget.imageUrl != null
                                  ? Image.network(
                                      widget.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: AppColors.secondary
                                                  .withValues(alpha: 0.1),
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 60,
                                                color: AppColors.secondary,
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.1,
                                      ),
                                      child: const Icon(
                                        Icons.book_outlined,
                                        size: 60,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'story.no_story_message'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              fontFamily: 'Comic Sans MS',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'story.create_story_description'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark.withValues(alpha: 0.7),
                              fontFamily: 'Comic Sans MS',
                            ),
                          ),
                          const SizedBox(height: 32),
                          CustomButton(
                            label: 'story.create_story_now',
                            onPressed: _createStoryForImage,
                            backgroundColor: AppColors.secondary,
                            textColor: AppColors.white,
                            icon: Icons.add_circle,
                            height: 56,
                            fontSize: 16,
                            iconSize: 24,
                            borderRadius: 12,
                            showShadow: true,
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
    );
  }

  void _createStoryForImage() {
    // Start generating story
    setState(() {
      _isGeneratingStory = true;
      _storyNotFound = false;
    });
    _generateStory();
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
                      Expanded(
                        child: Text(
                          _storyTitle.isNotEmpty
                              ? _storyTitle
                              : 'story.your_story_title'.tr(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'Comic Sans MS',
                          ),
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
                        icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isSpeaking ? 'Stop' : 'story.read_aloud'.tr(),
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
                              ? AppColors.accent
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
                      child: CustomButton(
                        label: 'story.draw_another',
                        onPressed: _createAnotherStory,
                        icon: Icons.palette,
                        backgroundColor: AppColors.white,
                        textColor: AppColors.primary,
                        borderColor: AppColors.primary,
                        height: 53,
                        fontSize: 14,
                        borderRadius: 16,
                        variant: 'outlined',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Generate new story button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateNewStory,
                    icon: const Icon(Icons.refresh),
                    label: Text('story.generate_new_story'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
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

      child: _storyImageUrl != null && _storyImageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _storyImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to local image if URL fails
                  return _buildFallbackImage();
                },
              ),
            )
          : widget.drawingImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.drawingImage is Uint8List
                  ? Image.memory(
                      widget.drawingImage as Uint8List,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Image.file(
                      widget.drawingImage as File,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            )
          : _buildFallbackImage(),
    );
  }

  Widget _buildFallbackImage() {
    return Center(
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
    );
  }
}
