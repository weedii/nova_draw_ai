import 'package:flutter/material.dart';
import 'app_animations.dart';

/// Examples of how to use the reusable animations on different elements
class AnimationExamples extends StatefulWidget {
  const AnimationExamples({super.key});

  @override
  State<AnimationExamples> createState() => _AnimationExamplesState();
}

class _AnimationExamplesState extends State<AnimationExamples>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late AnimationController _bounceController;
  late AnimationController _fadeController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _swayAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create controllers using the reusable utility
    _rotationController = AppAnimations.createRotationController(vsync: this);
    _floatController = AppAnimations.createFloatController(vsync: this);
    _bounceController = AppAnimations.createBounceController(vsync: this);
    _fadeController = AppAnimations.createFadeController(vsync: this);

    // Create animations using the reusable utility
    _rotationAnimation = AppAnimations.createRotationAnimation(
      controller: _rotationController,
    );
    _floatAnimation = AppAnimations.createFloatAnimation(
      controller: _floatController,
    );
    _bounceAnimation = AppAnimations.createBounceAnimation(
      controller: _bounceController,
    );
    _swayAnimation = AppAnimations.createSwayAnimation(
      controller: _bounceController,
    );
    _fadeAnimation = AppAnimations.createFadeAnimation(
      controller: _fadeController,
    );

    // Start animations
    _fadeController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animation Examples')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Example 1: Rotating Text
              const Text('Rotating Text:', style: TextStyle(fontSize: 18)),
              AppAnimatedRotation(
                animation: _rotationAnimation,
                child: const Text(
                  'Hello World! 🌍',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),

              const Divider(),

              // Example 2: Floating Image
              const Text('Floating Image:', style: TextStyle(fontSize: 18)),
              AppAnimatedFloat(
                animation: _floatAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),

              const Divider(),

              // Example 3: Bouncing Button
              const Text('Bouncing Button:', style: TextStyle(fontSize: 18)),
              AppAnimatedBounce(
                bounceAnimation: _bounceAnimation,
                swayAnimation: _swayAnimation,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'Bouncy Button!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const Divider(),

              // Example 4: Floating Icon
              const Text('Floating Icon:', style: TextStyle(fontSize: 18)),
              AppAnimatedFloat(
                animation: _floatAnimation,
                child: const Icon(
                  Icons.star,
                  size: 60,
                  color: Colors.orange,
                ),
              ),

              const Divider(),

              // Example 5: Rotating Container
              const Text('Rotating Container:', style: TextStyle(fontSize: 18)),
              AppAnimatedRotation(
                animation: _rotationAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.pink],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      '🎨',
                      style: TextStyle(fontSize: 30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
