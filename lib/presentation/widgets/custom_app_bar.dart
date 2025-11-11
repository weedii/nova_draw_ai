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
  final bool showSettingsButton;
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
    this.showSettingsButton = false,
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
        distance: 10.0,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          // Top row: Back button, Settings button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                )
              else
                const SizedBox(width: 40),

              // Settings button
              if (widget.showSettingsButton)
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: Icon(
                    Icons.settings_outlined,
                    color: AppColors.textDark.withValues(alpha: 0.8),
                    size: 35,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                )
              else if (widget.actionWidget != null)
                widget.actionWidget!
              else
                const SizedBox(width: 40),
            ],
          ),

          const SizedBox(height: 8),

          // Title and subtitle section
          if (widget.centerTitle)
            Column(
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
                      fontSize: 14,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
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
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
