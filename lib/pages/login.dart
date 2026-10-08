// FixMate — login page
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';
import 'role_selection.dart';
import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

 Future<void> realLogin() async {
  final state = context.read<AppState>();
  final t = state.tr;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final identifier = identifierController.text.trim();
  final password = passwordController.text;

  if (identifier.isEmpty || password.isEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(t('Please enter your email or phone number and password.'))),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final success = await state.signInSupabase(identifier, password);
  if (!mounted) return;
  navigator.pop(); // close loader

  if (success) {
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  } else {
    messenger.showSnackBar(SnackBar(content: Text(t(state.authError))));
  }
}

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: const [LanguageButton(), ThemeButton()]),
              const SizedBox(height: 20),
              const FixMateLogo(size: 170),
              const SizedBox(height: 25),
              Text(t('Welcome to FixMate'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(t('Your trusted technician marketplace'), textAlign: TextAlign.center),
              const SizedBox(height: 35),
              TextField(
                controller: identifierController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: t('Email or phone number'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: t('Password'), prefixIcon: const Icon(Icons.lock_outline))),
              Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(
          initialEmail: identifierController.text.trim().contains('@')
              ? identifierController.text.trim()
              : '',
        ),
      ),
    ),
    child: Text(t('Forgot password?')),
  ),
),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: realLogin, style: ElevatedButton.styleFrom(backgroundColor: FixMateTheme.gold, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(t('LOG IN')))),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t("Don't have an account?")), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupRoleSelectionPage())), child: Text(t('Sign up')))]),
            ],
          ),
        ),
      ),
    );
  }
}
