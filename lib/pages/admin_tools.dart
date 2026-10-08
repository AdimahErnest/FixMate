import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';

class AdminToolsPage extends StatefulWidget {
  final int initialTab;

  const AdminToolsPage({super.key, this.initialTab = 0});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> accounts = [];
  bool loading = true;
  String? error;
  String accountQuery = '';
  final Set<String> busyIds = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final state = context.read<AppState>();
      final result = await Future.wait([
        state.adminLoadProducts(),
        state.adminLoadReports(),
        state.adminLoadAccounts(),
      ]);
      if (!mounted) return;
      setState(() {
        products = result[0];
        reports = result[1];
        accounts = result[2];
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

  Future<void> runAction(
    String id,
    Future<void> Function() action,
    String success,
  ) async {
    setState(() => busyIds.add(id));
    try {
      await action();
      await refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => busyIds.remove(id));
    }
  }

  Widget productList(AppState state) {
    final t = state.tr;
    if (products.isEmpty) return Center(child: Text(t('No products found.')));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: products.map((row) {
        final id = row['product_id'] as String;
        final isListed = row['is_listed'] == true;
        return Card(
          child: ListTile(
            leading: row['image_url'] is String
                ? Image.network(
                    row['image_url'] as String,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.inventory_2),
                  )
                : const Icon(Icons.inventory_2, color: FixMateTheme.gold),
            title: Text(row['product_name'] as String? ?? ''),
            subtitle: Text(
              '${row['supplier_name'] ?? t('Supplier')} · ${t('Stock')}: ${row['stock_quantity'] ?? 0} · ${t('Open reports')}: ${row['report_count'] ?? 0}',
            ),
            trailing: TextButton(
              onPressed: busyIds.contains(id)
                  ? null
                  : () => runAction(
                        id,
                        () => state.adminSetProductListing(id, !isListed),
                        t(isListed ? 'Listing hidden.' : 'Listing restored.'),
                      ),
              child: Text(t(isListed ? 'Hide' : 'Restore')),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget reportList(AppState state) {
    final t = state.tr;
    if (reports.isEmpty) return Center(child: Text(t('No reports found.')));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: reports.map((row) {
        final id = row['report_id'] as String;
        final open = row['status'] == 'open';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['product_name'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${t('Reported by')}: ${row['reporter_name'] ?? t('Customer')}'),
                const SizedBox(height: 8),
                Text(row['reason'] as String? ?? ''),
                const SizedBox(height: 8),
                if (open)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: busyIds.contains(id)
                            ? null
                            : () => runAction(
                                  id,
                                  () => state.adminReviewProductReport(
                                    id,
                                    'dismissed',
                                  ),
                                  t('Report dismissed.'),
                                ),
                        child: Text(t('Dismiss')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: busyIds.contains(id)
                            ? null
                            : () => runAction(
                                  id,
                                  () => state.adminReviewProductReport(
                                    id,
                                    'reviewed',
                                  ),
                                  t('Report reviewed.'),
                                ),
                        child: Text(t('Mark reviewed')),
                      ),
                    ],
                  )
                else
                  Chip(label: Text(t(row['status'] as String? ?? 'reviewed'))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget accountList(AppState state) {
    final t = state.tr;
    final visible = accounts.where((row) {
      final terms = [
        row['full_name'],
        row['email'],
        row['role'],
      ].join(' ').toLowerCase();
      return terms.contains(accountQuery.toLowerCase());
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (value) => setState(() => accountQuery = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: t('Search accounts'),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(child: Text(t('No accounts found.')))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: visible.map((row) {
                    final id = row['user_id'] as String;
                    final suspended = row['account_status'] == 'suspended';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          suspended
                              ? Icons.person_off_outlined
                              : Icons.person_outline,
                          color: suspended ? Colors.red : FixMateTheme.gold,
                        ),
                        title: Text(row['full_name'] as String? ?? ''),
                        subtitle: Text(
                          '${row['email'] ?? ''} · ${t(row['role'] as String? ?? '')} · ${t(suspended ? 'Suspended' : 'Active')}',
                        ),
                        trailing: row['role'] == 'Admin'
                            ? null
                            : IconButton(
                                tooltip: t(suspended ? 'Restore account' : 'Suspend account'),
                                onPressed: busyIds.contains(id)
                                    ? null
                                    : () => runAction(
                                          id,
                                          () => state.adminSetAccountStatus(
                                            id,
                                            suspended ? 'active' : 'suspended',
                                          ),
                                          t(suspended
                                              ? 'Account restored.'
                                              : 'Account suspended.'),
                                        ),
                                icon: Icon(
                                  suspended
                                      ? Icons.check_circle_outline
                                      : Icons.block_outlined,
                                ),
                              ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Admin tools')),
        actions: [
          IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: t('Products')),
            Tab(text: t('Reports')),
            Tab(text: t('Accounts')),
          ],
        ),
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
          : TabBarView(
              controller: _tabs,
              children: [
                productList(state),
                reportList(state),
                accountList(state),
              ],
            ),
    );
  }
}
