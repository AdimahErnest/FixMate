// FixMate — Customer, Technician and Supplier signup pages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/signup_helpers.dart';
import 'navigation.dart';

class CustomerSignupPage
    extends StatefulWidget {
  const CustomerSignupPage({super.key});

  @override
  State<CustomerSignupPage> createState() =>
      _CustomerSignupPageState();
}

class _CustomerSignupPageState
    extends State<CustomerSignupPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword =
      TextEditingController();

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
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(t(validation))),
       );
       return;
     }
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final success = await state.signUpSupabase(
      email: email.text.trim().toLowerCase(),
      password: password.text,
      role: 'Customer',
      fullName: '${firstName.text.trim()} ${lastName.text.trim()}',
      phone: normalizeSignupPhone(phone.text)!,
    );
    
    if (mounted) Navigator.pop(context); // Close loader

    if (success && mounted) {
     // Keep this to update local UI state immediately
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavigation()), (route) => false);
    } else if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(state.authError))));
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
          subtitle: t(
            'Find trusted technicians and buy products on FixMate.',
          ),
        ),

        SignupField(
          label: t('First name'),
          controller: firstName,
        ),

        SignupField(
          label: t('Last name'),
          controller: lastName,
        ),

        SignupField(
          label: t('Phone number'),
          controller: phone,
          keyboardType: TextInputType.phone,
        ),

        SignupField(
          label: t('Email'),
          controller: email,
          keyboardType:
              TextInputType.emailAddress,
        ),

        PasswordField(
          label: t('Password'),
          controller: password,
        ),

        PasswordField(
          label: t('Confirm password'),
          controller: confirmPassword,
        ),

        const SizedBox(height: 10),

        SignupButton(
          text: t('CREATE CUSTOMER ACCOUNT'),
          onPressed: register,
        ),
      ],
    );
  }
}


class TechnicianSignupPage
    extends StatefulWidget {
  const TechnicianSignupPage({super.key});

  @override
  State<TechnicianSignupPage> createState() =>
      _TechnicianSignupPageState();
}
class _TechnicianSignupPageState extends State<TechnicianSignupPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final Set<String> selectedServices = {};

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(validation))),
      );
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

    final success = await state.signUpSupabase(
      email: email.text.trim().toLowerCase(),
      password: password.text,
      role: 'Technician',
      fullName: '${firstName.text.trim()} ${lastName.text.trim()}',
      phone: normalizeSignupPhone(phone.text)!,
      services: selectedServices.toList(),
    );

    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(state.authError))),
      );
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
        PasswordField(label: t('Password'), controller: password),
        PasswordField(label: t('Confirm password'), controller: confirmPassword),
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
        SignupButton(
          text: t('CREATE TECHNICIAN ACCOUNT'),
          onPressed: register,
        ),
      ],
    );
  }
}


class SupplierSignupPage
    extends StatefulWidget {
  const SupplierSignupPage({super.key});

  @override
  State<SupplierSignupPage> createState() =>
      _SupplierSignupPageState();
}

class _SupplierSignupPageState
    extends State<SupplierSignupPage> {
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final company = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final additionalPhone =
      TextEditingController();
  final Set<String> selectedItems = {};

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(validation))),
      );
      return;
    }
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Please select at least one supply category.'))),
      );
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final success = await state.signUpSupabase(
      email: email.text.trim().toLowerCase(),
      password: password.text,
      role: 'Supplier',
      fullName: company.text.trim().isEmpty ? 'FixMate Supplier' : company.text.trim(),
      phone: normalizeSignupPhone(phone.text)!,
      categories: selectedItems.toList(),
      additionalPhone: additionalPhone.text.trim().isEmpty
          ? null
          : normalizeSignupPhone(additionalPhone.text),
    );
    
    if (mounted) Navigator.pop(context);
    if (success && mounted) {
    
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavigation()), (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(state.authError))));
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
          subtitle: t(
            'Sell tools, equipment, spare parts and materials.',
          ),
        ),

        SignupField(
          label: t('Company name'),
          controller: company,
        ),

        SignupField(
          label: t('Email'),
          controller: email,
          keyboardType:
              TextInputType.emailAddress,
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

        const SizedBox(height: 10),
          PasswordField(label: t('Password'), controller: password),
          PasswordField(label: t('Confirm password'), controller: confirmPassword),
          const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t('Items you supply'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((item) {
            final selected =
                selectedItems.contains(item);

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
              selectedColor:
                  FixMateTheme.gold.withValues(
                alpha: .25,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        DropdownField(
          label: t('Location'),
        ),

        DropdownField(
          label: t('Region'),
        ),

        DropdownField(
          label: t('Town'),
        ),

        const SizedBox(height: 5),

        Text(
          t(
            'Business verification documents can be submitted after registration.',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall,
        ),

        const SizedBox(height: 20),

        SignupButton(
          text: t('CREATE SUPPLIER ACCOUNT'),
          onPressed: register,
        ),
      ],
    );
  }
}
