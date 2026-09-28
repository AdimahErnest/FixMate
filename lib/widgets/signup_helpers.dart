// FixMate — shared building blocks for the 3 signup pages

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import 'common.dart';

class SignupScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SignupScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class SignupHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SignupHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FixMateLogo(size: 80),

        const SizedBox(height: 15),

        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        Text(
          subtitle,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 25),
      ],
    );
  }
}

class SignupField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const SignupField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;

  const PasswordField({
    super.key,
    required this.label,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              const Icon(Icons.lock_outline),
        ),
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final String label;

  const DropdownField({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: 'Option',
        decoration: InputDecoration(
          labelText: label,
        ),
        items: [
          DropdownMenuItem(
            value: 'Option',
            child: Text(t('Select')),
          ),
        ],
        onChanged: (_) {},
      ),
    );
  }
}

class SignupButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SignupButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: FixMateTheme.gold,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
