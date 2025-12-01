import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import '../../../core/constants/colors.dart';
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

  bool get isSmallScreen => screenHeight < 700;
  bool get isMediumScreen => screenHeight >= 700 && screenHeight < 850;
  bool get isLargeScreen => screenHeight >= 850;

  double get emojiSize {
    if (isSmallScreen) return 28;
    if (isMediumScreen) return 32;
    return 36;
  }

  double get titleFontSize {
    if (isSmallScreen) return 15;
    if (isMediumScreen) return 17;
    return 18;
  }

  double get subtitleFontSize {
    if (isSmallScreen) return 12;
    if (isMediumScreen) return 13;
    return 14;
  }

  double get buttonFontSize {
    if (isSmallScreen) return 13;
    if (isMediumScreen) return 14;
    return 15;
  }

  double get cardPadding {
    if (isSmallScreen) return 14;
    if (isMediumScreen) return 18;
    return 20;
  }

  double get itemSpacing {
    if (isSmallScreen) return 12;
    if (isMediumScreen) return 16;
    return 20;
  }

  double get smallSpacing {
    if (isSmallScreen) return 6;
    if (isMediumScreen) return 8;
    return 10;
  }

  double get imagePreviewHeight {
    if (isSmallScreen) return min(availableHeight * 0.25, 150);
    if (isMediumScreen) return min(availableHeight * 0.28, 180);
    return min(availableHeight * 0.3, 200);
  }

  double get buttonHeight {
    if (isSmallScreen) return 46;
    if (isMediumScreen) return 50;
    return 56;
  }

  double get recordButtonSize {
    if (isSmallScreen) return 50;
    if (isMediumScreen) return 56;
    return 60;
  }

  double get recordIconSize {
    if (isSmallScreen) return 24;
    if (isMediumScreen) return 26;
    return 28;
  }

  double get iconSize {
    if (isSmallScreen) return 32;
    if (isMediumScreen) return 36;
    return 40;
  }

  double get borderRadius {
    if (isSmallScreen) return 12;
    if (isMediumScreen) return 14;
    return 16;
  }

  double get togglePadding {
    if (isSmallScreen) return 10;
    if (isMediumScreen) return 11;
    return 12;
  }
}

/// Screen for trying another prompt with an existing image
/// Used when user wants to re-edit their drawing with a different prompt
class DirectUploadRepromptScreen extends StatefulWidget {
  final String originalImageUrl;
  final String? dbDrawingId;

  const DirectUploadRepromptScreen({
    super.key,
    required this.originalImageUrl,
    this.dbDrawingId,
  });

  @override
  State<DirectUploadRepromptScreen> createState() =>
      _DirectUploadRepromptScreenState();
}

