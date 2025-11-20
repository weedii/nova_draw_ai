import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../services/auth_service.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/error_dialog.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('🎯 Sign in button pressed!');
        print('📧 Email: ${_emailController.text.trim()}');
        
        // Call the auth service to login
        print('📝 Calling login API...');
        final authResponse = await AuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        print('🎉 Login completed successfully!');
        
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth.sign_in_successful'.tr()),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate to drawing categories
          context.go('/drawings/categories');
        }
      } catch (e) {
        print('💥 Error during sign in: $e');
        
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          // Show beautiful error dialog
          final errorMessage = e.toString().replaceAll('Exception: ', '');
          print('🚨 Showing error to user: $errorMessage');
          
          ErrorDialog.showError(context, errorMessage);
        }
      }
    } else {
      print('❌ Form validation failed');
    }
  }

  void _navigateToSignUp() {
    context.push("/signup");
  }

  void _navigateToResetPassword() {
    context.push("/resetpassword");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // Logo and title
                        Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(60),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.primary, AppColors.accent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 60,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'common.app_name'.tr(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'auth.sign_in_subtitle'.tr(),
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

                        const SizedBox(height: 48),

                        // Sign in form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AuthTextField(
                                labelText: 'auth.email'.tr(),
                                hintText: 'auth.email_hint'.tr(),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.primary,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'auth.error_email_required'.tr();
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'auth.error_email_invalid'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                labelText: 'auth.password'.tr(),
                                hintText: 'auth.password_hint'.tr(),
                                isPassword: true,
                                controller: _passwordController,
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'auth.error_password_required'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _navigateToResetPassword,
                                  child: Text(
                                    'auth.forgot_password'.tr(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              AuthButton(
                                text: 'auth.sign_in'.tr(),
                                onPressed: _signIn,
                                isLoading: _isLoading,
                                icon: const Icon(Icons.login, size: 20),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.dont_have_account'.tr(),
                              style: TextStyle(
                                color: AppColors.textDark.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: _navigateToSignUp,
                              child: Text(
                                'auth.sign_up'.tr(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Full-screen loading overlay
        if (_isLoading)
          CustomLoadingWidget(
            message: 'auth.signing_in',
            subtitle: 'common.please_wait',
          ),
      ],
    );
  }
}
