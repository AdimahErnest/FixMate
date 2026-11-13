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
    return 'Use at least 8 characters.';
  }
  if (password != confirmPassword) return 'Passwords do not match.';
  return null;
}

String? validateSignupContact({
  required String name,
  required String email,
  required String phone,
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
  return null;
}

String? validateSignupPassword({
  required String password,
  required String confirmPassword,
}) {
  if (!isStrongSignupPassword(password)) {
    return 'Use at least 8 characters.';
  }
  if (password != confirmPassword) {
    return 'Passwords do not match.';
  }
  return null;
}

bool isStrongSignupPassword(String password) {
  return password.length >= 8;
}

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

class SignupFlowScaffold extends StatelessWidget {
  final String title;
  final int step;
  final List<String> steps;
  final List<Widget> children;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final VoidCallback? onSubmit;
  final bool submitting;
  final String? submitError;
  final String submitLabel;

  const SignupFlowScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.steps,
    required this.children,
    this.onBack,
    this.onContinue,
    this.onSubmit,
    this.submitting = false,
    this.submitError,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    final isLastStep = step == steps.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: step == 0 ? null : BackButton(onPressed: onBack),
        actions: const [LanguageButton(), ThemeButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('Step {step} of {count}: {title}')
                        .replaceAll('{step}', '${step + 1}')
                        .replaceAll('{count}', '${steps.length}')
                        .replaceAll('{title}', t(steps[step])),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: (step + 1) / steps.length),
                ],
              ),
            ),
            Expanded(
              child: IgnorePointer(
                ignoring: submitting,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
            if (submitError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    t(submitError!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: submitting ? null : onBack,
                        child: Text(t('Back')),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : (isLastStep ? onSubmit : onContinue),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FixMateTheme.buttonGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isLastStep ? t(submitLabel) : t('Continue')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  final String? errorText;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const SignupField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText == null
              ? null
              : context.read<AppState>().tr(errorText!),
        ),
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const PasswordField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    return _PasswordFieldInput(
      label: label,
      controller: controller,
      helperText: t('At least 8 characters.'),
      errorText: errorText == null ? null : t(errorText!),
      onChanged: onChanged,
    );
  }
}

class _PasswordFieldInput extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _PasswordFieldInput({
    required this.label,
    required this.controller,
    required this.helperText,
    required this.errorText,
    required this.onChanged,
  });

  @override
  State<_PasswordFieldInput> createState() => _PasswordFieldInputState();
}

class _PasswordFieldInputState extends State<_PasswordFieldInput> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: widget.controller,
      obscureText: obscure,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        helperText: widget.helperText,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: obscure ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => obscure = !obscure),
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    ),
  );
}

class SignupSearchableChoiceChips extends StatefulWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onChanged;
  final String searchLabel;
  final String emptyLabel;
  final String selectionHint;

  const SignupSearchableChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.searchLabel,
    required this.emptyLabel,
    required this.selectionHint,
  });

  @override
  State<SignupSearchableChoiceChips> createState() =>
      _SignupSearchableChoiceChipsState();
}

class _SignupSearchableChoiceChipsState
    extends State<SignupSearchableChoiceChips> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    final visible = widget.options
        .where(
          (option) => t(option).toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (value) => setState(() => query = value.trim()),
          decoration: InputDecoration(
            labelText: t(widget.searchLabel),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        Text(t(widget.selectionHint)),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          Text(t(widget.emptyLabel))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visible.map((option) {
              final selected = widget.selected.contains(option);
              return FilterChip(
                label: Text(t(option)),
                selected: selected,
                onSelected: (_) => widget.onChanged(option),
                selectedColor: FixMateTheme.gold.withValues(alpha: .25),
              );
            }).toList(),
          ),
      ],
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
  final String? regionError;
  final String? townError;

  const SignupLocationFields({
    super.key,
    required this.region,
    required this.town,
    required this.onRegionChanged,
    required this.onTownChanged,
    this.regionError,
    this.townError,
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
              errorText: regionError == null ? null : t(regionError!),
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
              errorText: townError == null ? null : t(townError!),
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
