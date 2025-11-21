import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/error_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedBirthdate;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        print('🎯 Sign up button pressed!');
        print('📧 Email: ${_emailController.text.trim()}');
        print('👤 Name: ${_nameController.text.trim()}');
        
        // Test connection first
        print('🧪 Testing backend connection...');
        final isConnected = await authProvider.testConnection();
        if (!isConnected) {
          throw Exception('Cannot connect to server. Please check if the backend is running.');
        }
        print('✅ Backend connection successful!');
        
        // Call the auth provider to register
        print('📝 Calling register...');
        print('🎂 Birthdate: $_selectedBirthdate');
        await authProvider.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim().isEmpty 
              ? null 
              : _nameController.text.trim(),
          birthdate: _selectedBirthdate,
        );

        print('🎉 Registration completed successfully!');

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth.account_created'.tr()),
              backgroundColor: AppColors.success,
            ),
          );

          // Router will automatically redirect to /drawings/categories
          // because of the auth state change
        }
      } catch (e) {
        print('💥 Error during sign up: $e');

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

  void _navigateToSignIn() {
    context.push("/signin");
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010, 1, 1), // Default to 2010 for kids
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth provider for loading state
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

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
                                  colors: [
                                    AppColors.accent,
                                    AppColors.secondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add,
                                size: 60,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'auth.create_account'.tr(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'auth.sign_up_subtitle'.tr(),
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

                        const SizedBox(height: 40),

                        // Sign up form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AuthTextField(
                                labelText: 'auth.full_name'.tr(),
                                hintText: 'auth.name_hint'.tr(),
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'auth.error_name_required'.tr();
                                  }
                                  if (value.length < 2) {
                                    return 'auth.error_name_length'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
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
                              // Birthdate Field
                              GestureDetector(
                                onTap: _selectBirthdate,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.cake_outlined,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Birthdate (Optional)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textDark.withValues(alpha: 0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _selectedBirthdate != null
                                                  ? DateFormat('MMM dd, yyyy').format(_selectedBirthdate!)
                                                  : 'Select your birthdate',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: _selectedBirthdate != null
                                                    ? AppColors.textDark
                                                    : AppColors.textDark.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today,
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
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
                                  if (value.length < 6) {
                                    return 'auth.error_password_length'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                labelText: 'auth.confirm_password'.tr(),
                                hintText: 'auth.confirm_password_hint'.tr(),
                                isPassword: true,
                                controller: _confirmPasswordController,
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'auth.error_confirm_password'.tr();
                                  }
                                  if (value != _passwordController.text) {
                                    return 'auth.error_passwords_mismatch'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              AuthButton(
                                text: 'auth.create_account'.tr(),
                                onPressed: _signUp,
                                isLoading: isLoading,
                                icon: const Icon(Icons.person_add, size: 20),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Sign in link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.already_have_account'.tr(),
                              style: TextStyle(
                                color: AppColors.textDark.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: _navigateToSignIn,
                              child: Text(
                                'auth.sign_in'.tr(),
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
        if (isLoading)
          CustomLoadingWidget(
            message: 'auth.creating_account',
            subtitle: 'common.please_wait',
          ),
      ],
    );
  }
}
