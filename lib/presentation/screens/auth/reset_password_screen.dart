import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _fadeController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _successController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      _successController.forward();

      // TODO: Implement actual reset password logic
    }
  }

  void _navigateToSignIn() {
    context.push("/signin");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                        ScaleTransition(
                          scale: _emailSent
                              ? _successAnimation
                              : Tween<double>(
                                  begin: 1.0,
                                  end: 1.0,
                                ).animate(_fadeController),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _emailSent
                                    ? [
                                        AppColors.success,
                                        AppColors.success.withValues(
                                          alpha: 0.7,
                                        ),
                                      ]
                                    : [AppColors.secondary, AppColors.accent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_emailSent
                                              ? AppColors.success
                                              : AppColors.secondary)
                                          .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _emailSent
                                  ? Icons.check_circle
                                  : Icons.lock_reset,
                              size: 60,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _emailSent ? 'Email Sent!' : 'reset_password'.tr(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _emailSent
                                ? AppColors.success
                                : AppColors.primary,
                            fontFamily: 'Comic Sans MS',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _emailSent
                              ? 'We\'ve sent a password reset link to ${_emailController.text}'
                              : 'enter_email_reset'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    if (!_emailSent) ...[
                      // Reset password form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AuthTextField(
                              labelText: 'email'.tr(),
                              hintText: 'email_hint'.tr(),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppColors.primary,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            AuthButton(
                              text: 'send_reset_link'.tr(),
                              onPressed: _sendResetLink,
                              isLoading: _isLoading,
                              icon: const Icon(Icons.send, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Success state
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.mail_outline,
                                  size: 48,
                                  color: AppColors.success,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Check your email and click the link to reset your password.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textDark.withValues(
                                      alpha: 0.8,
                                    ),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          AuthButton(
                            text: 'back_to_signin'.tr(),
                            onPressed: _navigateToSignIn,
                            isSecondary: true,
                            icon: const Icon(Icons.arrow_back, size: 20),
                          ),
                        ],
                      ),
                    ],

                    if (!_emailSent) ...[
                      const SizedBox(height: 32),
                      // Back to sign in link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remember your password?',
                            style: TextStyle(
                              color: AppColors.textDark.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToSignIn,
                            child: Text(
                              'back_to_signin'.tr(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
