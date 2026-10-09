// FixMate — Customer, Technician and Supplier signup pages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/signup_helpers.dart';
import 'navigation.dart';

class CustomerSignupPage extends StatefulWidget {
  const CustomerSignupPage({super.key});

  @override
  State<CustomerSignupPage> createState() => _CustomerSignupPageState();
}

class _CustomerSignupPageState extends State<CustomerSignupPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  String? selectedRegion;
  String? selectedTown;
  SignupVerificationMethod verificationMethod = SignupVerificationMethod.email;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final validation = validateSignupFields(
      name: '${firstName.text.trim()} ${lastName.text.trim()}',
      email: email.text,
      phone: phone.text,
      password: password.text,
      confirmPassword: confirmPassword.text,
    );
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(validation))));
      return;
    }
    final locationValidation = validateSignupLocation(
      region: selectedRegion,
      town: selectedTown,
    );
    if (locationValidation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(locationValidation))));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await state.beginSignupVerification(
      email: email.text.trim().toLowerCase(),
      password: password.text,
      role: 'Customer',
      verificationMethod: verificationMethod.name,
      fullName: '${firstName.text.trim()} ${lastName.text.trim()}',
      phone: normalizeSignupPhone(phone.text)!,
      region: selectedRegion,
      town: selectedTown,
    );

    if (mounted) Navigator.pop(context); // Close loader

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignupVerificationPage(
            destination: verificationMethod == SignupVerificationMethod.email
                ? email.text.trim()
                : phone.text.trim(),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(state.authError))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return SignupScaffold(
      title: t('Customer Registration'),
      children: [
        SignupHeader(
          title: t('Create customer account'),
          subtitle: t('Find trusted technicians and buy products on FixMate.'),
        ),

        SignupField(label: t('First name'), controller: firstName),

        SignupField(label: t('Last name'), controller: lastName),

        SignupField(
          label: t('Phone number'),
          controller: phone,
          keyboardType: TextInputType.phone,
        ),

        SignupField(
          label: t('Email'),
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),

        SignupVerificationSelector(
          value: verificationMethod,
          onChanged: (value) => setState(() => verificationMethod = value),
        ),

        SignupLocationFields(
          region: selectedRegion,
          town: selectedTown,
          onRegionChanged: (value) => setState(() {
            selectedRegion = value;
            selectedTown = null;
          }),
          onTownChanged: (value) => setState(() => selectedTown = value),
        ),

        PasswordField(label: t('Password'), controller: password),

        PasswordField(
          label: t('Confirm password'),
          controller: confirmPassword,
        ),

        const SizedBox(height: 10),

        SignupButton(text: t('CREATE CUSTOMER ACCOUNT'), onPressed: register),
      ],
    );
  }
}

class TechnicianSignupPage extends StatefulWidget {
  const TechnicianSignupPage({super.key});

  @override
  State<TechnicianSignupPage> createState() => _TechnicianSignupPageState();
}

