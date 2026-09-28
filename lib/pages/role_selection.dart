// FixMate — role pickers for login-time testing and for signup

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/common.dart';
import 'navigation.dart';
import 'signup.dart';

class RoleSelectionForLoginPage
    extends StatelessWidget {
  const RoleSelectionForLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('Select account type'),
        ),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RoleCard(
              icon: Icons.person,
              title: t('Customer'),
              description: t(
                'Find technicians and purchase products.',
              ),
              onTap: () {
                state.login('Customer');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MainNavigation(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.handyman,
              title: t('Technician'),
              description: t(
                'Offer services and receive customer requests.',
              ),
              onTap: () {
                state.login('Technician');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MainNavigation(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.store,
              title: t('Supplier'),
              description: t(
                'Sell tools, parts and equipment.',
              ),
              onTap: () {
                state.login('Supplier');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MainNavigation(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.shield_outlined,
              title: t('Admin'),
              description: t(
                'Manage platform operations and approvals.',
              ),
              onTap: () {
                state.login('Admin');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigation(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class SignupRoleSelectionPage
    extends StatelessWidget {
  const SignupRoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('Create your account'),
        ),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              t('I want to register as:'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            RoleCard(
              icon: Icons.person,
              title: t('Customer'),
              description: t(
                'Request technicians and purchase products.',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CustomerSignupPage(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.handyman,
              title: t('Technician'),
              description: t(
                'Provide professional repair and maintenance services.',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TechnicianSignupPage(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.store,
              title: t('Supplier'),
              description: t(
                'Sell tools, equipment, spare parts and materials.',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SupplierSignupPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
