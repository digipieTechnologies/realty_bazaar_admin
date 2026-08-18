// File: lib/modules/auth/screens/admin_login_screen.dart
// Purpose: Super Admin Authentication screen with design system styling and live API authentication.

import 'package:brokerflow_admin/app/app_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../providers/auth/admin_auth_provider.dart';
import '../../../widgets/brand/app_logo.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/toast/app_toast.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: "super-admin@gmail.com");
  final _passwordController = TextEditingController(text: "Super@123");

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AdminAuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      AppToast.showSuccess('Welcome Super Admin', 'Authenticated successfully.');
      context.go(AppRoutes.dashboard);
    } else {
      AppToast.showError('Authentication Failed', authProvider.errorMessage ?? 'Invalid credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AdminAuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: 440.0,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: AppLogo(size: 54.0)),
                  const SizedBox(height: 20.0),
                  Center(
                    child: Text(
                      'welcome_back'.tr(),
                      style: AppTextStyles.heading1.copyWith(fontSize: 24.0, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Center(
                    child: Text(
                      'login_subtitle'.tr(),
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28.0),
                  AppTextField(
                    label: 'email'.tr(),
                    hintText: 'email_hint'.tr(),
                    controller: _emailController,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    validator: (val) => val == null || val.isEmpty ? 'please_enter_valid_email'.tr() : null,
                  ),
                  const SizedBox(height: 16.0),
                  AppTextField(
                    label: 'password'.tr(),
                    hintText: 'password_hint'.tr(),
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    validator: (val) => val == null || val.isEmpty ? 'please_enter_password'.tr() : null,
                  ),
                  const SizedBox(height: 24.0),
                  AppButton.solid(
                    width: double.infinity,
                    text: 'login'.tr(),
                    isLoading: authProvider.isLoading,
                    onPressed: _handleLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
