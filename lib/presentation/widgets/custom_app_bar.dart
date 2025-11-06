import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../animations/app_animations.dart';

class CustomAppBar extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? emoji;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? actionWidget;
  final bool showAnimation;
  final bool centerTitle;
  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.emoji,
    this.showBackButton = true,
    this.onBackPressed,
    this.actionWidget,
    this.showAnimation = true,
    this.centerTitle = true,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late Animation<double> _sparkleFloat;

  @override
  void initState() {
    super.initState();

    if (widget.showAnimation && widget.emoji != null) {
      _sparkleController = AppAnimations.createFloatController(
        vsync: this,
        duration: const Duration(seconds: 4),
      );
      _sparkleFloat = AppAnimations.createFloatAnimation(
        controller: _sparkleController,
        distance: 25.0,
      );
      _sparkleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.showAnimation && widget.emoji != null) {
      _sparkleController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild when language changes
    context.locale;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Back button
          if (widget.showBackButton)
            IconButton(
              onPressed: widget.onBackPressed ?? () => context.pop(),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.primary,
                size: 24,
              ),
            ),

          // Title section
          Expanded(
            child: widget.centerTitle
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              widget.title.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                          ),
                          if (widget.emoji != null) ...[
                            const SizedBox(width: 8),
                            widget.showAnimation
                                ? AppAnimatedFloat(
                                    animation: _sparkleFloat,
                                    child: Text(
                                      widget.emoji!,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  )
                                : Text(
                                    widget.emoji!,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                          ],
                        ],
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.title.tr(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontFamily: 'Comic Sans MS',
                                    ),
                                  ),
                                ),
                                if (widget.emoji != null) ...[
                                  const SizedBox(width: 8),
                                  widget.showAnimation
                                      ? AppAnimatedFloat(
                                          animation: _sparkleFloat,
                                          child: Text(
                                            widget.emoji!,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          widget.emoji!,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                ],
                              ],
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle!.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textDark.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Action widget or spacer
          if (widget.actionWidget != null)
            widget.actionWidget!
          else if (widget.showBackButton)
            const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }
}
