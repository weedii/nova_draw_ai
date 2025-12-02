import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../services/actions/auth_api_service.dart';
import '../../services/actions/api_exceptions.dart';
import '../animations/app_animations.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _changeLanguage(Locale locale) {
    context.setLocale(locale);
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'auth.change_password'.tr(),
                style: const TextStyle(
                  fontFamily: 'Comic Sans MS',
                  color: AppColors.primary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'auth.current_password'.tr(),
                      hintText: 'auth.current_password_hint'.tr(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'auth.error_password_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'auth.new_password'.tr(),
                      hintText: 'auth.new_password_hint'.tr(),
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'auth.error_password_required'.tr();
                      }
                      if (value.length < 6) {
                        return 'auth.error_password_length'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'auth.confirm_password'.tr(),
                      hintText: 'auth.confirm_password_hint'.tr(),
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'auth.error_confirm_password_required'.tr();
                      }
                      if (value != newPasswordController.text) {
                        return 'auth.error_passwords_not_match'.tr();
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'common.cancel'.tr(),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      try {
                        await AuthApiService.changePassword(
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                        );
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          // Show success dialog
                          showDialog(
                            context: this.context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'auth.password_changed'.tr(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    'auth.errors.ok'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } on ApiException catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          String errorMessage = e.message;

                          // Map backend errors to translations (matching login/register pattern)
                          if (e.statusCode == 400 &&
                              e.message.contains(
                                'Current password is incorrect',
                              )) {
                            errorMessage =
                                'auth.errors.current_password_incorrect'.tr();
                          } else if (e.statusCode == 400 &&
                              e.message.contains(
                                'New password must be different',
                              )) {
                            errorMessage = 'auth.errors.new_password_same'.tr();
                          } else if (e.statusCode == 400 &&
                              e.message.contains('Password must be at least')) {
                            errorMessage = 'auth.errors.weak_password_message'
                                .tr();
                          } else if (e.statusCode == 401) {
                            errorMessage = 'auth.errors.session_expired'.tr();
                          } else if (e.statusCode == 500) {
                            errorMessage = 'auth.errors.server_error_message'
                                .tr();
                          }

                          AppDialog.showError(
                            dialogContext,
                            title: 'common.error'.tr(),
                            message: errorMessage,
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          AppDialog.showError(
                            dialogContext,
                            title: 'common.error'.tr(),
                            message: 'auth.errors.server_error_message'.tr(),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'auth.change_password'.tr(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    // Dispose controllers after dialog is fully closed
    // Use Future.delayed to ensure dialog animation completes
    Future.delayed(const Duration(milliseconds: 300), () {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text(
              'settings.logout'.tr(),
              style: const TextStyle(
                fontFamily: 'Comic Sans MS',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Text(
          'settings.logout_confirmation'.tr(),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'settings.logout'.tr(),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        // Logout
        await userProvider.logout();

        // Router will automatically redirect to /signin
        // because of the auth state change
      } catch (e) {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to logout: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch user provider for user data
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;
    final isLoading = userProvider.isLoading;

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
                  title: 'settings.settings',
                  subtitle: 'settings.app_settings',
                  emoji: '⚙️',
                  showBackButton: true,
                  showAnimation: true,
                ),

                // Settings Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // User Profile Section
                        if (isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (currentUser != null)
                          _UserProfileCard(user: currentUser),

                        const SizedBox(height: 24),

                        // Language Section
                        _SettingsSectionCard(
                          title: 'settings.language',
                          icon: '🌐',
                          child: Column(
                            children: [
                              Text(
                                'settings.select_language'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDark.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _LanguageButton(
                                      label: 'settings.english',
                                      isSelected:
                                          context.locale.languageCode == 'en',
                                      onTap: () =>
                                          _changeLanguage(const Locale('en')),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _LanguageButton(
                                      label: 'settings.german',
                                      isSelected:
                                          context.locale.languageCode == 'de',
                                      onTap: () =>
                                          _changeLanguage(const Locale('de')),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Account Section (Change Password + Logout)
                        _SettingsSectionCard(
                          title: 'settings.account',
                          icon: '👤',
                          child: Column(
                            children: [
                              // Change Password Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _showChangePasswordDialog,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.lock, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'auth.change_password'.tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Comic Sans MS',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Logout Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _logout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'settings.logout'.tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Comic Sans MS',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // About Section
                        _SettingsSectionCard(
                          title: 'settings.about',
                          icon: 'ℹ️',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'settings.app_description'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    'settings.version'.tr(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textDark.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '1.0.0',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
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

class _SettingsSectionCard extends StatelessWidget {
  final String title;
  final String icon;
  final Widget child;

  const _SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                title.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Comic Sans MS',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LanguageButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<_LanguageButton>
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
              colors: widget.isSelected
                  ? [AppColors.primary, AppColors.primaryDark]
                  : [
                      AppColors.secondary.withValues(alpha: 0.2),
                      AppColors.accent.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Center(
            child: Text(
              widget.label.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.isSelected ? AppColors.white : AppColors.textDark,
                fontFamily: 'Comic Sans MS',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  final User user;

  const _UserProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(user.name ?? user.email),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  fontFamily: 'Comic Sans MS',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    fontFamily: 'Comic Sans MS',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Text('⭐', style: TextStyle(fontSize: 16)),
                SizedBox(width: 4),
                Text(
                  'Pro',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
