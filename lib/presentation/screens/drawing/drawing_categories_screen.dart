import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../models/ui_models.dart';
import '../../../providers/drawing_provider.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loading_widget.dart';

class DrawingCategoriesScreen extends StatefulWidget {
  const DrawingCategoriesScreen({super.key});

  @override
  State<DrawingCategoriesScreen> createState() =>
      _DrawingCategoriesScreenState();
}

class _DrawingCategoriesScreenState extends State<DrawingCategoriesScreen>
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

    // Load categories from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DrawingProvider>().loadCategoriesWithDrawingsFromApi();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onCategorySelected(DrawingCategory category) {
    // Update provider state
    context.read<DrawingProvider>().selectCategory(category.categoryEn);
    // Navigate to drawing items screen to select specific drawing
    context.push('/drawings/${Uri.encodeComponent(category.categoryEn)}');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, drawingProvider, child) {
        // Handle loading state
        if (drawingProvider.isLoadingCategories) {
          return CustomLoadingWidget(
            message: 'categories.loading_categories',
            subtitle: 'common.please_wait',
            showBackButton: false,
          );
        }

        // Handle error state
        if (drawingProvider.categoriesState == CategoriesState.error) {
          return _buildErrorScreen(drawingProvider);
        }

        // Handle empty state
        if (drawingProvider.categoriesState == CategoriesState.empty) {
          return _buildEmptyScreen();
        }

        final categories = drawingProvider.categories;

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
                          title: 'categories.choose_drawing',
                          subtitle: 'categories.select_category',
                          emoji: '🎨',
                          showBackButton: false,
                          showAnimation: true,
                          showSettingsButton: true,
                        ),

                        // Categories Grid
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: GridView.builder(
                              padding: const EdgeInsets.only(
                                top: 16.0,
                                bottom: 120.0,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    mainAxisExtent: 220,
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen(DrawingProvider provider) {
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
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'categories.error'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (provider.categoriesError ?? 'categories.error_unknown')
                        .tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => provider.retryLoadCategories(),
                    icon: const Icon(Icons.refresh),
                    label: Text('common.retry'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'categories.no_data'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  bool _isPressed = false;

  String _getCategoryTitle() {
    final isGerman = context.locale.languageCode == 'de';
    return isGerman ? widget.category.categoryDe : widget.category.categoryEn;
  }

  String _getCategoryDescription() {
    final isGerman = context.locale.languageCode == 'de';
    return (isGerman
            ? widget.category.descriptionDe
            : widget.category.descriptionEn) ??
        '';
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
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
