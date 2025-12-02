import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../services/actions/auth_api_service.dart';
import '../../../services/actions/api_exceptions.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/app_dialog.dart';

/// Reset password flow steps
enum ResetStep { email, otp, success }

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  // Form keys for each step
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  ResetStep _currentStep = ResetStep.email;
  bool _isLoading = false;
  String _loadingMessage = '';

  // Animations
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
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Step 1: Send reset code to email
  Future<void> _sendResetCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'auth.sending_reset_link';
    });

    try {
      await AuthApiService.forgotPassword(email: _emailController.text.trim());

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = ResetStep.otp;
        });
        _fadeController.reset();
        _fadeController.forward();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = e.message;

        // Map specific error messages to translations (matching login/register pattern)
        if (e.statusCode == 500) {
          errorMessage = 'auth.errors.server_error_message'.tr();
        }

        AppDialog.showError(
          context,
          title: 'common.error'.tr(),
          message: errorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppDialog.showError(
          context,
          title: 'common.error'.tr(),
          message: 'auth.errors.server_error_message'.tr(),
        );
      }
    }
  }

  /// Step 2: Verify code and reset password
  Future<void> _resetPassword() async {
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'auth.resetting_password';
    });

    try {
      await AuthApiService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = ResetStep.success;
        });
        _successController.forward();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = e.message;

        // Map specific error messages to translations (matching login/register pattern)
        if (e.statusCode == 404 && e.message.contains('User not found')) {
          errorMessage = 'auth.errors.reset_user_not_found'.tr();
        } else if (e.statusCode == 400 &&
            e.message.contains('Invalid reset code')) {
          errorMessage = 'auth.errors.invalid_reset_code'.tr();
        } else if (e.statusCode == 400 && e.message.contains('expired')) {
          errorMessage = 'auth.errors.reset_code_expired'.tr();
        } else if (e.statusCode == 400 &&
            e.message.contains('Password must be at least')) {
          errorMessage = 'auth.errors.weak_password_message'.tr();
        } else if (e.statusCode == 500) {
          errorMessage = 'auth.errors.server_error_message'.tr();
        }

        AppDialog.showError(
          context,
          title: 'common.error'.tr(),
          message: errorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppDialog.showError(
          context,
          title: 'common.error'.tr(),
          message: 'auth.errors.server_error_message'.tr(),
        );
      }
    }
  }

  /// Resend the reset code
  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'auth.sending_reset_link';
    });

    try {
      await AuthApiService.forgotPassword(email: _emailController.text.trim());

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.code_resent'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = e.message;

        // Map specific error messages to translations (matching login/register pattern)
        if (e.statusCode == 500) {
          errorMessage = 'auth.errors.server_error_message'.tr();
        }

        AppDialog.showError(
          context,
          title: 'common.error'.tr(),
          message: errorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppDialog.showError(
          context,
          title: 'common.error'.tr(),
          message: 'auth.errors.server_error_message'.tr(),
        );
      }
    }
  }

  void _navigateToSignIn() {
    context.pushReplacement("/signin");
  }

  void _goBackToEmail() {
    setState(() {
      _currentStep = ResetStep.email;
      _codeController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
    _fadeController.reset();
    _fadeController.forward();
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
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildCurrentStep(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          CustomLoadingWidget(
            message: _loadingMessage,
            subtitle: 'common.please_wait',
          ),
      ],
    );
  }

  Widget _buildHeader() {
    IconData icon;
    List<Color> gradientColors;
    String title;
    String subtitle;

    switch (_currentStep) {
      case ResetStep.email:
        icon = Icons.lock_reset;
        gradientColors = [AppColors.secondary, AppColors.accent];
        title = 'auth.reset_password'.tr();
        subtitle = 'auth.enter_email_reset'.tr();
        break;
      case ResetStep.otp:
        icon = Icons.pin;
        gradientColors = [AppColors.primary, AppColors.accent];
        title = 'auth.enter_code'.tr();
        subtitle = '${'auth.code_sent_to'.tr()} ${_emailController.text}';
        break;
      case ResetStep.success:
        icon = Icons.check_circle;
        gradientColors = [
          AppColors.success,
          AppColors.success.withValues(alpha: 0.7),
        ];
        title = 'auth.password_reset_success'.tr();
        subtitle = 'auth.can_now_login'.tr();
        break;
    }

    return Column(
      children: [
        ScaleTransition(
          scale: _currentStep == ResetStep.success
              ? _successAnimation
              : Tween<double>(begin: 1.0, end: 1.0).animate(_fadeController),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, size: 60, color: AppColors.white),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _currentStep == ResetStep.success
                ? AppColors.success
                : AppColors.primary,
            fontFamily: 'Comic Sans MS',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textDark.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case ResetStep.email:
        return _buildEmailStep();
      case ResetStep.otp:
        return _buildOtpStep();
      case ResetStep.success:
        return _buildSuccessStep();
    }
  }

  /// Step 1: Email input form
  Widget _buildEmailStep() {
    return Column(
      children: [
        Form(
          key: _emailFormKey,
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
              const SizedBox(height: 32),
              AuthButton(
                text: 'auth.send_reset_code'.tr(),
                onPressed: _sendResetCode,
                icon: const Icon(Icons.send, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildBackToSignIn(),
      ],
    );
  }

  /// Step 2: OTP code and new password form
  Widget _buildOtpStep() {
    return Column(
      children: [
        Form(
          key: _otpFormKey,
          child: Column(
            children: [
              // OTP Code field
              AuthTextField(
                labelText: 'auth.reset_code'.tr(),
                hintText: 'auth.reset_code_hint'.tr(),
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                prefixIcon: const Icon(Icons.pin, color: AppColors.primary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.error_code_required'.tr();
                  }
                  if (value.length != 6) {
                    return 'auth.error_code_length'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // New password field
              AuthTextField(
                labelText: 'auth.new_password'.tr(),
                hintText: 'auth.new_password_hint'.tr(),
                controller: _newPasswordController,
                isPassword: true,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
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
              const SizedBox(height: 20),

              // Confirm password field
              AuthTextField(
                labelText: 'auth.confirm_password'.tr(),
                hintText: 'auth.confirm_new_password_hint'.tr(),
                controller: _confirmPasswordController,
                isPassword: true,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.error_confirm_password_required'.tr();
                  }
                  if (value != _newPasswordController.text) {
                    return 'auth.error_passwords_not_match'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              AuthButton(
                text: 'auth.reset_password'.tr(),
                onPressed: _resetPassword,
                icon: const Icon(Icons.check, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Resend code and back buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _resendCode,
              child: Text(
                'auth.resend_code'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(' | '),
            TextButton(
              onPressed: _goBackToEmail,
              child: Text(
                'auth.change_email'.tr(),
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Step 3: Success state
  Widget _buildSuccessStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.celebration, size: 48, color: AppColors.success),
              const SizedBox(height: 16),
              Text(
                'auth.password_changed_message'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AuthButton(
          text: 'auth.go_to_signin'.tr(),
          onPressed: _navigateToSignIn,
          icon: const Icon(Icons.login, size: 20),
        ),
      ],
    );
  }

  Widget _buildBackToSignIn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'auth.remember_password'.tr(),
          style: TextStyle(
            color: AppColors.textDark.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: _navigateToSignIn,
          child: Text(
            'auth.back_to_signin'.tr(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
