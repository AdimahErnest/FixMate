// FixMate — Customer, Technician and Supplier signup pages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/signup_helpers.dart';
import 'navigation.dart';
import 'business_verification.dart';

const _customerSignupSteps = [
  'Contact details',
  'Location',
  'Secure your account',
];
const _technicianSignupSteps = [
  'Contact details',
  'Services and location',
  'Secure your account',
];
const _supplierSignupSteps = [
  'Company details',
  'Products and location',
  'Secure your account',
];

Map<String, String> _contactErrors({
  required String name,
  required String email,
  required String phone,
  String? additionalPhone,
}) {
  final errors = <String, String>{};
  if (name.trim().isEmpty) errors['name'] = 'Please enter your name.';
  if (!isValidSignupEmail(email)) {
    errors['email'] = 'Please enter a valid email address.';
  }
  if (normalizeSignupPhone(phone) == null) {
    errors['phone'] = 'Enter a valid Cameroon phone number.';
  }
  if (additionalPhone != null &&
      additionalPhone.trim().isNotEmpty &&
      normalizeSignupPhone(additionalPhone) == null) {
    errors['additionalPhone'] = 'Enter a valid additional phone number.';
  }
  return errors;
}

Map<String, String> _passwordErrors(String password, String confirmPassword) {
  final errors = <String, String>{};
  if (!isStrongSignupPassword(password)) {
    errors['password'] = 'Use at least 8 characters.';
  } else if (password != confirmPassword) {
    errors['confirmPassword'] = 'Passwords do not match.';
  }
  return errors;
}

Widget _signupReviewRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 100,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      Expanded(child: Text(value)),
    ],
  ),
);

