// FixMate — shared building blocks for the 3 signup pages

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';
import 'common.dart';

enum SignupVerificationMethod { email, whatsapp }

bool isValidSignupEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

String? validateSignupFields({
  required String name,
  required String email,
  required String phone,
  required String password,
  required String confirmPassword,
  String? additionalPhone,
}) {
  if (name.trim().isEmpty) return 'Please enter your name.';
  if (!isValidSignupEmail(email)) {
    return 'Please enter a valid email address.';
  }
  if (normalizeSignupPhone(phone) == null) {
    return 'Enter a valid Cameroon phone number.';
  }
  if (additionalPhone != null &&
      additionalPhone.trim().isNotEmpty &&
      normalizeSignupPhone(additionalPhone) == null) {
    return 'Enter a valid additional phone number.';
  }
  if (!isStrongSignupPassword(password)) {
    return 'Use at least 8 characters with uppercase, lowercase, and a number.';
  }
  if (password != confirmPassword) return 'Passwords do not match.';
  return null;
}

bool isStrongSignupPassword(String password) =>
    password.length >= 8 &&
    RegExp(r'[A-Z]').hasMatch(password) &&
    RegExp(r'[a-z]').hasMatch(password) &&
    RegExp(r'[0-9]').hasMatch(password);

String? validateSignupLocation({
  required String? region,
  required String? town,
}) {
  if (region == null || !cameroonRegions.containsKey(region)) {
    return 'Please select your region.';
  }
  if (town == null || !cameroonRegions[region]!.contains(town)) {
    return 'Please select a town in your region.';
  }
  return null;
}

bool isValidRecoveryCode(String code) => RegExp(r'^\d{6,8}$').hasMatch(code);

bool isValidSignupCode(String code) => RegExp(r'^\d{6}$').hasMatch(code);

String? normalizeSignupPhone(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('237') && digits.length == 12) {
    digits = digits.substring(3);
  } else if (digits.startsWith('0') && digits.length == 10) {
    digits = digits.substring(1);
  }
  return RegExp(r'^[26]\d{8}$').hasMatch(digits) ? digits : null;
}

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
        actions: const [LanguageButton(), ThemeButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }
}

class SignupHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SignupHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FixMateLogo(size: 80),

        const SizedBox(height: 15),

        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text(subtitle, textAlign: TextAlign.center),

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
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;

  const PasswordField({super.key, required this.label, this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          helperText: t(
            'At least 8 characters, with uppercase, lowercase, and a number.',
          ),
        ),
      ),
    );
  }
}

class SignupVerificationSelector extends StatelessWidget {
  final SignupVerificationMethod value;
  final ValueChanged<SignupVerificationMethod> onChanged;

  const SignupVerificationSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            t('Verify account with'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        RadioGroup<SignupVerificationMethod>(
          groupValue: value,
          onChanged: (selection) {
            if (selection != null) onChanged(selection);
          },
          child: Column(
            children: [
              RadioListTile<SignupVerificationMethod>(
                contentPadding: EdgeInsets.zero,
                title: Text(t('Email code')),
                value: SignupVerificationMethod.email,
              ),
              RadioListTile<SignupVerificationMethod>(
                contentPadding: EdgeInsets.zero,
                title: Text(t('WhatsApp code')),
                value: SignupVerificationMethod.whatsapp,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SignupLocationFields extends StatelessWidget {
  final String? region;
  final String? town;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onTownChanged;

  const SignupLocationFields({
    super.key,
    required this.region,
    required this.town,
    required this.onRegionChanged,
    required this.onTownChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    final towns = region == null ? const <String>[] : cameroonRegions[region]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            t('Your location'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            t('Select a region first, then choose your town.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            initialValue: region,
            decoration: InputDecoration(
              labelText: t('Region'),
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            items: cameroonRegions.keys
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(t(value))),
                )
                .toList(),
            onChanged: onRegionChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            initialValue: towns.contains(town) ? town : null,
            decoration: InputDecoration(
              labelText: t('Town'),
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            items: towns
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: region == null ? null : onTownChanged,
          ),
        ),
      ],
    );
  }
}

class SignupButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const SignupButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: FixMateTheme.buttonGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(text),
      ),
    );
  }
}
