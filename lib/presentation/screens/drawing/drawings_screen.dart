import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/drawing_data.dart';
import '../../../providers/drawing_provider.dart';
import '../../animations/app_animations.dart';
import '../../widgets/custom_app_bar.dart';

class DrawingsScreen extends StatefulWidget {
  final String categoryId;

  const DrawingsScreen({super.key, required this.categoryId});

  @override
  State<DrawingsScreen> createState() => _DrawingsScreenState();
}

class _DrawingsScreenState extends State<DrawingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;

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

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _onDrawingSelected(Drawing drawing) {
    // Update provider state
    context.read<DrawingProvider>().selectDrawing(
      widget.categoryId,
      drawing.id,
    );
    // Navigate to drawing steps with both category and drawing IDs
    context.push('/drawings/${widget.categoryId}/${drawing.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Center(
            child: Text(
              'drawings.category_not_found'.tr(),
              style: const TextStyle(fontSize: 24, color: AppColors.textDark),
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
                CustomAppBar(
                  title: 'drawings.select_drawing',
                  subtitle: 'drawings.choose_what_to_draw',
                  actionWidget: Text(
                    category!.icon,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),

                // Category badge
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: category!.color,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Drawing Items List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ListView.builder(
                      itemCount: category!.drawings.length,
                      itemBuilder: (context, index) {
                        final drawing = category!.drawings[index];
                        return _DrawingCard(
                          drawing: drawing,
                          categoryColor: category!.color,
                          onTap: () => _onDrawingSelected(drawing),
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

class _DrawingCard extends StatefulWidget {
  final Drawing drawing;
  final Color categoryColor;
  final VoidCallback onTap;
  final Duration delay;

  const _DrawingCard({
    required this.drawing,
    required this.categoryColor,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_DrawingCard> createState() => _DrawingCardState();
}

class _DrawingCardState extends State<_DrawingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String _getDrawingName() {
    final isGerman = context.locale.languageCode == 'de';
    return isGerman ? widget.drawing.nameDe : widget.drawing.nameEn;
  }

  String _getStepsDescription() {
    final isGerman = context.locale.languageCode == 'de';
    final stepsText = isGerman ? 'Schritte' : 'Steps';
    return '${widget.drawing.steps.length} $stepsText';
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
                        widget.drawing.emoji,
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
                        // Drawing name
                        Text(
                          _getDrawingName(),
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
