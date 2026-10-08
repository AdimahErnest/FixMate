// FixMate — Forgot-password email-code flow
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/signup_helpers.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController emailController;
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool codeSent = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> sendCode() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final email = emailController.text.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showMessage(t('Please enter a valid email address.'));
      return;
    }

    setState(() => busy = true);
    final ok = await state.sendPasswordResetCode(email.toLowerCase());
    if (!mounted) return;
    setState(() {
      busy = false;
      if (ok) codeSent = true;
    });
    showMessage(
      ok
          ? t('If an account exists for this email, a code has been sent.')
          : t(state.authError),
    );
  }

  Future<void> resetPassword() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final code = codeController.text.trim();
    final newPassword = passwordController.text;

    if (code.isEmpty) {
      showMessage(t('Please enter the code from your email.'));
      return;
    }
    if (!isStrongSignupPassword(newPassword)) {
      showMessage(
        t('Use at least 8 characters with uppercase, lowercase, and a number.'),
      );
      return;
    }
    if (newPassword != confirmController.text) {
      showMessage(t('Passwords do not match.'));
      return;
    }

    setState(() => busy = true);
    final ok = await state.resetPasswordWithCode(
      email: emailController.text.trim().toLowerCase(),
      code: code,
      newPassword: newPassword,
    );
    if (!mounted) return;
    setState(() => busy = false);

    if (ok) {
      showMessage(t('Password changed. Please log in.'));
      Navigator.pop(context);
    } else {
      showMessage(t(state.authError));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Reset password')),
        actions: const [LanguageButton(), ThemeButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: FixMateLogo(size: 90)),
            const SizedBox(height: 20),
            Text(
              t('Enter your email and we will send you a code.'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              readOnly: codeSent,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: t('Email'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            if (!codeSent)
              ElevatedButton(
                onPressed: busy ? null : sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FixMateTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t('SEND CODE')),
              )
            else ...[
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t('Code from your email'),
                  prefixIcon: const Icon(Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t('New password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t('Confirm password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: busy ? null : resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FixMateTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t('RESET PASSWORD')),
              ),
              TextButton(
                onPressed: busy ? null : sendCode,
                child: Text(t('Resend code')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
