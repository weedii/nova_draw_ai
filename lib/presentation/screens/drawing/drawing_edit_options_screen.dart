import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import '../../../core/constants/colors.dart';
import '../../../models/ui_models.dart';
import '../../../services/actions/drawing_api_service.dart';
import '../../../services/actions/edit_option_api_service.dart';
import '../../../services/actions/api_exceptions.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

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
  bool _isLoadingOptions = true;
  String? _loadingError;
  EditOption? _selectedEditOption;
  List<EditOption> _availableEditOptions = [];

  // Audio recording state variables
  final AudioRecorder audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Uint8List? _recordingBytes; // Stores audio bytes directly (no disk I/O)
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer; // Timer to update recording duration

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
    _recordingTimer?.cancel(); // Cancel the recording timer if active
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadEditOptions() async {
    try {
      print('📋 Loading edit options from API...');

      // Fetch edit options from the API
      final apiOptions = await EditOptionApiService.getEditOptions(
        category: widget.categoryId,
        subject: widget.drawingId,
      );

      if (!mounted) return;

      print('✅ Edit options loaded successfully: ${apiOptions.length} options');

      // Convert API options to local EditOption objects
      final convertedOptions = apiOptions
          .map(
            (apiOption) => EditOption(
              id: apiOption.id,
              titleEn: apiOption.titleEn,
              titleDe: apiOption.titleDe,
              descriptionEn: apiOption.descriptionEn,
              descriptionDe: apiOption.descriptionDe,
              promptEn: apiOption.promptEn,
              promptDe: apiOption.promptDe,
              emoji: apiOption.icon ?? '✨',
              color: AppColors.primary,
            ),
          )
          .toList();

      setState(() {
        _availableEditOptions = convertedOptions;
        _isLoadingOptions = false;
        _loadingError = null;
      });
    } on ApiException catch (e) {
      print('❌ API Error loading edit options: ${e.message}');

      // Check if this is a "No edit options found" error (404)
      // In this case, we don't show an error - just proceed without edit options
      // The voice editing option will still be available
      if (e.message.contains('No edit options found')) {
        print(
          'ℹ️ No edit options available for this subject, but voice editing is still available',
        );
        if (mounted) {
          setState(() {
            _availableEditOptions = [];
            _isLoadingOptions = false;
            _loadingError = null;
          });
        }
      } else {
        // For other API errors, show the error screen
        if (mounted) {
          setState(() {
            _isLoadingOptions = false;
            _loadingError = e.message;
          });
        }
      }
    } catch (e) {
      print('❌ Unexpected error loading edit options: $e');
      if (mounted) {
        setState(() {
          _isLoadingOptions = false;
          _loadingError = 'edit_options.loading_error'.tr();
        });
      }
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
        // Navigate to the final result screen with the edited image URL
        context.pushReplacement(
          '/drawings/${widget.categoryId}/${widget.drawingId}/result',
          extra: {
            'uploadedImage': widget.uploadedImage,
            'editedImageUrl': response.resultImage,
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

  /// Start recording audio from the device microphone
  /// Uses the 'record' package to capture AAC audio directly to memory
  /// No temporary files are created - audio bytes are stored in _recordingBytes
  void _startRecording() async {
    try {
      // Check if the app has permission to record audio
      if (await audioRecorder.hasPermission()) {
        print('🎤 Starting audio recording...');

        // Start recording with AAC format (recommended for quality and compression)
        // RecordConfig specifies the audio format and quality settings
        // The record package will create a temporary file which we'll read into memory
        final tempDir = Directory.systemTemp;
        final tempPath =
            '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

        // Try recording without autoGain and noiseSuppress which may not be available
        await audioRecorder.start(
          const RecordConfig(
            bitRate: 128000, // 128 kbps bitrate (good balance of quality/size)
            sampleRate: 44100, // 44.1 kHz sample rate (CD quality)
            numChannels: 1, // Mono recording
          ),
          path: tempPath, // Temporary file path (will be deleted after reading)
        );

        // Update UI state to show recording is in progress
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
          _recordingBytes = null; // Clear any previous recording
        });

        print('✅ Audio recording started');

        // Start a timer to update the recording duration every second
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isRecording) {
            setState(() {
              _recordingDuration += const Duration(seconds: 1);
            });
          }
        });
      } else {
        print('❌ Microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('edit_options.no_recording'.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Stop recording audio and store the bytes in memory
  /// The audio bytes are NOT saved to disk - they're kept in RAM for direct transmission
  void _stopRecording() async {
    try {
      if (!_isRecording) return;

      print('🛑 Stopping audio recording...');

      // Cancel the recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Stop the recording and get the audio file path
      final recordingPath = await audioRecorder.stop();

      if (recordingPath != null) {
        final audioFile = File(recordingPath);
        final fileExists = await audioFile.exists();

        if (fileExists) {
          // Get file info
          final fileStat = await audioFile.stat();
          print('📊 File size: ${fileStat.size} bytes');
          print('📁 File path: ${audioFile.path}');

          // Read the audio file into memory as bytes
          // This converts the recorded file to Uint8List for direct backend transmission
          final audioBytes = await audioFile.readAsBytes();

          print('✅ Audio recording stopped');
          print('🎵 Audio bytes loaded: ${audioBytes.length} bytes');

          // Update UI state to show recording is complete
          setState(() {
            _isRecording = false;
            _recordingBytes = audioBytes; // Store bytes in memory
          });

          // TODO: For debugging - save a copy to Downloads folder to inspect
          // Uncomment the code below to save the audio file for testing
          // try {
          //   final downloadsDir = Directory('/storage/emulated/0/Download');
          //   if (await downloadsDir.exists()) {
          //     final debugFile = File(
          //       '${downloadsDir.path}/audio_debug_${DateTime.now().millisecondsSinceEpoch}.aac',
          //     );
          //     await debugFile.writeAsBytes(audioBytes);
          //     print('💾 Debug copy saved to: ${debugFile.path}');
          //   }
          // } catch (e) {
          //   print('⚠️  Could not save debug copy: $e');
          // }

          // Delete the temporary file since we have the bytes in memory
          // This keeps the device storage clean
          try {
            await audioFile.delete();
            print('🗑️  Temporary audio file deleted');
          } catch (e) {
            print('⚠️  Could not delete temporary file: $e');
          }
        } else {
          print('❌ Recording file was not created at: $recordingPath');
          throw Exception('Recording file not found at: $recordingPath');
        }
      } else {
        print('❌ Recording path is null - recording may have failed');
        throw Exception('Recording path is null');
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Restart recording - clear the current recording and start fresh
  void _restartRecording() {
    setState(() {
      _recordingBytes = null;
      _recordingDuration = Duration.zero;
      _isRecording = false;
    });
    _startRecording();
  }

  /// Send the image and voice recording to the backend for AI enhancement
  /// The audio bytes are sent directly without any disk I/O
  /// Language is automatically detected from the app's current locale
  void _sendWithVoice() async {
    try {
      // Validate that we have audio bytes to send
      if (_recordingBytes == null || _recordingBytes!.isEmpty) {
        print('❌ No recording available');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('edit_options.no_recording'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate that we have an image to edit
      if (widget.uploadedImage == null) {
        print('❌ No image available');
        throw ApiException('Image is required');
      }

      print('🚀 Sending image with voice to backend...');

      // Update UI to show processing state
      setState(() {
        _isApplyingEdit = true;
      });

      // Get the current app language ('en' or 'de')
      final language = context.locale.languageCode;
      print('💬 Language: $language');

      // Call the API service to send both image and audio
      // The audio bytes are sent directly to memory without saving to disk
      final response = await DrawingApiService.editImageWithVoice(
        imageFile: widget.uploadedImage!,
        audioBytes: _recordingBytes!, // Send audio bytes directly
        language: language, // Send current app language
      );

      if (mounted && response.success) {
        print('✅ Image edited with voice successfully!');

        // Create a voice edit option to represent the voice-based editing
        final voiceEditOption = EditOption(
          id: 'voice_edit',
          titleEn: 'Voice Story',
          titleDe: 'Sprachgeschichte',
          descriptionEn: 'Edited with your voice',
          descriptionDe: 'Mit deiner Stimme bearbeitet',
          emoji: '🎤',
          color: AppColors.accent,
          promptEn: 'Voice-based editing',
          promptDe: 'Sprachbasierte Bearbeitung',
        );

        // Navigate to the final result screen with the edited image URL
        context.pushReplacement(
          '/drawings/${widget.categoryId}/${widget.drawingId}/result',
          extra: {
            'uploadedImage': widget.uploadedImage,
            'editedImageUrl': response.resultImage,
            'selectedEditOption': voiceEditOption,
          },
        );
      }
    } on ApiException catch (e) {
      print('❌ API Error: ${e.message}');
      if (mounted) {
        setState(() {
          _isApplyingEdit = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      if (mounted) {
        setState(() {
          _isApplyingEdit = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show applying edit loading
    if (_isApplyingEdit) {
      return _buildApplyingEditView();
    }

    // Show loading state while fetching edit options
    if (_isLoadingOptions) {
      return CustomLoadingWidget(
        message: 'edit_options.loading_options',
        subtitle: 'edit_options.fetching_from_server',
      );
    }

    // Show error state if loading failed
    if (_loadingError != null) {
      return _buildErrorView();
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

  Widget _buildErrorView() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'edit_options.loading_failed'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadingError ?? 'edit_options.loading_error'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.border,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    label: 'common.retry',
                    onPressed: () {
                      setState(() {
                        _isLoadingOptions = true;
                        _loadingError = null;
                      });
                      _loadEditOptions();
                    },
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.white,
                    icon: Icons.refresh,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'common.back',
                    onPressed: () => context.pop(),
                    variant: 'outlined',
                    borderColor: AppColors.primary,
                    textColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsView() {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // Original image display
            Container(
              width: double.infinity,
              height: 380,
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
                        fit: BoxFit.contain,
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

            const SizedBox(height: 20),

            // Voice recording section
            _buildVoiceRecordingCard(),

            const SizedBox(height: 16),

            // Edit options section
            _availableEditOptions.isEmpty
                ? _buildNoOptionsView()
                : _buildEditOptionsGrid(),

            const SizedBox(height: 16),

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
        color: AppColors.white.withValues(alpha: 0.5),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji
              Text(option.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),

              // Title
              Flexible(
                child: Text(
                  context.locale.languageCode == 'de'
                      ? option.titleDe
                      : option.titleEn,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? option.color : AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),

              // Description
              Flexible(
                child: Text(
                  context.locale.languageCode == 'de'
                      ? option.descriptionDe
                      : option.descriptionEn,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceRecordingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🎤', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'edit_options.voice_description'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Comic Sans MS',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'edit_options.voice_description_subtitle'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recording status and buttons
          if (!_isRecording && _recordingBytes == null)
            // Start recording button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic),
                label: Text('edit_options.start_recording'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 6,
                  shadowColor: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
            )
          else if (_isRecording)
            // Recording in progress
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'edit_options.recording'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: Text('edit_options.stop_recording'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 6,
                      shadowColor: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            )
          else
            // Recording complete
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'edit_options.recording_complete'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Two buttons: Restart and Send
                Row(
                  children: [
                    // Restart Recording button
                    Expanded(
                      child: CustomButton(
                        label: 'edit_options.restart_recording',
                        onPressed: _restartRecording,
                        backgroundColor: AppColors.error.withValues(alpha: 0.8),
                        textColor: AppColors.white,
                        icon: Icons.refresh,
                        borderRadius: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send My Story button
                    Expanded(
                      child: CustomButton(
                        label: 'edit_options.send_with_voice',
                        onPressed: _sendWithVoice,
                        backgroundColor: AppColors.accent,
                        textColor: AppColors.white,
                        icon: Icons.send,
                        borderRadius: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Apply edit button (only show if option is selected)
        if (_selectedEditOption != null)
          CustomButton(
            label: 'edit_options.apply_edit',
            onPressed: _applyEditOption,
            backgroundColor: _selectedEditOption!.color,
            textColor: AppColors.white,
            icon: Icons.auto_fix_high,
            borderRadius: 16,
          ),

        if (_selectedEditOption != null) const SizedBox(height: 16),

        // Skip editing button
        CustomButton(
          label: 'edit_options.keep_original',
          onPressed: _skipEditing,
          backgroundColor: AppColors.white,
          textColor: AppColors.primary,
          borderColor: AppColors.primary,
          variant: 'outlined',
          icon: Icons.skip_next,
          borderRadius: 16,
        ),
      ],
    );
  }
}
