// FixMate — bottom navigation shell shown after login
import 'subscription.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'admin_dashboard.dart';
import 'home.dart';
import 'technicians.dart';
import 'shop.dart';
import 'profile.dart';
import 'business_verification.dart';
import 'login.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().startNotificationStream();
    });
  }

  @override
  void dispose() {
    context.read<AppState>().stopNotificationStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAuthenticatedSupplier =
        state.userRole == 'Supplier' && supabase.auth.currentUser != null;
    if (isAuthenticatedSupplier &&
        state.businessVerificationLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (isAuthenticatedSupplier && state.businessVerificationLoadFailed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We could not check your company approval. Access stays limited until verification status can be confirmed.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: state.loadBusinessVerification,
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () async {
                    await state.signOutSupabase();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (_) => false,
                      );
                    }
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (isAuthenticatedSupplier &&
        !state.hasApprovedBusinessDocuments) {
      return const BusinessVerificationPage();
    }

    final isBusinessRole =
        state.userRole == 'Technician' || state.userRole == 'Supplier';
    final isAdmin = state.userRole == 'Admin';

    final pages = isAdmin
        ? [AdminDashboardPage(), ProfilePage()]
        : isBusinessRole
        ? [HomePage(), ShopPage(), SubscriptionPage(), ProfilePage()]
        : [HomePage(), TechniciansPage(), ShopPage(), ProfilePage()];

    return Scaffold(
      body: Column(
        children: [
          if (state.userRole == 'Technician' && !state.isBusinessVerified)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusinessVerificationPage(
                          allowSkip: true,
                        ),
                      ),
                    );
                    if (context.mounted) {
                      context.read<AppState>().loadBusinessVerification();
                      context.read<AppState>().loadBusinessSubscription();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.hasApprovedBusinessDocuments
                                ? 'Subscribe to display your blue verified badge.'
                                : state.businessVerificationStatus == 'submitted'
                                ? 'Documents are under review. Your verified badge appears after approval and subscription.'
                                : 'Submit your verification documents to qualify for the blue verified badge.',
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(index: currentIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: FixMateBottomNavigation(
        currentIndex: currentIndex,
        isBusinessRole: isBusinessRole,
        isAdmin: isAdmin,
        onChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}

class FixMateBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final bool isBusinessRole;
  final bool isAdmin;
  final ValueChanged<int> onChanged;

  const FixMateBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.isBusinessRole,
    required this.isAdmin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    final labels = isAdmin
        ? [t('Dashboard'), t('Profile')]
        : isBusinessRole
        ? [t('Home'), t('Shop'), t('Subscription'), t('Profile')]
        : [t('Home'), t('Technicians'), t('Shop'), t('Profile')];

    final icons = isAdmin
        ? [Icons.dashboard_outlined, Icons.person_outline]
        : isBusinessRole
        ? [
            Icons.home_outlined,
            Icons.shopping_bag_outlined,
            Icons.card_membership_outlined,
            Icons.person_outline,
          ]
        : [
            Icons.home_outlined,
            Icons.handyman_outlined,
            Icons.shopping_bag_outlined,
            Icons.person_outline,
          ];

    final selectedIcons = isAdmin
        ? [Icons.dashboard, Icons.person]
        : isBusinessRole
        ? [Icons.home, Icons.shopping_bag, Icons.card_membership, Icons.person]
        : [Icons.home, Icons.handyman, Icons.shopping_bag, Icons.person];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(24),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: FixMateTheme.gold.withValues(alpha: .22),
          selectedIndex: currentIndex,
          onDestinationSelected: onChanged,
          destinations: List.generate(labels.length, (index) {
            return NavigationDestination(
              icon: Icon(icons[index]),
              selectedIcon: Icon(selectedIcons[index]),
              label: labels[index],
            );
          }),
        ),
      ),
    );
  }
}
