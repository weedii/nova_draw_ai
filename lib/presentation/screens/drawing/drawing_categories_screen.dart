import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/drawing_data.dart';
import '../../../providers/drawing_provider.dart';
import '../../animations/app_animations.dart';

class DrawingCategoriesScreen extends StatefulWidget {
  const DrawingCategoriesScreen({super.key});

  @override
  State<DrawingCategoriesScreen> createState() =>
      _DrawingCategoriesScreenState();
}

class _DrawingCategoriesScreenState extends State<DrawingCategoriesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sparkleFloat;

  @override
  void initState() {
    super.initState();

    _fadeController = AppAnimations.createFadeController(vsync: this);
    _sparkleController = AppAnimations.createFloatController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _sparkleFloat = AppAnimations.createFloatAnimation(
      controller: _sparkleController,
      distance: 15.0,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _onCategorySelected(DrawingCategory category) {
    // Update provider state
    context.read<DrawingProvider>().selectCategory(category.id);
    // Navigate to drawing items screen to select specific drawing
    context.push('/drawings/${category.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, drawingProvider, child) {
        final categories = drawingProvider.categories;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header with decorative elements
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      child: Stack(
                        children: [
                          // Decorative sparkles
                          Positioned(
                            top: 5,
                            right: 0,
                            child: const Text(
                              '🎨',
                              style: TextStyle(fontSize: 30),
                            ),
                          ),

                          // Main title
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  'categories.choose_drawing'.tr(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'categories.select_category'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textDark.withValues(
                                      alpha: 0.7,
                                    ),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Categories Grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                mainAxisExtent: 200,
                                crossAxisCount: 2,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return _CategoryCard(
                              category: category,
                              onTap: () => _onCategorySelected(category),
                              delay: Duration(milliseconds: 100 * index),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final DrawingCategory category;
  final VoidCallback onTap;
  final Duration delay;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  String _getCategoryTitle() {
    final isGerman = context.locale.languageCode == 'de';
    return isGerman ? widget.category.titleDe : widget.category.titleEn;
  }

  String _getCategoryDescription() {
    final isGerman = context.locale.languageCode == 'de';
    return isGerman
        ? widget.category.descriptionDe
        : widget.category.descriptionEn;
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Delayed entrance animation
    Future.delayed(widget.delay, () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.category.color,
                widget.category.color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.category.color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Text(
                    widget.category.icon,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                _getCategoryTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  fontFamily: 'Comic Sans MS',
                ),
              ),
              const SizedBox(height: 4),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _getCategoryDescription(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
