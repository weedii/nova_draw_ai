import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import 'drawing/drawing_categories_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Screens for bottom navigation (removed DirectUploadScreen)
  late final List<Widget> _screens;

  // Animation controller for bottom nav visibility
  late AnimationController _navAnimationController;
  late Animation<Offset> _navOffsetAnimation;

  bool _isNavVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _screens = [const DrawingCategoriesScreen(), const GalleryScreen()];

    // Initialize animation controller for bottom nav
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _navOffsetAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 1.5), // Slide down off screen
        ).animate(
          CurvedAnimation(
            parent: _navAnimationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final currentOffset = notification.metrics.pixels;
      final delta = currentOffset - _lastScrollOffset;

      // Only trigger animation if scroll delta is significant (> 5 pixels)
      if (delta.abs() > 5) {
        if (delta > 0) {
          // Scrolling down - hide nav
          if (_isNavVisible) {
            setState(() => _isNavVisible = false);
            _navAnimationController.forward();
          }
        } else {
          // Scrolling up - show nav
          if (!_isNavVisible) {
            setState(() => _isNavVisible = true);
            _navAnimationController.reverse();
          }
        }
        _lastScrollOffset = currentOffset;
      }
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // Reset nav visibility when switching tabs
      if (!_isNavVisible) {
        _isNavVisible = true;
        _navAnimationController.reverse();
      }
      _lastScrollOffset = 0;
    });
  }

  void _navigateToDirectUpload() {
    context.push('/direct-upload');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Wrap screen with NotificationListener to detect scroll events
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _onScroll(notification);
              return false; // Allow notification to bubble up
            },
            child: _screens[_selectedIndex],
          ),
          // Floating Navigation Bar - positioned absolutely with animation
          Positioned(
            left: 25,
            right: 25,
            bottom: 30,
            child: SlideTransition(
              position: _navOffsetAnimation,
              child: _buildFloatingNavigationBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavigationBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFloatingNavItem(
                icon: Icons.palette,
                outlinedIcon: Icons.palette_outlined,
                label: 'navigation.tutorials'.tr(),
                isSelected: _selectedIndex == 0,
                onTap: () => _onNavItemTapped(0),
              ),
              _buildFloatingNavItem(
                icon: Icons.add_photo_alternate,
                outlinedIcon: Icons.add_photo_alternate_outlined,
                label: 'navigation.upload'.tr(),
                isSelected: false,
                onTap: _navigateToDirectUpload,
              ),
              _buildFloatingNavItem(
                icon: Icons.collections,
                outlinedIcon: Icons.collections_outlined,
                label: 'navigation.gallery'.tr(),
                isSelected: _selectedIndex == 1,
                onTap: () => _onNavItemTapped(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required IconData icon,
    required IconData outlinedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? icon : outlinedIcon,
                  size: 24,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textDark.withValues(alpha: 0.6),
                  fontFamily: 'Comic Sans MS',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
