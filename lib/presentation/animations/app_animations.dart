import 'package:flutter/material.dart';

/// Reusable animations that can be applied to any widget
class AppAnimations {
  /// Creates a continuous rotation animation
  /// [duration] - How long one full rotation takes
  /// [clockwise] - Direction of rotation (true = clockwise, false = counter-clockwise)
  static AnimationController createRotationController({
    required TickerProvider vsync,
    Duration duration = const Duration(seconds: 10),
  }) {
    return AnimationController(duration: duration, vsync: vsync)..repeat();
  }

  /// Creates a rotation animation (0 to 2π radians)
  /// [controller] - The animation controller
  /// [clockwise] - Direction of rotation
  static Animation<double> createRotationAnimation({
    required AnimationController controller,
    bool clockwise = true,
  }) {
    return Tween<double>(
      begin: 0,
      end: clockwise ? 2 * 3.14159 : -2 * 3.14159,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }

  /// Creates a floating/bounce animation controller
  /// [duration] - How long one bounce cycle takes (one direction, total cycle is 2x duration)
  static AnimationController createFloatController({
    required TickerProvider vsync,
    Duration duration = const Duration(seconds: 3),
  }) {
    return AnimationController(duration: duration, vsync: vsync)
      ..repeat(reverse: true); // Smoothly reverses instead of snapping back
  }

  /// Creates a vertical floating animation
  /// [controller] - The animation controller
  /// [distance] - How far the element moves up/down
  static Animation<double> createFloatAnimation({
    required AnimationController controller,
    double distance = 20.0,
  }) {
    return Tween<double>(
      begin: 0,
      end: -distance,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// Creates a bounce animation controller (for mascot-like bouncing)
  /// [duration] - How long one bounce cycle takes (one direction, total cycle is 2x duration)
  static AnimationController createBounceController({
    required TickerProvider vsync,
    Duration duration = const Duration(seconds: 2),
  }) {
    return AnimationController(duration: duration, vsync: vsync)
      ..repeat(reverse: true); // Smoothly reverses for natural bouncing
  }

  /// Creates a vertical bounce animation
  /// [controller] - The animation controller
  /// [bounceHeight] - How high the bounce goes
  static Animation<double> createBounceAnimation({
    required AnimationController controller,
    double bounceHeight = 10.0,
  }) {
    return Tween<double>(
      begin: 0,
      end: -bounceHeight,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// Creates a subtle rotation animation (for gentle swaying)
  /// [controller] - The animation controller
  /// [angle] - Maximum rotation angle in radians (0.1 = ~5.7 degrees)
  static Animation<double> createSwayAnimation({
    required AnimationController controller,
    double angle = 0.1,
  }) {
    return Tween<double>(
      begin: -angle,
      end: angle,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// Creates a fade-in animation controller
  /// [duration] - How long the fade takes
  static AnimationController createFadeController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return AnimationController(duration: duration, vsync: vsync);
  }

  /// Creates a fade animation (0 to 1 opacity)
  /// [controller] - The animation controller
  static Animation<double> createFadeAnimation({
    required AnimationController controller,
  }) {
    return Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  /// Creates a scale animation controller
  /// [duration] - How long the scale animation takes
  static AnimationController createScaleController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return AnimationController(duration: duration, vsync: vsync);
  }

  /// Creates a scale animation
  /// [controller] - The animation controller
  /// [fromScale] - Starting scale (1.0 = normal size)
  /// [toScale] - Ending scale
  static Animation<double> createScaleAnimation({
    required AnimationController controller,
    double fromScale = 0.8,
    double toScale = 1.0,
  }) {
    return Tween<double>(
      begin: fromScale,
      end: toScale,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }
}

/// Wrapper widgets for easy animation application
class AppAnimatedRotation extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const AppAnimatedRotation({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.rotate(angle: animation.value, child: this.child);
      },
    );
  }
}

class AppAnimatedFloat extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const AppAnimatedFloat({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: this.child,
        );
      },
    );
  }
}

class AppAnimatedBounce extends StatelessWidget {
  final Widget child;
  final Animation<double> bounceAnimation;
  final Animation<double>? swayAnimation;

  const AppAnimatedBounce({
    super.key,
    required this.child,
    required this.bounceAnimation,
    this.swayAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: swayAnimation != null
          ? Listenable.merge([bounceAnimation, swayAnimation!])
          : bounceAnimation,
      builder: (context, child) {
        Widget result = Transform.translate(
          offset: Offset(0, bounceAnimation.value),
          child: this.child,
        );

        if (swayAnimation != null) {
          result = Transform.rotate(angle: swayAnimation!.value, child: result);
        }

        return result;
      },
    );
  }
}
