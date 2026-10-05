// FixMate — Admin role dashboard (static demo data)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    final stats = [
      _StatCard(label: t('Pending approvals'), value: '24', icon: Icons.pending_actions_outlined),
      _StatCard(label: t('Active technicians'), value: '1,248', icon: Icons.handyman_outlined),
      _StatCard(label: t('Monthly revenue'), value: '₣ 4.8M', icon: Icons.attach_money_outlined),
      _StatCard(label: t('Open disputes'), value: '08', icon: Icons.report_problem_outlined),
    ];

    final actions = [
      _QuickActionTile(title: t('Review supplier requests'), icon: Icons.storefront_outlined),
      _QuickActionTile(title: t('Verify technician profiles'), icon: Icons.verified_user_outlined),
      _QuickActionTile(title: t('Resolve customer complaints'), icon: Icons.support_agent_outlined),
      _QuickActionTile(title: t('View analytics'), icon: Icons.analytics_outlined),
    ];

    final activity = [
      t('New supplier onboarding'),
      t('Technician verification complete'),
      t('Payment dispute escalated'),
      t('Campaign promotion approved'),
    ];

    return Scaffold(
      appBar: FixMateAppBar(title: t('Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Platform overview'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                t('Manage platform operations and approvals.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: stats.map((item) => item).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                t('Quick actions'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...actions.map(
                (action) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: FixMateTheme.gold.withValues(alpha: 0.15),
                      child: Icon(action.icon, color: FixMateTheme.gold),
                    ),
                    title: Text(action.title),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t('Recent platform activity'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...activity.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_outlined, color: FixMateTheme.gold),
                    title: Text(entry),
                    trailing: TextButton(
                      onPressed: () {},
                      child: Text(t('Approve')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: FixMateTheme.gold, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile {
  final String title;
  final IconData icon;

  const _QuickActionTile({
    required this.title,
    required this.icon,
  });
}