class _DirectUploadRepromptScreenState extends State<DirectUploadRepromptScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _promptController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  Uint8List? _recordingBytes;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _useVoicePrompt = false;
  bool _isProcessing = false;

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
    _promptController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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

  void _submit() async {
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
        response = await DrawingApiService.editImageWithVoice(
          imageUrl: widget.originalImageUrl,
          audioBytes: _recordingBytes!,
          language: language,
          subject: 'drawing',
          drawingId: widget.dbDrawingId,
        );
      } else {
        response = await DrawingApiService.editImage(
          imageUrl: widget.originalImageUrl,
          prompt: _promptController.text.trim(),
          subject: 'drawing',
          drawingId: widget.dbDrawingId,
        );
      }

      if (mounted && response.success) {
        context.pushReplacement(
          '/drawings/direct/upload/result',
          extra: {
            'originalImageUrl': widget.originalImageUrl,
            'editedImageUrl': response.editedImageUrl,
            'drawing_id': response.drawingId,
          },
        );
      }
    } on ApiException catch (e) {
      setState(() => _isProcessing = false);
      _showError(e.message);
    } on SocketException catch (_) {
      setState(() => _isProcessing = false);
      _showError('direct_upload.error_network'.tr());
    } on TimeoutException catch (_) {
      setState(() => _isProcessing = false);
      _showError('direct_upload.error_timeout'.tr());
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return CustomLoadingWidget(
        message: 'direct_upload.processing',
        subtitle: 'common.please_wait',
      );
    }

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                CustomAppBar(
                  title: 'final_result.try_another_prompt',
                  subtitle: 'direct_upload.what_to_do',
                  emoji: '✨',
                  showBackButton: true,
                  showAnimation: true,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final r = _ResponsiveHelper(
                        screenWidth: screenSize.width,
                        screenHeight: screenSize.height,
                        availableHeight: constraints.maxHeight,
                      );

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(r.cardPadding * 0.8),
                        child: Column(
                          children: [
                            // Image preview
                            Container(
                              height: r.imagePreviewHeight,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  r.borderRadius,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  r.borderRadius,
                                ),
                                child: Image.network(
                                  widget.originalImageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      color: AppColors.error.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: r.iconSize,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: r.itemSpacing),
                            // Prompt input card
                            Container(
                              padding: EdgeInsets.all(r.cardPadding),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  r.borderRadius + 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '✨',
                                    style: TextStyle(fontSize: r.emojiSize),
                                  ),
                                  SizedBox(height: r.smallSpacing),
                                  Text(
                                    'direct_upload.what_to_do'.tr(),
                                    style: TextStyle(
                                      fontSize: r.titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: r.itemSpacing * 0.8),
                                  // Toggle between text and voice
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _useVoicePrompt = false,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: r.togglePadding,
                                            ),
                                            decoration: BoxDecoration(
                                              color: !_useVoicePrompt
                                                  ? AppColors.primary
                                                  : AppColors.background,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.keyboard,
                                                  size: r.subtitleFontSize + 4,
                                                  color: !_useVoicePrompt
                                                      ? AppColors.white
                                                      : AppColors.textDark,
                                                ),
                                                SizedBox(
                                                  width: r.smallSpacing * 0.8,
                                                ),
                                                Text(
                                                  'Type',
                                                  style: TextStyle(
                                                    fontSize:
                                                        r.subtitleFontSize,
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
                                          onTap: () => setState(
                                            () => _useVoicePrompt = true,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: r.togglePadding,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _useVoicePrompt
                                                  ? AppColors.accent
                                                  : AppColors.background,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.mic,
                                                  size: r.subtitleFontSize + 4,
                                                  color: _useVoicePrompt
                                                      ? AppColors.white
                                                      : AppColors.textDark,
                                                ),
                                                SizedBox(
                                                  width: r.smallSpacing * 0.8,
                                                ),
                                                Text(
                                                  'Voice',
                                                  style: TextStyle(
                                                    fontSize:
                                                        r.subtitleFontSize,
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
                                  SizedBox(height: r.itemSpacing * 0.8),
                                  if (!_useVoicePrompt)
                                    TextField(
                                      controller: _promptController,
                                      decoration: InputDecoration(
                                        hintText: 'direct_upload.prompt_hint'
                                            .tr(),
                                        hintStyle: TextStyle(
                                          fontSize: r.subtitleFontSize,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.background,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            r.borderRadius,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: r.cardPadding * 0.9,
                                          vertical: r.togglePadding + 2,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: r.buttonFontSize,
                                      ),
                                      maxLines: 3,
                                    )
                                  else
                                    _buildVoiceRecorder(r),
                                ],
                              ),
                            ),
                            SizedBox(height: r.itemSpacing),
                            // Submit button
                            CustomButton(
                              label: 'direct_upload.submit',
                              onPressed: _submit,
                              backgroundColor: AppColors.accent,
                              textColor: AppColors.white,
                              icon: Icons.auto_fix_high,
                              borderRadius: r.borderRadius,
                              height: r.buttonHeight,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceRecorder(_ResponsiveHelper r) {
    return Container(
      padding: EdgeInsets.all(r.cardPadding * 0.8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(r.borderRadius),
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
                    fontSize: r.titleFontSize + 2,
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
          SizedBox(height: r.itemSpacing * 0.8),
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
                icon: Icon(Icons.refresh, size: r.subtitleFontSize + 2),
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
