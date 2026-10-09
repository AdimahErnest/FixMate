// FixMate — Forgot-password email-code flow
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool showPassword = false;
  bool showConfirmation = false;
  int resendSeconds = 0;
  Timer? resendTimer;

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
    resendTimer?.cancel();
    super.dispose();
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void startResendCooldown() {
    resendTimer?.cancel();
    setState(() => resendSeconds = 60);
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  void changeEmail() {
    resendTimer?.cancel();
    setState(() {
      codeSent = false;
      resendSeconds = 0;
      codeController.clear();
      passwordController.clear();
      confirmController.clear();
    });
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
      if (ok) {
        codeSent = true;
        codeController.clear();
      }
    });
    if (ok) startResendCooldown();
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

    if (!isValidRecoveryCode(code)) {
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
            const SizedBox(height: 8),
            Text(
              t('Use the newest code sent to your inbox. Check spam if it is missing.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              readOnly: codeSent,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
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
                  backgroundColor: FixMateTheme.buttonGold,
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
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t('Code from your email'),
                  prefixIcon: const Icon(Icons.pin_outlined),
                  helperText: t('Enter the 6 to 8 digit code from the latest email.'),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t('New password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: t('Use at least 8 characters with uppercase, lowercase, and a number.'),
                  suffixIcon: IconButton(
                    tooltip: t(showPassword ? 'Hide password' : 'Show password'),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmController,
                obscureText: !showConfirmation,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: t('Confirm password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: t(
                      showConfirmation ? 'Hide password' : 'Show password',
                    ),
                    onPressed: () => setState(
                      () => showConfirmation = !showConfirmation,
                    ),
                    icon: Icon(
                      showConfirmation
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: busy ? null : resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FixMateTheme.buttonGold,
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
                onPressed: busy || resendSeconds > 0 ? null : sendCode,
                child: Text(
                  resendSeconds > 0
                      ? '${t('Resend code')} (${resendSeconds}s)'
                      : t('Resend code'),
                ),
              ),
              TextButton(
                onPressed: busy ? null : changeEmail,
                child: Text(t('Use a different email')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