class _TechnicianSignupPageState extends State<TechnicianSignupPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final Set<String> selectedServices = {};
  String? selectedRegion;
  String? selectedTown;
  SignupVerificationMethod verificationMethod = SignupVerificationMethod.email;

  final List<String> services = [
    'Electricity',
    'Plumbing',
    'Refrigeration & Air Conditioning',
    'Phone Repairs',
    'Carpentry',
    'Painting',
    'Welding',
    'Masonry',
    'Tiling',
    'Fenestration',
    'Auto Repair',
    'Home Appliance Repair',
    'Computer & IT Tools Repair',
    'Audio Repair',
    'Electronics Repair',
    'Solar Maintenance & Repair',
  ];

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final state = context.read<AppState>();
    final t = state.tr;

    final validation = validateSignupFields(
      name: '${firstName.text.trim()} ${lastName.text.trim()}',
      email: email.text,
      phone: phone.text,
      password: password.text,
      confirmPassword: confirmPassword.text,
    );
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(validation))));
      return;
    }
    final locationValidation = validateSignupLocation(
      region: selectedRegion,
      town: selectedTown,
    );
    if (locationValidation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(locationValidation))));
      return;
    }
    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Please select at least one service.'))),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await state.beginSignupVerification(
      email: email.text.trim().toLowerCase(),
      password: password.text,
      role: 'Technician',
      verificationMethod: verificationMethod.name,
      fullName: '${firstName.text.trim()} ${lastName.text.trim()}',
      phone: normalizeSignupPhone(phone.text)!,
      region: selectedRegion,
      town: selectedTown,
      services: selectedServices.toList(),
    );

    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignupVerificationPage(
            destination: verificationMethod == SignupVerificationMethod.email
                ? email.text.trim()
                : phone.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(state.authError))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return SignupScaffold(
      title: t('Technician Registration'),
      children: [
        SignupHeader(
          title: t('Create technician account'),
          subtitle: t('Offer your professional services to customers.'),
        ),
        SignupField(label: t('First name'), controller: firstName),
        SignupField(label: t('Last name'), controller: lastName),
        SignupField(
          label: t('Phone number'),
          controller: phone,
          keyboardType: TextInputType.phone,
        ),
        SignupField(
          label: t('Email'),
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),
        SignupVerificationSelector(
          value: verificationMethod,
          onChanged: (value) => setState(() => verificationMethod = value),
        ),
        SignupLocationFields(
          region: selectedRegion,
          town: selectedTown,
          onRegionChanged: (value) => setState(() {
            selectedRegion = value;
            selectedTown = null;
          }),
          onTownChanged: (value) => setState(() => selectedTown = value),
        ),
        PasswordField(label: t('Password'), controller: password),
        PasswordField(
          label: t('Confirm password'),
          controller: confirmPassword,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t('Services you provide'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: services.map((service) {
            final selected = selectedServices.contains(service);
            return FilterChip(
              label: Text(t(service)),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selectedServices.add(service);
                  } else {
                    selectedServices.remove(service);
                  }
                });
              },
              selectedColor: FixMateTheme.gold.withValues(alpha: .25),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SignupButton(text: t('CREATE TECHNICIAN ACCOUNT'), onPressed: register),
      ],
    );
  }
}

class SupplierSignupPage extends StatefulWidget {
  const SupplierSignupPage({super.key});

  @override
  State<SupplierSignupPage> createState() => _SupplierSignupPageState();
}

class _SupplierSignupPageState extends State<SupplierSignupPage> {
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final company = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final additionalPhone = TextEditingController();
  final Set<String> selectedItems = {};
  String? selectedRegion;
  String? selectedTown;
  SignupVerificationMethod verificationMethod = SignupVerificationMethod.email;

  final List<String> categories = [
    'Electrical Materials',
    'Plumbing Materials',
    'Refrigeration Equipment',
    'Air Conditioning Equipment',
    'Phone Parts',
    'Carpentry Materials',
    'Paint',
    'Welding Equipment',
    'Masonry Materials',
    'Tiles',
    'Windows & Doors',
    'Auto Parts',
    'Home Appliances',
    'Computers',
    'IT Equipment',
    'Audio Equipment',
    'Electronic Components',
    'Solar Equipment',
    'Tools',
    'Safety Equipment',
    'Other',
  ];

