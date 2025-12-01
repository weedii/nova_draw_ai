import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math';
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

/// Responsive helper class for calculating sizes based on screen dimensions
class _ResponsiveHelper {
  final double screenWidth;
  final double screenHeight;
  final double availableHeight;

  _ResponsiveHelper({
    required this.screenWidth,
    required this.screenHeight,
    required this.availableHeight,
  });

  // Screen size categories
  bool get isSmallScreen => screenHeight < 700;
  bool get isMediumScreen => screenHeight >= 700 && screenHeight < 850;
  bool get isLargeScreen => screenHeight >= 850;

  // Responsive icon sizes
  double get iconContainerSize {
    if (isSmallScreen) return 50;
    if (isMediumScreen) return 60;
    return 70;
  }

  double get iconSize {
    if (isSmallScreen) return 28;
    if (isMediumScreen) return 32;
    return 36;
  }

  double get emojiSize {
    if (isSmallScreen) return 26;
    if (isMediumScreen) return 30;
    return 36;
  }

  // Responsive font sizes
  double get titleFontSize {
    if (isSmallScreen) return 16;
    if (isMediumScreen) return 18;
    return 20;
  }

  double get subtitleFontSize {
    if (isSmallScreen) return 11;
    if (isMediumScreen) return 12;
    return 13;
  }

  double get buttonFontSize {
    if (isSmallScreen) return 13;
    if (isMediumScreen) return 14;
    return 15;
  }

  // Responsive padding
  double get cardPadding {
    if (isSmallScreen) return 14;
    if (isMediumScreen) return 18;
    return 24;
  }

  double get cardPaddingHorizontal {
    if (isSmallScreen) return 14;
    if (isMediumScreen) return 18;
    return 20;
  }

  double get itemSpacing {
    if (isSmallScreen) return 10;
    if (isMediumScreen) return 14;
    return 16;
  }

  double get smallSpacing {
    if (isSmallScreen) return 4;
    if (isMediumScreen) return 6;
    return 8;
  }

  // Image preview height
  double get imagePreviewHeight {
    if (isSmallScreen) return min(availableHeight * 0.35, 200);
    if (isMediumScreen) return min(availableHeight * 0.4, 280);
    return min(availableHeight * 0.45, 350);
  }

  double get smallImagePreviewHeight {
    if (isSmallScreen) return 80;
    if (isMediumScreen) return 100;
    return 120;
  }

  // Button dimensions
  double get buttonHeight {
    if (isSmallScreen) return 46;
    if (isMediumScreen) return 50;
    return 56;
  }

  double get buttonPaddingVertical {
    if (isSmallScreen) return 10;
    if (isMediumScreen) return 12;
    return 14;
  }

  double get buttonPaddingHorizontal {
    if (isSmallScreen) return 14;
    if (isMediumScreen) return 16;
    return 20;
  }

  // Record button size
  double get recordButtonSize {
    if (isSmallScreen) return 48;
    if (isMediumScreen) return 52;
    return 56;
  }

  double get recordIconSize {
    if (isSmallScreen) return 22;
    if (isMediumScreen) return 24;
    return 26;
  }

  // Border radius
  double get cardBorderRadius {
    if (isSmallScreen) return 16;
    if (isMediumScreen) return 20;
    return 24;
  }

  double get buttonBorderRadius {
    if (isSmallScreen) return 12;
    if (isMediumScreen) return 14;
    return 16;
  }

