import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// A beautiful, reusable loading overlay widget that covers the entire screen
/// with a semi-transparent background and animated loading indicator.
///
/// This widget follows the app's color theme and provides smooth animations
/// for a polished user experience.
///
/// Example usage:
/// ```dart
/// LoadingOverlay(
///   isLoading: _isLoading,
///   message: 'Taking photo...',
///   child: YourMainWidget(),
/// )
/// ```
class LoadingOverlay extends StatefulWidget {
  /// The child widget to display behind the loading overlay
  final Widget child;

  /// Whether the loading overlay should be visible
  final bool isLoading;

  /// Optional message to display below the loading animation
  final String? message;

  /// Custom color for the loading spinner (defaults to primary color)
  final Color? spinnerColor;

  /// Custom background color for the overlay (defaults to semi-transparent black)
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.spinnerColor,
    this.backgroundColor,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle loading state changes
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _showLoading();
      } else {
        _hideLoading();
      }
    }
  }

  /// Shows the loading overlay with animations
  void _showLoading() {
    _fadeController.forward();
    _scaleController.forward();
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  /// Hides the loading overlay with animations
  void _hideLoading() {
    _fadeController.reverse();
    _scaleController.reverse();
    _rotationController.stop();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,

        // Loading overlay
        if (widget.isLoading)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color:
                      widget.backgroundColor ??
                      Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildLoadingContent(),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// Builds the main loading content with animations
  Widget _buildLoadingContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated loading spinner
          _buildAnimatedSpinner(),

          const SizedBox(height: 24),

          // Loading message
          if (widget.message != null) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    widget.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontFamily: 'Comic Sans MS',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],

          // Subtitle
          Text(
            'Please wait...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withValues(alpha: 0.6),
              fontFamily: 'Comic Sans MS',
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the animated spinner with custom design
  Widget _buildAnimatedSpinner() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Outer rotating ring
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 3.14159,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (widget.spinnerColor ?? AppColors.primary)
                          .withValues(alpha: 0.3),
                      width: 4,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.spinnerColor ?? AppColors.primary,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Inner pulsing circle
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value * 0.6,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.spinnerColor ?? AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.spinnerColor ?? AppColors.primary)
                              .withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Sparkle effect
          Positioned(
            top: 10,
            right: 10,
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_rotationAnimation.value * 3.14159 * 2,
                  child: Text(
                    '✨',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.accent.withValues(
                        alpha: 0.8 + 0.2 * _pulseAnimation.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A simpler loading widget for inline use (not full screen)
class InlineLoadingWidget extends StatefulWidget {
  /// The message to display with the loading spinner
  final String? message;

  /// Size of the loading spinner
  final double size;

  /// Color of the loading spinner
  final Color? color;

  const InlineLoadingWidget({
    super.key,
    this.message,
    this.size = 40,
    this.color,
  });

  @override
  State<InlineLoadingWidget> createState() => _InlineLoadingWidgetState();
}

class _InlineLoadingWidgetState extends State<InlineLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * 3.14159,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (widget.color ?? AppColors.primary).withValues(
                      alpha: 0.3,
                    ),
                    width: 3,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color ?? AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withValues(alpha: 0.7),
              fontFamily: 'Comic Sans MS',
            ),
          ),
        ],
      ],
    );
  }
}