  @override
  void dispose() {
    password.dispose();
    confirmPassword.dispose();
    company.dispose();
    email.dispose();
    phone.dispose();
    additionalPhone.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final validation = validateSignupFields(
      name: company.text,
      email: email.text,
      phone: phone.text,
      password: password.text,
      confirmPassword: confirmPassword.text,
      additionalPhone: additionalPhone.text,
    );
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(validation))));
      return;
    }
    final locationValidation = validateSignupLocation(
      region: selectedRegion,
      town: selectedTown,
    );
    if (locationValidation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(locationValidation))));
      return;
    }
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('Please select at least one supply category.')),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await state.beginSignupVerification(
      email: email.text.trim().toLowerCase(),
      password: password.text,
      role: 'Supplier',
      verificationMethod: verificationMethod.name,
      fullName: company.text.trim().isEmpty
          ? 'FixMate Supplier'
          : company.text.trim(),
      phone: normalizeSignupPhone(phone.text)!,
      region: selectedRegion,
      town: selectedTown,
      categories: selectedItems.toList(),
      additionalPhone: additionalPhone.text.trim().isEmpty
          ? null
          : normalizeSignupPhone(additionalPhone.text),
    );

    if (mounted) Navigator.pop(context);
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignupVerificationPage(
            destination: verificationMethod == SignupVerificationMethod.email
                ? email.text.trim()
                : phone.text.trim(),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(state.authError))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return SignupScaffold(
      title: t('Supplier Registration'),
      children: [
        SignupHeader(
          title: t('Create supplier account'),
          subtitle: t('Sell tools, equipment, spare parts and materials.'),
        ),

        SignupField(label: t('Company name'), controller: company),

        SignupField(
          label: t('Email'),
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),

        SignupField(
          label: t('Phone number'),
          controller: phone,
          keyboardType: TextInputType.phone,
        ),

        SignupField(
          label: t('Additional phone number'),
          controller: additionalPhone,
          keyboardType: TextInputType.phone,
        ),

        SignupVerificationSelector(
          value: verificationMethod,
          onChanged: (value) => setState(() => verificationMethod = value),
        ),

        SignupLocationFields(
          region: selectedRegion,
          town: selectedTown,
          onRegionChanged: (value) => setState(() {
            selectedRegion = value;
            selectedTown = null;
          }),
          onTownChanged: (value) => setState(() => selectedTown = value),
        ),

        const SizedBox(height: 10),
        PasswordField(label: t('Password'), controller: password),
        PasswordField(
          label: t('Confirm password'),
          controller: confirmPassword,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t('Items you supply'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((item) {
            final selected = selectedItems.contains(item);

            return FilterChip(
              label: Text(t(item)),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selectedItems.add(item);
                  } else {
                    selectedItems.remove(item);
                  }
                });
              },
              selectedColor: FixMateTheme.gold.withValues(alpha: .25),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        const SizedBox(height: 5),

        Text(
          t(
            'Business verification documents can be submitted after registration.',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),

        const SizedBox(height: 20),

        SignupButton(text: t('CREATE SUPPLIER ACCOUNT'), onPressed: register),
      ],
    );
  }
}

class SignupVerificationPage extends StatefulWidget {
  final String destination;

  const SignupVerificationPage({super.key, required this.destination});

  @override
  State<SignupVerificationPage> createState() => _SignupVerificationPageState();
}

class _SignupVerificationPageState extends State<SignupVerificationPage> {
  final codeController = TextEditingController();
  bool verifying = false;
  bool resending = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> verify() async {
    final state = context.read<AppState>();
    final t = state.tr;
    if (!isValidSignupCode(codeController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Enter the 6-digit verification code.'))),
      );
      return;
    }
    setState(() => verifying = true);
    final success = await state.verifySignupCode(codeController.text.trim());
    if (!mounted) return;
    setState(() => verifying = false);
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(state.authError))));
    }
  }

  Future<void> resend() async {
    final state = context.read<AppState>();
    final success = await state.resendSignupCode();
    if (!mounted) return;
    setState(() => resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? state.tr('A new verification code has been sent.')
              : state.tr(state.authError),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    return SignupScaffold(
      title: t('Verify your account'),
      children: [
        SignupHeader(
          title: t('Enter your verification code'),
          subtitle: t('We sent a six-digit code to'),
        ),
        Text(
          widget.destination,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          t('If you do not receive it, check the address or number and try again.'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: t('6-digit verification code'),
            prefixIcon: const Icon(Icons.verified_user_outlined),
          ),
        ),
        const SizedBox(height: 16),
        SignupButton(
          text: t('VERIFY AND CREATE ACCOUNT'),
          onPressed: verifying ? null : verify,
        ),
        TextButton(
          onPressed: resending
              ? null
              : () {
                  setState(() => resending = true);
                  resend();
                },
          child: Text(t('Resend code')),
        ),
      ],
    );
  }
}
