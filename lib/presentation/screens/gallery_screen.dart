import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../animations/app_animations.dart';
import '../widgets/custom_app_bar.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header
                    CustomAppBar(
                      title: 'navigation.gallery',
                      subtitle: 'Coming soon...',
                      emoji: '🖼️',
                      showBackButton: false,
                      showAnimation: true,
                      showSettingsButton: false,
                    ),
                    // Empty Gallery State
                    Expanded(child: Center(child: _buildEmptyGalleryState())),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGalleryState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Large empty icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.accent.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.collections_outlined,
            size: 60,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        // Title
        Text(
          'Gallery',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontFamily: 'Comic Sans MS',
          ),
        ),
        const SizedBox(height: 12),
        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Your amazing drawings will appear here! Start creating to build your gallery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withValues(alpha: 0.7),
              fontFamily: 'Comic Sans MS',
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Decorative elements
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDecorativeElement('🎨'),
            const SizedBox(width: 16),
            _buildDecorativeElement('✨'),
            const SizedBox(width: 16),
            _buildDecorativeElement('🌟'),
          ],
        ),
      ],
    );
  }

  Widget _buildDecorativeElement(String emoji) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
    );
  }
}
