import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/drawing_data.dart';
import '../../animations/app_animations.dart';

class DrawingItemsScreen extends StatefulWidget {
  final String categoryId;

  const DrawingItemsScreen({super.key, required this.categoryId});

  @override
  State<DrawingItemsScreen> createState() => _DrawingItemsScreenState();
}

class _DrawingItemsScreenState extends State<DrawingItemsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sparkleFloat;

  DrawingCategory? category;

  String _getCategoryTitle() {
    if (category == null) return '';
    final isGerman = context.locale.languageCode == 'de';
    return isGerman ? category!.titleDe : category!.titleEn;
  }

  @override
  void initState() {
    super.initState();

    // Get category data
    category = DrawingData.getCategoryById(widget.categoryId);

    // Initialize animations
    _fadeController = AppAnimations.createFadeController(vsync: this);
    _sparkleController = AppAnimations.createFloatController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );
    _sparkleFloat = AppAnimations.createFloatAnimation(
      controller: _sparkleController,
      distance: 20.0,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _onDrawingItemSelected(DrawingItem item) {
    // Navigate to drawing steps with both category and item IDs
    context.push('/drawing-steps/${widget.categoryId}/${item.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: const Center(
            child: Text(
              'Category not found',
              style: TextStyle(fontSize: 24, color: AppColors.textDark),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Stack(
                    children: [
                      // Back button
                      Positioned(
                        left: 0,
                        top: 0,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),

                      // Decorative elements
                      Positioned(
                        top: 10,
                        right: 20,
                        child: Text(
                          category!.icon,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),

                      // Main title
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'select_drawing'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: category!.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: category!.color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _getCategoryTitle(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: category!.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'choose_what_to_draw'.tr(),
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

                // Drawing Items List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ListView.builder(
                      itemCount: category!.items.length,
                      itemBuilder: (context, index) {
                        final item = category!.items[index];
                        return _DrawingItemCard(
                          item: item,
                          categoryColor: category!.color,
                          onTap: () => _onDrawingItemSelected(item),
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
  }
}

class _DrawingItemCard extends StatefulWidget {
  final DrawingItem item;
  final Color categoryColor;
  final VoidCallback onTap;
  final Duration delay;

  const _DrawingItemCard({
    required this.item,
    required this.categoryColor,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_DrawingItemCard> createState() => _DrawingItemCardState();
}

class _DrawingItemCardState extends State<_DrawingItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String _getItemName() {
    final isGerman = context.locale.languageCode == 'de';
    return isGerman ? widget.item.nameDe : widget.item.nameEn;
  }

  String _getStepsDescription() {
    final isGerman = context.locale.languageCode == 'de';
    final stepsText = isGerman ? 'Schritte' : 'Steps';
    return '${widget.item.steps.length} $stepsText';
  }

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Delayed entrance animation
    Future.delayed(widget.delay, () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.categoryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: widget.categoryColor.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Item emoji/icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.categoryColor,
                          widget.categoryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        widget.item.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Item details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name
                        Text(
                          _getItemName(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Comic Sans MS',
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Steps count
                        Text(
                          _getStepsDescription(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: widget.categoryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
