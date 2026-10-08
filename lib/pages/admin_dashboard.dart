// FixMate — data-backed admin overview
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'admin_tools.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> accounts = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final state = context.read<AppState>();
      final values = await Future.wait([
        state.adminLoadProducts(),
        state.adminLoadReports(),
        state.adminLoadAccounts(),
      ]);
      if (!mounted) return;
      setState(() {
        products = values[0];
        reports = values[1];
        accounts = values[2];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void openTools(BuildContext context, int tab) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminToolsPage(initialTab: tab)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    return Scaffold(
      appBar: FixMateAppBar(
        title: t('Dashboard'),
        actions: [
          IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: refresh, child: Text(t('Retry'))),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    t('Platform overview'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(t('Manage platform operations and approvals.')),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      _StatCard(
                        label: t('Product listings'),
                        value: '${products.length}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _StatCard(
                        label: t('Open reports'),
                        value: '${reports.where((row) => row['status'] == 'open').length}',
                        icon: Icons.report_problem_outlined,
                      ),
                      _StatCard(
                        label: t('Accounts'),
                        value: '${accounts.length}',
                        icon: Icons.people_outline,
                      ),
                      _StatCard(
                        label: t('Suspended accounts'),
                        value: '${accounts.where((row) => row['account_status'] == 'suspended').length}',
                        icon: Icons.person_off_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('Management'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _ToolTile(
                    title: t('Moderate product listings'),
                    subtitle: t('Hide or restore marketplace listings.'),
                    icon: Icons.storefront_outlined,
                    onTap: () => openTools(context, 0),
                  ),
                  _ToolTile(
                    title: t('Review product reports'),
                    subtitle: t('Investigate customer reports.'),
                    icon: Icons.flag_outlined,
                    onTap: () => openTools(context, 1),
                  ),
                  _ToolTile(
                    title: t('Manage accounts'),
                    subtitle: t('Search, suspend, or restore user accounts.'),
                    icon: Icons.manage_accounts_outlined,
                    onTap: () => openTools(context, 2),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: FixMateTheme.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t('Admin changes are checked against your Supabase Admin profile.'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: FixMateTheme.gold.withValues(alpha: .15),
            child: Icon(icon, color: FixMateTheme.gold),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      );
}
