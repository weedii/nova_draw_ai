import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_cropper.dart';
import '../../../services/image_picker_service.dart';
import '../../../services/actions/drawing_api_service.dart';
import '../../../services/actions/api_exceptions.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

/// Direct Upload Screen - allows kids to upload any drawing
/// without going through tutorial categories
class DirectUploadScreen extends StatefulWidget {
  const DirectUploadScreen({super.key});

  @override
  State<DirectUploadScreen> createState() => _DirectUploadScreenState();
}

class _DirectUploadScreenState extends State<DirectUploadScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Services
  final ImagePickerService _imagePickerService = ImagePickerService();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Form state
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  File? _pickedImage;

  // Audio recording state
  bool _isRecording = false;
  Uint8List? _recordingBytes;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _useVoicePrompt = false;

  // Loading states
  bool _isLoading = false;
  bool _isProcessing = false;

  // Current step (0: subject, 1: image, 2: prompt)
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AppAnimations.createFadeController(vsync: this);
    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _subjectController.dispose();
    _promptController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _subjectController.text.trim().isEmpty) {
      _showError('direct_upload.error_no_subject'.tr());
      return;
    }
    if (_currentStep == 1 && _pickedImage == null) {
      _showError('direct_upload.error_no_image'.tr());
      return;
    }
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Maps API error messages to user-friendly localized messages
  String _getUserFriendlyError(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return 'direct_upload.error_timeout'.tr();
    }
    if (lowerError.contains('network') || lowerError.contains('connection') || 
        lowerError.contains('socket') || lowerError.contains('failed host lookup')) {
      return 'direct_upload.error_network'.tr();
    }
    if (lowerError.contains('too large') || lowerError.contains('2048')) {
      return 'direct_upload.error_image_too_large'.tr();
    }
    if (lowerError.contains('invalid audio') || lowerError.contains('audio format')) {
      return 'direct_upload.error_invalid_audio'.tr();
    }
    if (lowerError.contains('service not available') || lowerError.contains('503')) {
      return 'direct_upload.error_service_unavailable'.tr();
    }
    
    // Return original if no mapping found
    return error;
  }

  /// Shows a retry dialog for recoverable errors
  void _showRetryDialog(String error, VoidCallback onRetry) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Text('common.error'.tr()),
          ],
        ),
        content: Text(_getUserFriendlyError(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  // Image picking methods
  void _takePhoto() async {
    setState(() => _isLoading = true);
    try {
      final File? image = await _imagePickerService.pickFromCamera();
      if (image != null && mounted) {
        final croppedImage = await ImageCropperService.cropImage(
          imageFile: image,
        );
        setState(() {
          _pickedImage = croppedImage ?? image;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _chooseFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final File? image = await _imagePickerService.pickFromGallery();
      if (image != null && mounted) {
        final croppedImage = await ImageCropperService.cropImage(
          imageFile: image,
        );
        setState(() {
          _pickedImage = croppedImage ?? image;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // Audio recording methods
  void _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = Directory.systemTemp;
        final tempPath =
            '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

        await _audioRecorder.start(
          const RecordConfig(
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
          ),
          path: tempPath,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
          _recordingBytes = null;
        });

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isRecording) {
            setState(() {
              _recordingDuration += const Duration(seconds: 1);
            });
          }
        });
      } else {
        _showError('Microphone permission denied');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _stopRecording() async {
    try {
      if (!_isRecording) return;
      _recordingTimer?.cancel();

      final recordingPath = await _audioRecorder.stop();
      if (recordingPath != null) {
        final audioFile = File(recordingPath);
        if (await audioFile.exists()) {
          final audioBytes = await audioFile.readAsBytes();
          setState(() {
            _isRecording = false;
            _recordingBytes = audioBytes;
          });
          await audioFile.delete();
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Submit the drawing
  void _submit() async {
    // Validate
    if (_pickedImage == null) {
      _showError('direct_upload.error_no_image'.tr());
      return;
    }

    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      _showError('direct_upload.error_no_subject'.tr());
      return;
    }

    final hasTextPrompt = _promptController.text.trim().isNotEmpty;
    final hasVoicePrompt = _recordingBytes != null && _recordingBytes!.isNotEmpty;

    if (!hasTextPrompt && !hasVoicePrompt) {
      _showError('direct_upload.error_no_prompt'.tr());
      return;
    }

    setState(() => _isProcessing = true);

    try {
      late final response;

      if (hasVoicePrompt && _useVoicePrompt) {
        // Use voice prompt
        final language = context.locale.languageCode;
        response = await DrawingApiService.directUploadWithVoice(
          imageFile: _pickedImage!,
          subject: subject,
          audioBytes: _recordingBytes!,
          language: language,
        );
      } else {
        // Use text prompt
        response = await DrawingApiService.directUpload(
          imageFile: _pickedImage!,
          subject: subject,
          prompt: _promptController.text.trim(),
        );
      }

      if (mounted && response.success) {
        // Navigate to result screen
        context.pushReplacement(
          '/drawings/direct/upload/result',
          extra: {
            'originalImageUrl': response.originalImageUrl,
            'editedImageUrl': response.editedImageUrl,
            'drawing_id': response.drawingId,
          },
        );
      }
    } on ApiException catch (e) {
      setState(() => _isProcessing = false);
      // Show retry dialog for API errors
      _showRetryDialog(e.message, _submit);
    } on SocketException catch (_) {
      setState(() => _isProcessing = false);
      _showRetryDialog('direct_upload.error_network'.tr(), _submit);
    } on TimeoutException catch (_) {
      setState(() => _isProcessing = false);
      _showRetryDialog('direct_upload.error_timeout'.tr(), _submit);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showRetryDialog(e.toString(), _submit);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild when language changes
    context.locale;

    if (_isProcessing) {
      return CustomLoadingWidget(
        message: 'direct_upload.processing',
        subtitle: 'common.please_wait',
      );
    }

    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    CustomAppBar(
                      title: 'direct_upload.title',
                      subtitle: 'direct_upload.subtitle',
                      emoji: '🎨',
                      showBackButton: false,
                      showAnimation: true,
                      showSettingsButton: true,
                    ),
                    // Step indicator
                    _buildStepIndicator(),
                    // Main content based on current step
                    Expanded(
                      child: Padding(
                        // Extra bottom padding for floating nav bar
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          right: 20.0,
                          top: 20.0,
                          bottom: 100.0, // Space for floating nav bar
                        ),
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          CustomLoadingWidget(
            message: 'common.loading',
            subtitle: 'common.please_wait',
          ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        children: [
          _buildStepDot(0, '1'),
          Expanded(child: _buildStepLine(0)),
          _buildStepDot(1, '2'),
          Expanded(child: _buildStepLine(1)),
          _buildStepDot(2, '3'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(color: AppColors.accent, width: 3)
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      height: 3,
      color: isActive ? AppColors.primary : AppColors.border,
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSubjectStep();
      case 1:
        return _buildImageStep();
      case 2:
        return _buildPromptStep();
      default:
        return _buildSubjectStep();
    }
  }


  // Step 1: What did you draw?
  Widget _buildSubjectStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Main card with gradient border
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Column(
                      children: [
                        // Animated emoji container
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.1),
                                AppColors.accent.withValues(alpha: 0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🎨', style: TextStyle(fontSize: 50)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'direct_upload.what_did_you_draw'.tr(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Comic Sans MS',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'direct_upload.subject_description'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        // Enhanced text field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              hintText: 'direct_upload.subject_hint'.tr(),
                              hintStyle: TextStyle(
                                color: AppColors.textDark.withValues(alpha: 0.4),
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                              prefixIcon: const Icon(
                                Icons.brush,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textCapitalization: TextCapitalization.words,
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
        const SizedBox(height: 20),
        CustomButton(
          label: 'common.next',
          onPressed: _nextStep,
          backgroundColor: AppColors.primary,
          textColor: AppColors.white,
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }

  // Step 2: Upload your drawing
  Widget _buildImageStep() {
    return Column(
      children: [
        Expanded(
          child: _pickedImage != null
              ? _buildImagePreview()
              : _buildImageUploadOptions(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'common.back',
                onPressed: _previousStep,
                variant: 'outlined',
                borderColor: AppColors.primary,
                textColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                label: 'common.next',
                onPressed: _pickedImage != null ? _nextStep : () {},
                backgroundColor:
                    _pickedImage != null ? AppColors.primary : AppColors.border,
                textColor: AppColors.white,
                icon: Icons.arrow_forward,
                enabled: _pickedImage != null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadOptions() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated camera icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.cloud_upload_rounded, size: 50, color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'direct_upload.upload_your_drawing'.tr(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                fontFamily: 'Comic Sans MS',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'direct_upload.upload_description'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Camera button with icon
            _buildUploadOptionButton(
              icon: Icons.camera_alt_rounded,
              label: 'upload.take_photo'.tr(),
              color: AppColors.primary,
              onTap: _takePhoto,
            ),
            const SizedBox(height: 16),
            // Gallery button
            _buildUploadOptionButton(
              icon: Icons.photo_library_rounded,
              label: 'upload.choose_from_gallery'.tr(),
              color: AppColors.secondary,
              onTap: _chooseFromGallery,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
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
              child: Image.file(_pickedImage!, fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          label: 'upload.choose_different',
          onPressed: () => setState(() => _pickedImage = null),
          variant: 'outlined',
          borderColor: AppColors.primary,
          textColor: AppColors.primary,
          icon: Icons.refresh,
        ),
      ],
    );
  }

  // Step 3: What should we do with it?
  Widget _buildPromptStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Image preview (small)
                if (_pickedImage != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_pickedImage!, fit: BoxFit.cover),
                    ),
                  ),

                // Prompt input card
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        'direct_upload.what_to_do'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Toggle between text and voice
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _useVoicePrompt = false),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_useVoicePrompt
                                      ? AppColors.primary
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.keyboard,
                                      color: !_useVoicePrompt
                                          ? AppColors.white
                                          : AppColors.textDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Type',
                                      style: TextStyle(
                                        color: !_useVoicePrompt
                                            ? AppColors.white
                                            : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _useVoicePrompt = true),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _useVoicePrompt
                                      ? AppColors.accent
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.mic,
                                      color: _useVoicePrompt
                                          ? AppColors.white
                                          : AppColors.textDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Voice',
                                      style: TextStyle(
                                        color: _useVoicePrompt
                                            ? AppColors.white
                                            : AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Text input or voice recording
                      if (!_useVoicePrompt)
                        TextField(
                          controller: _promptController,
                          decoration: InputDecoration(
                            hintText: 'direct_upload.prompt_hint'.tr(),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          maxLines: 3,
                        )
                      else
                        _buildVoiceRecorder(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'common.back',
                onPressed: _previousStep,
                variant: 'outlined',
                borderColor: AppColors.primary,
                textColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                label: 'direct_upload.submit',
                onPressed: _submit,
                backgroundColor: AppColors.accent,
                textColor: AppColors.white,
                icon: Icons.auto_fix_high,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceRecorder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Recording indicator
          if (_isRecording)
            Column(
              children: [
                const Icon(
                  Icons.mic,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                Text(
                  'direct_upload.recording'.tr(),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else if (_recordingBytes != null)
            Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDuration(_recordingDuration)} recorded',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                const Icon(
                  Icons.mic_none,
                  size: 48,
                  color: AppColors.border,
                ),
                const SizedBox(height: 8),
                Text(
                  'direct_upload.start_recording'.tr(),
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Record button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _isRecording ? AppColors.error : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: AppColors.white,
                size: 32,
              ),
            ),
          ),

          // Clear recording button
          if (_recordingBytes != null && !_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _recordingBytes = null;
                  _recordingDuration = Duration.zero;
                }),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Record again'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
