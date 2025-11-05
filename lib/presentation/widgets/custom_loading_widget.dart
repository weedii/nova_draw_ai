import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../animations/app_animations.dart';

/// A beautiful, reusable full-screen loading widget with creative animations
///
/// Features:
/// - Full-screen overlay with gradient background
/// - Multiple animated elements (stars, sparkles, drawing tools)
/// - Customizable loading message
/// - Follows app's color scheme and theme
/// - Child-friendly design with playful animations
class CustomLoadingWidget extends StatefulWidget {
  /// The message to display while loading (uses translation keys)
  final String message;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Whether to show the back button (default: false for full loading states)
  final bool showBackButton;

  /// Callback for back button press
  final VoidCallback? onBackPressed;

  const CustomLoadingWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  State<CustomLoadingWidget> createState() => _CustomLoadingWidgetState();
}

class _CustomLoadingWidgetState extends State<CustomLoadingWidget>
    with TickerProviderStateMixin {
  // Animation controllers for different elements
  late AnimationController _mainController;
  late AnimationController _starController;
  late AnimationController _sparkleController;
  late AnimationController _paletteController;
  late AnimationController _brushController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _mainRotation;
  late Animation<double> _starRotation;
  late Animation<double> _sparkleFloat;
  late Animation<double> _paletteFloat;
  late Animation<double> _brushSway;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Main loading spinner
    _mainController = AppAnimations.createRotationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Decorative star rotation
    _starController = AppAnimations.createRotationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Floating sparkles
    _sparkleController = AppAnimations.createFloatController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Floating palette
    _paletteController = AppAnimations.createFloatController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Swaying brush
    _brushController = AppAnimations.createBounceController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade in animation
    _fadeController = AppAnimations.createFadeController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Pulse animation for loading indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create animations
    _mainRotation = AppAnimations.createRotationAnimation(
      controller: _mainController,
      clockwise: true,
    );

    _starRotation = AppAnimations.createRotationAnimation(
      controller: _starController,
      clockwise: false,
    );

    _sparkleFloat = AppAnimations.createFloatAnimation(
      controller: _sparkleController,
      distance: 25.0,
    );

    _paletteFloat = AppAnimations.createFloatAnimation(
      controller: _paletteController,
      distance: 20.0,
    );

    _brushSway = AppAnimations.createSwayAnimation(
      controller: _brushController,
      angle: 0.15,
    );

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorAnimation =
        ColorTween(begin: AppColors.primary, end: AppColors.accent).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  void _startAnimations() {
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _starController.dispose();
    _sparkleController.dispose();
    _paletteController.dispose();
    _brushController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // Animated background elements
                _buildBackgroundElements(),

                // Main content
                _buildMainContent(),

                // Optional back button
                if (widget.showBackButton) _buildBackButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Rotating star (top-left)
        Positioned(
          top: 60,
          left: 40,
          child: AppAnimatedRotation(
            animation: _starRotation,
            child: const Text('⭐', style: TextStyle(fontSize: 50)),
          ),
        ),

        // Floating sparkles (top-right)
        Positioned(
          top: 100,
          right: 50,
          child: AppAnimatedFloat(
            animation: _sparkleFloat,
            child: const Text('✨', style: TextStyle(fontSize: 35)),
          ),
        ),

        // Floating palette (bottom-left)
        Positioned(
          bottom: 120,
          left: 30,
          child: AppAnimatedFloat(
            animation: _paletteFloat,
            child: const Text('🎨', style: TextStyle(fontSize: 45)),
          ),
        ),

        // Swaying brush (bottom-right)
        Positioned(
          bottom: 80,
          right: 40,
          child: Transform.rotate(
            angle: _brushSway.value,
            child: const Text('🖌️', style: TextStyle(fontSize: 40)),
          ),
        ),

        // Additional floating elements
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: 20,
          child: AppAnimatedFloat(
            animation: _sparkleFloat,
            child: const Text('🌈', style: TextStyle(fontSize: 30)),
          ),
        ),

        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.4,
          right: 20,
          child: AppAnimatedFloat(
            animation: _paletteFloat,
            child: const Text('🖍️', style: TextStyle(fontSize: 35)),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main loading animation
            _buildMainLoadingIndicator(),

            const SizedBox(height: 40),

            // Loading message
            _buildLoadingMessage(),

            if (widget.subtitle != null) ...[
              const SizedBox(height: 16),
              _buildSubtitle(),
            ],

            const SizedBox(height: 32),

            // Animated dots
            _buildAnimatedDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainLoadingIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _colorAnimation,
        _mainRotation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _colorAnimation.value ?? AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_colorAnimation.value ?? AppColors.primary)
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                Transform.rotate(
                  angle: _mainRotation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    child: CustomPaint(
                      painter: LoadingRingPainter(
                        progress: _mainController.value,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),

                // Center icon
                const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: AppColors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMessage() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_pulseAnimation.value - 1) * 0.05,
          child: Text(
            widget.message.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Comic Sans MS',
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return Text(
      widget.subtitle!.tr(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textDark.withValues(alpha: 0.7),
        height: 1.4,
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.3;
            final animationValue = (_pulseController.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: 0.6 + 0.4 * scale,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 20,
      left: 20,
      child: IconButton(
        onPressed: widget.onBackPressed,
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.primary,
          size: 28,
        ),
        style: IconButton.styleFrom(padding: const EdgeInsets.all(12)),
      ),
    );
  }
}

/// Custom painter for the loading ring animation
class LoadingRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  LoadingRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Draw partial arc based on progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // Start from top (-90 degrees in radians)
      2 * 3.14159 * progress, // Progress-based sweep
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(LoadingRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