  // Bottom padding (no nav bar on this screen)
  double get bottomPadding {
    if (isSmallScreen) return 12;
    if (isMediumScreen) return 16;
    return 20;
  }
}

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

  String _getUserFriendlyError(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return 'direct_upload.error_timeout'.tr();
    }
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('socket') ||
        lowerError.contains('failed host lookup')) {
      return 'direct_upload.error_network'.tr();
    }
    if (lowerError.contains('too large') || lowerError.contains('2048')) {
      return 'direct_upload.error_image_too_large'.tr();
    }
    if (lowerError.contains('invalid audio') ||
        lowerError.contains('audio format')) {
      return 'direct_upload.error_invalid_audio'.tr();
    }
    if (lowerError.contains('service not available') ||
        lowerError.contains('503')) {
      return 'direct_upload.error_service_unavailable'.tr();
    }

    return error;
  }

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

  void _submit() async {
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
    final hasVoicePrompt =
        _recordingBytes != null && _recordingBytes!.isNotEmpty;

    if (!hasTextPrompt && !hasVoicePrompt) {
      _showError('direct_upload.error_no_prompt'.tr());
      return;
    }

    setState(() => _isProcessing = true);

    try {
      late final response;

      if (hasVoicePrompt && _useVoicePrompt) {
        final language = context.locale.languageCode;
        response = await DrawingApiService.directUploadWithVoice(
          imageFile: _pickedImage!,
          subject: subject,
          audioBytes: _recordingBytes!,
          language: language,
        );
      } else {
        response = await DrawingApiService.directUpload(
          imageFile: _pickedImage!,
          subject: subject,
          prompt: _promptController.text.trim(),
        );
      }

      if (mounted && response.success) {
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
    context.locale;

    if (_isProcessing) {
      return CustomLoadingWidget(
        message: 'direct_upload.processing',
        subtitle: 'common.please_wait',
      );
    }

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: true,
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
                      showBackButton: true,
                      showAnimation: true,
                      showSettingsButton: true,
                    ),
                    _buildStepIndicator(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final responsive = _ResponsiveHelper(
                            screenWidth: screenSize.width,
                            screenHeight: screenSize.height,
                            availableHeight: constraints.maxHeight,
                          );

                          return Padding(
                            padding: EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              top: 8.0,
                              bottom: responsive.bottomPadding,
                            ),
                            child: _buildCurrentStep(responsive),
                          );
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(color: AppColors.accent, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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

  Widget _buildCurrentStep(_ResponsiveHelper r) {
    switch (_currentStep) {
      case 0:
        return _buildSubjectStep(r);
      case 1:
        return _buildImageStep(r);
      case 2:
        return _buildPromptStep(r);
      default:
        return _buildSubjectStep(r);
    }
  }

  // Step 1: What did you draw?
  Widget _buildSubjectStep(_ResponsiveHelper r) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(r.cardBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.cardPaddingHorizontal,
                  vertical: r.cardPadding,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(r.cardBorderRadius - 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: r.iconContainerSize,
                      height: r.iconContainerSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.accent.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '🎨',
                          style: TextStyle(fontSize: r.emojiSize),
                        ),
                      ),
                    ),
                    SizedBox(height: r.itemSpacing),
                    Text(
                      'direct_upload.what_did_you_draw'.tr(),
                      style: TextStyle(
                        fontSize: r.titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontFamily: 'Comic Sans MS',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: r.smallSpacing),
                    Text(
                      'direct_upload.subject_description'.tr(),
                      style: TextStyle(
                        fontSize: r.subtitleFontSize,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: r.itemSpacing),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          r.buttonBorderRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'direct_upload.subject_hint'.tr(),
                          hintStyle: TextStyle(
                            color: AppColors.textDark.withValues(alpha: 0.4),
                            fontSize: r.buttonFontSize,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          prefixIcon: Icon(
                            Icons.brush,
                            color: AppColors.primary,
                            size: r.iconSize * 0.6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              r.buttonBorderRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              r.buttonBorderRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: r.buttonPaddingHorizontal,
                            vertical: r.buttonPaddingVertical,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: r.buttonFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: r.itemSpacing),
        CustomButton(
          label: 'common.next',
          onPressed: _nextStep,
          backgroundColor: AppColors.primary,
          textColor: AppColors.white,
          icon: Icons.arrow_forward,
          height: r.buttonHeight,
        ),
      ],
    );
  }

  // Step 2: Upload your drawing
  Widget _buildImageStep(_ResponsiveHelper r) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _pickedImage != null
                ? _buildImagePreview(r)
                : _buildImageUploadOptions(r),
          ),
        ),
        SizedBox(height: r.itemSpacing),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'common.back',
                onPressed: _previousStep,
                variant: 'outlined',
                borderColor: AppColors.primary,
                textColor: AppColors.primary,
                height: r.buttonHeight,
              ),
            ),
            SizedBox(width: r.smallSpacing * 1.5),
            Expanded(
              child: CustomButton(
                label: 'common.next',
                onPressed: _pickedImage != null ? _nextStep : () {},
                backgroundColor: _pickedImage != null
                    ? AppColors.primary
                    : AppColors.border,
                textColor: AppColors.white,
                icon: Icons.arrow_forward,
                enabled: _pickedImage != null,
                height: r.buttonHeight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadOptions(_ResponsiveHelper r) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: r.cardPaddingHorizontal,
          vertical: r.cardPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(r.cardBorderRadius - 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: r.iconContainerSize,
              height: r.iconContainerSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.cloud_upload_rounded,
                  size: r.iconSize,
                  color: AppColors.secondary,
                ),
              ),
            ),
            SizedBox(height: r.itemSpacing),
            Text(
              'direct_upload.upload_your_drawing'.tr(),
              style: TextStyle(
                fontSize: r.titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                fontFamily: 'Comic Sans MS',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: r.smallSpacing),
            Text(
              'direct_upload.upload_description'.tr(),
              style: TextStyle(
                fontSize: r.subtitleFontSize,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: r.itemSpacing),
            _buildUploadOptionButton(
              r: r,
              icon: Icons.camera_alt_rounded,
              label: 'upload.take_photo'.tr(),
              color: AppColors.primary,
              onTap: _takePhoto,
            ),
            SizedBox(height: r.smallSpacing * 1.5),
            _buildUploadOptionButton(
              r: r,
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
    required _ResponsiveHelper r,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: r.buttonPaddingVertical,
          horizontal: r.buttonPaddingHorizontal,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r.buttonBorderRadius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(r.smallSpacing),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: r.iconSize * 0.55,
              ),
            ),
            SizedBox(width: r.smallSpacing * 1.5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: r.buttonFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(_ResponsiveHelper r) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: r.imagePreviewHeight,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(r.buttonBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r.buttonBorderRadius),
            child: Image.file(_pickedImage!, fit: BoxFit.contain),
          ),
        ),
        SizedBox(height: r.smallSpacing * 1.5),
        CustomButton(
          label: 'upload.choose_different',
          onPressed: () => setState(() => _pickedImage = null),
          variant: 'outlined',
          borderColor: AppColors.primary,
          textColor: AppColors.primary,
          icon: Icons.refresh,
          height: r.buttonHeight,
        ),
      ],
    );
  }

  // Step 3: What should we do with it?
  Widget _buildPromptStep(_ResponsiveHelper r) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                if (_pickedImage != null)
                  Container(
                    height: r.smallImagePreviewHeight,
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: r.smallSpacing * 1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r.buttonBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(r.buttonBorderRadius),
                      child: Image.file(_pickedImage!, fit: BoxFit.cover),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.all(r.cardPadding * 0.8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(r.buttonBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: r.emojiSize)),
                      SizedBox(height: r.smallSpacing),
                      Text(
                        'direct_upload.what_to_do'.tr(),
                        style: TextStyle(
                          fontSize: r.titleFontSize * 0.85,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: r.smallSpacing * 1.5),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _useVoicePrompt = false),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: r.smallSpacing * 1.2,
                                ),
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
                                      size: r.iconSize * 0.5,
                                      color: !_useVoicePrompt
                                          ? AppColors.white
                                          : AppColors.textDark,
                                    ),
                                    SizedBox(width: r.smallSpacing),
                                    Text(
                                      'Type',
                                      style: TextStyle(
                                        fontSize: r.subtitleFontSize,
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
                          SizedBox(width: r.smallSpacing),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _useVoicePrompt = true),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: r.smallSpacing * 1.2,
                                ),
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
                                      size: r.iconSize * 0.5,
                                      color: _useVoicePrompt
                                          ? AppColors.white
                                          : AppColors.textDark,
                                    ),
                                    SizedBox(width: r.smallSpacing),
                                    Text(
                                      'Voice',
                                      style: TextStyle(
                                        fontSize: r.subtitleFontSize,
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
                      SizedBox(height: r.smallSpacing * 1.5),
                      if (!_useVoicePrompt)
                        TextField(
                          controller: _promptController,
                          decoration: InputDecoration(
                            hintText: 'direct_upload.prompt_hint'.tr(),
                            hintStyle: TextStyle(fontSize: r.subtitleFontSize),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                r.buttonBorderRadius,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: r.buttonPaddingHorizontal,
                              vertical: r.buttonPaddingVertical,
                            ),
                          ),
                          style: TextStyle(fontSize: r.subtitleFontSize + 1),
                          maxLines: 3,
                        )
                      else
                        _buildVoiceRecorder(r),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: r.itemSpacing),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomButton(
                label: 'common.back',
                onPressed: _previousStep,
                variant: 'outlined',
                borderColor: AppColors.primary,
                textColor: AppColors.primary,
                height: r.buttonHeight,
              ),
            ),
            SizedBox(width: r.smallSpacing * 1.5),
            Expanded(
              flex: 3,
              child: CustomButton(
                label: 'direct_upload.submit',
                onPressed: _submit,
                backgroundColor: AppColors.accent,
                textColor: AppColors.white,
                icon: Icons.auto_fix_high,
                height: r.buttonHeight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceRecorder(_ResponsiveHelper r) {
    return Container(
      padding: EdgeInsets.all(r.smallSpacing * 1.5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(r.buttonBorderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: r.iconSize, color: AppColors.error),
                SizedBox(height: r.smallSpacing),
                Text(
                  'direct_upload.recording'.tr(),
                  style: TextStyle(
                    fontSize: r.subtitleFontSize,
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDuration(_recordingDuration),
                  style: TextStyle(
                    fontSize: r.titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else if (_recordingBytes != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: r.iconSize,
                  color: AppColors.success,
                ),
                SizedBox(height: r.smallSpacing),
                Text(
                  '${_formatDuration(_recordingDuration)} recorded',
                  style: TextStyle(
                    fontSize: r.subtitleFontSize,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic_none, size: r.iconSize, color: AppColors.border),
                SizedBox(height: r.smallSpacing),
                Text(
                  'direct_upload.start_recording'.tr(),
                  style: TextStyle(
                    fontSize: r.subtitleFontSize,
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          SizedBox(height: r.smallSpacing * 1.5),
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: r.recordButtonSize,
              height: r.recordButtonSize,
              decoration: BoxDecoration(
                color: _isRecording ? AppColors.error : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: AppColors.white,
                size: r.recordIconSize,
              ),
            ),
          ),
          if (_recordingBytes != null && !_isRecording)
            Padding(
              padding: EdgeInsets.only(top: r.smallSpacing),
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _recordingBytes = null;
                  _recordingDuration = Duration.zero;
                }),
                icon: Icon(Icons.refresh, size: r.iconSize * 0.4),
                label: Text(
                  'Record again',
                  style: TextStyle(fontSize: r.subtitleFontSize),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textDark.withValues(alpha: 0.6),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.smallSpacing,
                    vertical: r.smallSpacing * 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
