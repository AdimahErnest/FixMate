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
    final isBusinessRole =
        state.userRole == 'Technician' || state.userRole == 'Supplier';
    final isAdmin = state.userRole == 'Admin';

    final pages = isAdmin
        ? [AdminDashboardPage(), ProfilePage()]
        : isBusinessRole
        ? [HomePage(), ShopPage(), SubscriptionPage(), ProfilePage()]
        : [HomePage(), TechniciansPage(), ShopPage(), ProfilePage()];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
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
