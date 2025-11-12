import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../animations/app_animations.dart';
import '../widgets/custom_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _rainbowController;
  late AnimationController _sparkleController;
  late AnimationController _fadeController;

  late Animation<double> _starRotation;
  late Animation<double> _rainbowRotation;
  late Animation<double> _sparkleFloat;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create reusable animation controllers
    _starController = AppAnimations.createRotationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _rainbowController = AppAnimations.createRotationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _sparkleController = AppAnimations.createFloatController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeController = AppAnimations.createFadeController(vsync: this);

    // Create reusable animations
    _starRotation = AppAnimations.createRotationAnimation(
      controller: _starController,
      clockwise: true,
    );

    _rainbowRotation = AppAnimations.createRotationAnimation(
      controller: _rainbowController,
      clockwise: false,
    );

    _sparkleFloat = AppAnimations.createFloatAnimation(
      controller: _sparkleController,
      distance: 20.0,
    );

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );

    // Start fade in animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    _rainbowController.dispose();
    _sparkleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onStartDrawing() {
    // TODO: Navigate to drawing screen
    context.push("/signin");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),

        child: Stack(
          children: [
            // Decorative star (top-left)
            Positioned(
              top: 40,
              left: 40,
              child: AppAnimatedRotation(
                animation: _starRotation,
                child: const Text('⭐', style: TextStyle(fontSize: 60)),
              ),
            ),

            // Decorative rainbow (bottom-right)
            Positioned(
              bottom: 80,
              right: 40,
              child: AppAnimatedRotation(
                animation: _rainbowRotation,
                child: const Text('🌈', style: TextStyle(fontSize: 50)),
              ),
            ),

            // Decorative sparkle (top-right)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              right: 80,
              child: AppAnimatedFloat(
                animation: _sparkleFloat,
                child: const Text('✨', style: TextStyle(fontSize: 40)),
              ),
            ),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Mascot with animation
                          Container(
                            width: MediaQuery.of(context).size.width < 400
                                ? 150
                                : 192,
                            height: MediaQuery.of(context).size.width < 400
                                ? 150
                                : 192,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width < 400
                                    ? 75
                                    : 96,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width < 400
                                    ? 75
                                    : 96,
                              ),
                              child: Image.network(
                                "https://images.unsplash.com/photo-1744451658473-cf5c564d5a37?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjdXRlJTIwY2FydG9vbiUyMHJvYm90JTIwbWFzY290fGVufDF8fHx8MTc2MTAzODM4M3ww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          SizedBox(
                            height: MediaQuery.of(context).size.height < 700
                                ? 16
                                : 32,
                          ),

                          // Title
                          Column(
                            children: [
                              Text(
                                'welcome_screen.welcome'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width < 400
                                      ? 36
                                      : 48,
                                  color: const Color(0xFF4DA6FF),
                                  fontFamily: 'Comic Sans MS',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'common.app_name'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width < 400
                                      ? 42
                                      : 56,
                                  color: const Color(0xFFFF7EB9),
                                  fontFamily: 'Comic Sans MS',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'welcome_screen.app_description'.tr(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF2D3748),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(
                            height: MediaQuery.of(context).size.height < 700
                                ? 24
                                : 48,
                          ),

                          // Start Button
                          CustomButton(
                            label: 'welcome_screen.start_drawing',
                            onPressed: _onStartDrawing,
                            backgroundColor: const Color(0xFF4DA6FF),
                            textColor: Colors.white,
                            icon: Icons.auto_awesome,
                            iconSize: 24,
                            height: 56,
                            fontSize: 20,
                            borderRadius: 50,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
