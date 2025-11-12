import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Custom reusable button widget with full dynamic support
///
/// Features:
/// - Dynamic colors (background, text, border)
/// - Dynamic text with multi-language support (English/German)
/// - Icon and emoji support
/// - Multiple button variants (filled, outlined, text)
/// - Loading state support
/// - Customizable sizing and styling
/// - Press animation feedback
class CustomButton extends StatefulWidget {
  /// Translation key for button text (e.g., 'common.save')
  final String label;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Button background color (default: primary)
  final Color? backgroundColor;

  /// Button text color (default: white for filled, primary for outlined)
  final Color? textColor;

  /// Border color for outlined buttons
  final Color? borderColor;

  /// Icon to display before text (optional)
  final IconData? icon;

  /// Emoji to display before text (optional, takes precedence over icon)
  final String? emoji;

  /// Button variant: 'filled', 'outlined', 'text' (default: 'filled')
  final String variant;

  /// Whether button is in loading state
  final bool isLoading;

  /// Custom width (default: full width)
  final double? width;

  /// Custom height (default: 56)
  final double height;

  /// Padding inside button
  final EdgeInsets padding;

  /// Border radius
  final double borderRadius;

  /// Font size for text
  final double fontSize;

  /// Font weight for text
  final FontWeight fontWeight;

  /// Whether to show shadow
  final bool showShadow;

  /// Icon size
  final double iconSize;

  /// Whether button is enabled
  final bool enabled;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
    this.emoji,
    this.variant = 'filled',
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.borderRadius = 12,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.showShadow = true,
    this.iconSize = 20,
    this.enabled = true,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (!widget.enabled) {
      return AppColors.textDark.withValues(alpha: 0.3);
    }

    switch (widget.variant) {
      case 'outlined':
        return Colors.transparent;
      case 'text':
        return Colors.transparent;
      default:
        return widget.backgroundColor ?? AppColors.primary;
    }
  }

  Color _getTextColor() {
    if (!widget.enabled) {
      return AppColors.textDark.withValues(alpha: 0.5);
    }

    switch (widget.variant) {
      case 'outlined':
        return widget.textColor ?? (widget.borderColor ?? AppColors.primary);
      case 'text':
        return widget.textColor ?? AppColors.primary;
      default:
        return widget.textColor ?? AppColors.white;
    }
  }

  Color _getBorderColor() {
    if (!widget.enabled) {
      return AppColors.textDark.withValues(alpha: 0.2);
    }

    switch (widget.variant) {
      case 'outlined':
        return widget.borderColor ?? AppColors.primary;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final textColor = _getTextColor();
    final borderColor = _getBorderColor();
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive font size based on screen width
    final responsiveFontSize = _calculateResponsiveFontSize(screenWidth);
    final responsiveIconSize = _calculateResponsiveIconSize(screenWidth);

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Emoji or Icon
        if (widget.emoji != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              widget.emoji!,
              style: TextStyle(fontSize: responsiveIconSize),
            ),
          )
        else if (widget.icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              widget.icon,
              size: responsiveIconSize,
              color: textColor,
            ),
          ),

        // Loading indicator or text
        if (widget.isLoading)
          SizedBox(
            width: responsiveIconSize,
            height: responsiveIconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else
          Flexible(
            child: Text(
              widget.label.tr(),
              style: TextStyle(
                fontSize: responsiveFontSize,
                fontWeight: widget.fontWeight,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );

    return GestureDetector(
      onTapDown: widget.enabled && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = true);
              _scaleController.forward();
            }
          : null,
      onTapUp: widget.enabled && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = false);
              _scaleController.reverse();
              widget.onPressed();
            }
          : null,
      onTapCancel: widget.enabled && !widget.isLoading
          ? () {
              setState(() => _isPressed = false);
              _scaleController.reverse();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: borderColor,
              width: widget.variant == 'outlined' ? 2 : 0,
            ),
            boxShadow: widget.showShadow && widget.variant == 'filled'
                ? [
                    BoxShadow(
                      color: (widget.backgroundColor ?? AppColors.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: null, // Handled by GestureDetector
              child: Padding(
                padding: widget.padding,
                child: Center(child: buttonContent),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Calculate responsive font size based on screen width
  /// Scales from 12px on small screens to 18px on large screens
  double _calculateResponsiveFontSize(double screenWidth) {
    if (screenWidth < 360) {
      return 12; // Small phones
    } else if (screenWidth < 480) {
      return 16; // Medium phones
    } else if (screenWidth < 600) {
      return 18; // Large phones
    } else if (screenWidth < 800) {
      return 20; // Tablets
    } else {
      return 24; // Large tablets/desktops
    }
  }

  /// Calculate responsive icon size based on screen width
  /// Scales from 14px on small screens to 24px on large screens
  double _calculateResponsiveIconSize(double screenWidth) {
    if (screenWidth < 360) {
      return 14; // Small phones
    } else if (screenWidth < 480) {
      return 16; // Medium phones
    } else if (screenWidth < 600) {
      return 18; // Large phones
    } else if (screenWidth < 800) {
      return 20; // Tablets
    } else {
      return 24; // Large tablets/desktops
    }
  }
}