Widget _documentPrivacyConsent({
  required bool value,
  required ValueChanged<bool?> onChanged,
}) => CheckboxListTile(
  contentPadding: EdgeInsets.zero,
  value: value,
  controlAffinity: ListTileControlAffinity.leading,
  onChanged: onChanged,
  title: const Text('I understand how my verification documents are handled.'),
  subtitle: const Text(
    'Only authorized FixMate admins can review identity, criminal-record, registration, and tax documents. They are private, used only for verification, and are not shown on your public profile.',
  ),
);

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
  int step = 0;
  bool submitting = false;
  String? submitError;
  Map<String, String> errors = {};

  void continueStep() {
    final nextErrors = step == 0
        ? _contactErrors(
            name: '${firstName.text} ${lastName.text}',
            email: email.text,
            phone: phone.text,
          )
        : validateSignupLocation(region: selectedRegion, town: selectedTown) ==
              null
        ? <String, String>{}
        : <String, String>{
            validateSignupLocation(
              region: selectedRegion,
              town: selectedTown,
            )!.contains('region')
                ? 'region'
                : 'town': validateSignupLocation(
                  region: selectedRegion,
                  town: selectedTown,
                )!,
          };
    setState(() {
      errors = nextErrors;
      if (errors.isEmpty && step < 2) step++;
    });
  }

  void backStep() => setState(() {
    if (step > 0) step--;
    errors = {};
    submitError = null;
  });

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
    if (submitting) return;
    final passwordValidation = _passwordErrors(
      password.text,
      confirmPassword.text,
    );
    if (passwordValidation.isNotEmpty) {
      setState(() => errors = passwordValidation);
      return;
    }
    setState(() {
      submitting = true;
      submitError = null;
    });
    var success = false;
    try {
      success = await state.beginSignupVerification(
        email: email.text.trim().toLowerCase(),
        password: password.text,
        role: 'Customer',
        verificationMethod: verificationMethod.name,
        fullName: '${firstName.text.trim()} ${lastName.text.trim()}',
        phone: normalizeSignupPhone(phone.text)!,
        region: selectedRegion,
        town: selectedTown,
      );
      if (!success && mounted) setState(() => submitError = state.authError);
    } catch (error) {
      if (mounted) setState(() => submitError = error.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return SignupFlowScaffold(
      title: t('Customer Registration'),
      step: step,
      steps: _customerSignupSteps,
      onBack: backStep,
      onContinue: continueStep,
      onSubmit: register,
      submitting: submitting,
      submitError: submitError,
      submitLabel: 'CREATE CUSTOMER ACCOUNT',
      children: switch (step) {
        0 => [
          SignupHeader(
            title: t('Create customer account'),
            subtitle: t('Find trusted technicians and buy products on FixMate.'),
          ),
          SignupField(
            label: t('First name'),
            controller: firstName,
            errorText: errors['name'],
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => errors.remove('name')),
          ),
          SignupField(
            label: t('Last name'),
            controller: lastName,
            errorText: errors['name'],
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => errors.remove('name')),
          ),
          SignupField(
            label: t('Phone number'),
            controller: phone,
            keyboardType: TextInputType.phone,
            errorText: errors['phone'],
            onChanged: (_) => setState(() => errors.remove('phone')),
          ),
          SignupField(
            label: t('Email'),
            controller: email,
            keyboardType: TextInputType.emailAddress,
            errorText: errors['email'],
            onChanged: (_) => setState(() => errors.remove('email')),
          ),
          SignupVerificationSelector(
            value: verificationMethod,
            onChanged: (value) => setState(() => verificationMethod = value),
          ),
        ],
        1 => [
          SignupHeader(
            title: t('Where can customers find you?'),
            subtitle: t('Your location helps us show nearby services.'),
          ),
          SignupLocationFields(
            region: selectedRegion,
            town: selectedTown,
            regionError: errors['region'],
            townError: errors['town'],
            onRegionChanged: (value) => setState(() {
              selectedRegion = value;
              selectedTown = null;
              errors.remove('region');
              errors.remove('town');
            }),
            onTownChanged: (value) => setState(() {
              selectedTown = value;
              errors.remove('town');
            }),
          ),
        ],
        _ => [
          SignupHeader(
            title: t('Secure your account'),
            subtitle: t('Choose a password with at least 8 characters.'),
          ),
          PasswordField(
            label: t('Password'),
            controller: password,
            errorText: errors['password'],
            onChanged: (_) => setState(() => errors.remove('password')),
          ),
          PasswordField(
            label: t('Confirm password'),
            controller: confirmPassword,
            errorText: errors['confirmPassword'],
            onChanged: (_) => setState(() => errors.remove('confirmPassword')),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t('Review your details')),
                  _signupReviewRow(t('Name'), '${firstName.text} ${lastName.text}'),
                  _signupReviewRow(t('Email'), email.text),
                  _signupReviewRow(t('Phone'), phone.text),
                  _signupReviewRow(
                    t('Location'),
                    '${selectedTown ?? ''}, ${selectedRegion ?? ''}',
                  ),
                ],
              ),
            ),
          ),
        ],
      },
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
  int step = 0;
  bool submitting = false;
  bool documentPrivacyConsent = false;
  String? submitError;
  Map<String, String> errors = {};

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

  void continueStep() {
    final nextErrors = <String, String>{};
    if (step == 0) {
      nextErrors.addAll(
        _contactErrors(
          name: '${firstName.text} ${lastName.text}',
          email: email.text,
          phone: phone.text,
        ),
      );
    } else if (validateSignupLocation(
          region: selectedRegion,
          town: selectedTown,
        ) !=
        null) {
      final message = validateSignupLocation(
        region: selectedRegion,
        town: selectedTown,
      )!;
      nextErrors[message.contains('region') ? 'region' : 'town'] = message;
    } else if (selectedServices.isEmpty) {
      nextErrors['services'] = 'Please select at least one service.';
    }
    if (step == 1 && !documentPrivacyConsent) {
      nextErrors['privacy'] =
          'Please acknowledge how verification documents are handled.';
    }
    setState(() {
      errors = nextErrors;
      if (errors.isEmpty && step < 2) step++;
    });
  }

  void backStep() => setState(() {
    if (step > 0) step--;
    errors = {};
    submitError = null;
  });

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
    if (submitting) return;
    final passwordValidation = _passwordErrors(
      password.text,
      confirmPassword.text,
    );
    if (passwordValidation.isNotEmpty) {
      setState(() => errors = passwordValidation);
      return;
    }
    setState(() {
      submitting = true;
      submitError = null;
    });
    var success = false;
    try {
      success = await state.beginSignupVerification(
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
      if (!success && mounted) setState(() => submitError = state.authError);
    } catch (error) {
      if (mounted) setState(() => submitError = error.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return SignupFlowScaffold(
      title: t('Technician Registration'),
      step: step,
      steps: _technicianSignupSteps,
      onBack: backStep,
      onContinue: continueStep,
      onSubmit: register,
      submitting: submitting,
      submitError: submitError,
      submitLabel: 'CREATE TECHNICIAN ACCOUNT',
      children: switch (step) {
        0 => [
          SignupHeader(
            title: t('Create technician account'),
            subtitle: t('Offer your professional services to customers.'),
          ),
          SignupField(
            label: t('First name'),
            controller: firstName,
            errorText: errors['name'],
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => errors.remove('name')),
          ),
          SignupField(
            label: t('Last name'),
            controller: lastName,
            errorText: errors['name'],
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => errors.remove('name')),
          ),
          SignupField(
            label: t('Phone number'),
            controller: phone,
            keyboardType: TextInputType.phone,
            errorText: errors['phone'],
            onChanged: (_) => setState(() => errors.remove('phone')),
          ),
          SignupField(
            label: t('Email'),
            controller: email,
            keyboardType: TextInputType.emailAddress,
            errorText: errors['email'],
            onChanged: (_) => setState(() => errors.remove('email')),
          ),
          SignupVerificationSelector(
            value: verificationMethod,
            onChanged: (value) => setState(() => verificationMethod = value),
          ),
        ],
        1 => [
          SignupHeader(
            title: t('Choose your services and location'),
            subtitle: t('Customers will find you by skill and town.'),
          ),
          SignupLocationFields(
            region: selectedRegion,
            town: selectedTown,
            regionError: errors['region'],
            townError: errors['town'],
            onRegionChanged: (value) => setState(() {
              selectedRegion = value;
              selectedTown = null;
              errors.remove('region');
              errors.remove('town');
            }),
            onTownChanged: (value) => setState(() {
              selectedTown = value;
              errors.remove('town');
            }),
          ),
          Text(
            t('Services you provide'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SignupSearchableChoiceChips(
            options: services,
            selected: selectedServices,
            searchLabel: 'Search services',
            emptyLabel: 'No services match your search.',
            selectionHint: 'Select every service for which you work.',
            onChanged: (service) => setState(() {
              if (!selectedServices.add(service)) {
                selectedServices.remove(service);
              }
              errors.remove('services');
            }),
          ),
          if (errors['services'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t(errors['services']!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (selectedServices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t('A separate certificate or license is required for every selected service.'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          _documentPrivacyConsent(
            value: documentPrivacyConsent,
            onChanged: (value) => setState(() {
              documentPrivacyConsent = value ?? false;
              errors.remove('privacy');
            }),
          ),
          if (errors['privacy'] != null)
            Text(
              t(errors['privacy']!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
        _ => [
          SignupHeader(
            title: t('Secure your account'),
            subtitle: t('Choose a password with at least 8 characters.'),
          ),
          PasswordField(
            label: t('Password'),
            controller: password,
            errorText: errors['password'],
            onChanged: (_) => setState(() => errors.remove('password')),
          ),
          PasswordField(
            label: t('Confirm password'),
            controller: confirmPassword,
            errorText: errors['confirmPassword'],
            onChanged: (_) => setState(() => errors.remove('confirmPassword')),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t('Review your details')),
                  _signupReviewRow(t('Name'), '${firstName.text} ${lastName.text}'),
                  _signupReviewRow(t('Email'), email.text),
                  _signupReviewRow(t('Phone'), phone.text),
                  _signupReviewRow(t('Services'), selectedServices.map(t).join(', ')),
                  _signupReviewRow(
                    t('Location'),
                    '${selectedTown ?? ''}, ${selectedRegion ?? ''}',
                  ),
                ],
              ),
            ),
          ),
        ],
      },
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
  int step = 0;
  bool submitting = false;
  bool documentPrivacyConsent = false;
  String? submitError;
  Map<String, String> errors = {};

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

  void continueStep() {
    final nextErrors = <String, String>{};
    if (step == 0) {
      nextErrors.addAll(
        _contactErrors(
          name: company.text,
          email: email.text,
          phone: phone.text,
          additionalPhone: additionalPhone.text,
        ),
      );
    } else if (validateSignupLocation(
          region: selectedRegion,
          town: selectedTown,
        ) !=
        null) {
      final message = validateSignupLocation(
        region: selectedRegion,
        town: selectedTown,
      )!;
      nextErrors[message.contains('region') ? 'region' : 'town'] = message;
    } else if (selectedItems.isEmpty) {
      nextErrors['categories'] = 'Please select at least one supply category.';
    }
    if (step == 1 && !documentPrivacyConsent) {
      nextErrors['privacy'] =
          'Please acknowledge how verification documents are handled.';
    }
    setState(() {
      errors = nextErrors;
      if (errors.isEmpty && step < 2) step++;
    });
  }

  void backStep() => setState(() {
    if (step > 0) step--;
    errors = {};
    submitError = null;
  });

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
    if (submitting) return;
    final passwordValidation = _passwordErrors(
      password.text,
      confirmPassword.text,
    );
    if (passwordValidation.isNotEmpty) {
      setState(() => errors = passwordValidation);
      return;
    }
    setState(() {
      submitting = true;
      submitError = null;
    });
    var success = false;
    try {
      success = await state.beginSignupVerification(
        email: email.text.trim().toLowerCase(),
        password: password.text,
        role: 'Supplier',
        verificationMethod: verificationMethod.name,
        fullName: company.text.trim(),
        phone: normalizeSignupPhone(phone.text)!,
        region: selectedRegion,
        town: selectedTown,
        categories: selectedItems.toList(),
        additionalPhone: additionalPhone.text.trim().isEmpty
            ? null
            : normalizeSignupPhone(additionalPhone.text),
      );
      if (!success && mounted) setState(() => submitError = state.authError);
    } catch (error) {
      if (mounted) setState(() => submitError = error.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return SignupFlowScaffold(
      title: t('Supplier Registration'),
      step: step,
      steps: _supplierSignupSteps,
      onBack: backStep,
      onContinue: continueStep,
      onSubmit: register,
      submitting: submitting,
      submitError: submitError,
      submitLabel: 'CREATE SUPPLIER ACCOUNT',
      children: switch (step) {
        0 => [
          SignupHeader(
            title: t('Create supplier account'),
            subtitle: t('Sell tools, equipment, spare parts and materials.'),
          ),
          SignupField(
            label: t('Company name'),
            controller: company,
            errorText: errors['name'],
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => errors.remove('name')),
          ),
          SignupField(
            label: t('Email'),
            controller: email,
            keyboardType: TextInputType.emailAddress,
            errorText: errors['email'],
            onChanged: (_) => setState(() => errors.remove('email')),
          ),
          SignupField(
            label: t('Phone number'),
            controller: phone,
            keyboardType: TextInputType.phone,
            errorText: errors['phone'],
            onChanged: (_) => setState(() => errors.remove('phone')),
          ),
          SignupField(
            label: t('Additional phone number'),
            controller: additionalPhone,
            keyboardType: TextInputType.phone,
            errorText: errors['additionalPhone'],
            onChanged: (_) => setState(() => errors.remove('additionalPhone')),
          ),
          SignupVerificationSelector(
            value: verificationMethod,
            onChanged: (value) => setState(() => verificationMethod = value),
          ),
          Text(
            t('Company documents are required after signup and admin review may take up to 24 hours.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        1 => [
          SignupHeader(
            title: t('Products and business location'),
            subtitle: t('Choose the product categories you supply.'),
          ),
          SignupLocationFields(
            region: selectedRegion,
            town: selectedTown,
            regionError: errors['region'],
            townError: errors['town'],
            onRegionChanged: (value) => setState(() {
              selectedRegion = value;
              selectedTown = null;
              errors.remove('region');
              errors.remove('town');
            }),
            onTownChanged: (value) => setState(() {
              selectedTown = value;
              errors.remove('town');
            }),
          ),
          Text(
            t('Items you supply'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SignupSearchableChoiceChips(
            options: categories,
            selected: selectedItems,
            searchLabel: 'Search product categories',
            emptyLabel: 'No categories match your search.',
            selectionHint: 'Select all the types of products you supply.',
            onChanged: (item) => setState(() {
              if (!selectedItems.add(item)) selectedItems.remove(item);
              errors.remove('categories');
            }),
          ),
          if (errors['categories'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t(errors['categories']!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          _documentPrivacyConsent(
            value: documentPrivacyConsent,
            onChanged: (value) => setState(() {
              documentPrivacyConsent = value ?? false;
              errors.remove('privacy');
            }),
          ),
          if (errors['privacy'] != null)
            Text(
              t(errors['privacy']!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
        _ => [
          SignupHeader(
            title: t('Secure your account'),
            subtitle: t('Choose a password with at least 8 characters.'),
          ),
          PasswordField(
            label: t('Password'),
            controller: password,
            errorText: errors['password'],
            onChanged: (_) => setState(() => errors.remove('password')),
          ),
          PasswordField(
            label: t('Confirm password'),
            controller: confirmPassword,
            errorText: errors['confirmPassword'],
            onChanged: (_) => setState(() => errors.remove('confirmPassword')),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t('Review your details')),
                  _signupReviewRow(t('Company'), company.text),
                  _signupReviewRow(t('Email'), email.text),
                  _signupReviewRow(t('Phone'), phone.text),
                  _signupReviewRow(t('Products'), selectedItems.map(t).join(', ')),
                  _signupReviewRow(
                    t('Location'),
                    '${selectedTown ?? ''}, ${selectedRegion ?? ''}',
                  ),
                ],
              ),
            ),
          ),
        ],
      },
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
  String? codeError;
  String? verificationError;
  int resendSeconds = 30;
  Timer? resendTimer;

  @override
  void initState() {
    super.initState();
    startResendCooldown();
  }

  void startResendCooldown() {
    resendTimer?.cancel();
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (resendSeconds > 0) {
          resendSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  Future<void> verify() async {
    final state = context.read<AppState>();
    if (!isValidSignupCode(codeController.text.trim())) {
      setState(() {
        codeError = 'Enter the 6-digit verification code.';
        verificationError = null;
      });
      return;
    }
    setState(() {
      verifying = true;
      codeError = null;
      verificationError = null;
    });
    var success = false;
    try {
      success = await state.verifySignupCode(codeController.text.trim());
      if (!success && mounted) {
        setState(() => verificationError = state.authError);
      }
    } catch (error) {
      if (mounted) setState(() => verificationError = error.toString());
    }
    if (!mounted) return;
    setState(() => verifying = false);
    if (success) {
      final nextPage = state.userRole == 'Technician'
          ? const BusinessVerificationPage(allowSkip: true)
          : const MainNavigation();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
        (route) => false,
      );
    }
  }

  Future<void> resend() async {
    final state = context.read<AppState>();
    if (resendSeconds > 0 || resending) return;
    setState(() {
      resending = true;
      verificationError = null;
    });
    var success = false;
    try {
      success = await state.resendSignupCode();
      if (!success && mounted) {
        setState(() => verificationError = state.authError);
      }
    } catch (error) {
      if (mounted) setState(() => verificationError = error.toString());
    }
    if (!mounted) return;
    setState(() {
      resending = false;
      if (success) {
        resendSeconds = 30;
        startResendCooldown();
      }
    });
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
          t(
            'If you do not receive it, check the address or number and try again.',
          ),
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
            errorText: codeError == null ? null : t(codeError!),
          ),
          onChanged: (_) => setState(() => codeError = null),
        ),
        if (verificationError != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              t(verificationError!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SignupButton(
          text: t('VERIFY AND CREATE ACCOUNT'),
          onPressed: verifying ? null : verify,
        ),
        TextButton(
          onPressed: resending
              || resendSeconds > 0
              ? null
              : resend,
          child: Text(
            t(
              resending
                  ? 'Sending…'
                  : resendSeconds > 0
                  ? 'Resend code in {seconds}s'.replaceAll(
                      '{seconds}',
                      '$resendSeconds',
                    )
                  : 'Resend code',
            ),
          ),
        ),
        TextButton(
          onPressed: verifying || resending ? null : () => Navigator.pop(context),
          child: Text(t('Back to edit signup details')),
        ),
      ],
    );
  }
}
