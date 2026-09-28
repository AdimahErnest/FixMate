// FixMate — Supplier view of orders received
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SupplierOrdersPage extends StatefulWidget {
  const SupplierOrdersPage({super.key});

  @override
  State<SupplierOrdersPage> createState() => _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage> {
  String? busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadSupplierOrders();
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String statusLabel(String status, String Function(String) t) {
    switch (status) {
      case 'confirmed':
        return t('Confirmed');
      case 'shipped':
        return t('Shipped');
      case 'delivered':
        return t('Delivered');
      case 'cancelled':
        return t('Cancelled');
      default:
        return t('Pending');
    }
  }

  String paymentLabel(String status, String Function(String) t) {
    switch (status) {
      case 'paid':
        return t('Paid');
      case 'refunded':
        return t('Refunded');
      default:
        return t('Unpaid');
    }
  }

  String formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year}  $hour:$minute';
  }

  String formatPrice(double price) => '${price.toStringAsFixed(0)} FCFA';

  Future<bool> confirm(String message) async {
    final t = context.read<AppState>().tr;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('No')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('Yes')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> changeStatus(SupplierOrderItem item, String status) async {
    final state = context.read<AppState>();
    final t = state.tr;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => busyId = item.id);
    final ok = await state.updateOrderItemStatus(item.id, status);
    if (!mounted) return;
    setState(() => busyId = null);

    messenger.showSnackBar(SnackBar(
      content: Text(ok ? t('Item updated.') : t('Could not update the item.')),
    ));
  }

  Future<void> declineItem(SupplierOrderItem item) async {
    final t = context.read<AppState>().tr;
    if (!await confirm(t('Decline this item?'))) return;
    if (!mounted) return;
    await changeStatus(item, 'cancelled');
  }

  Widget buildCard(SupplierOrderItem item, String Function(String) t) {
    final busy = busyId == item.id;
    final color = statusColor(item.status);
    final showContact = item.status != 'pending' &&
        item.status != 'cancelled' &&
        item.customerPhone.isNotEmpty;

    Widget? actions;
    if (item.status == 'pending') {
      actions = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : () => declineItem(item),
              child: Text(t('Decline')),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: busy ? null : () => changeStatus(item, 'confirmed'),
              child: Text(t('Confirm')),
            ),
          ),
        ],
      );
    } else if (item.status == 'confirmed') {
      actions = SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : () => changeStatus(item, 'shipped'),
          child: Text(t('Mark as shipped')),
        ),
      );
    } else if (item.status == 'shipped') {
      actions = SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : () => changeStatus(item, 'delivered'),
          child: Text(t('Mark as delivered')),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity} × ${t(item.productName)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel(item.status, t),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatPrice(item.subtotal),
              style: const TextStyle(
                color: FixMateTheme.gold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: FixMateTheme.gold),
                const SizedBox(width: 6),
                Expanded(child: Text(item.customerName)),
              ],
            ),
            if (showContact) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: FixMateTheme.gold),
                  const SizedBox(width: 6),
                  Expanded(child: SelectableText(item.customerPhone)),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18, color: FixMateTheme.gold),
                const SizedBox(width: 6),
                Text('${t('Payment')}: ${paymentLabel(item.paymentStatus, t)}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatDate(item.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (actions != null) ...[
              const SizedBox(height: 14),
              actions,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    int rank(String status) {
      switch (status) {
        case 'pending':
          return 0;
        case 'confirmed':
          return 1;
        case 'shipped':
          return 2;
        default:
          return 3;
      }
    }

    final items = [...state.supplierOrders]
      ..sort((a, b) {
        final byStatus = rank(a.status).compareTo(rank(b.status));
        return byStatus != 0 ? byStatus : b.createdAt.compareTo(a.createdAt);
      });

    final children = <Widget>[];
    if (state.supplierOrdersLoading && items.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (state.supplierOrdersFailed && items.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(t('Could not load orders.')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: state.loadSupplierOrders,
              child: Text(t('Retry')),
            ),
          ],
        ),
      ));
    } else if (items.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 70, color: FixMateTheme.gold),
            const SizedBox(height: 16),
            Text(
              t('No orders yet.'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ));
    } else {
      children.addAll(items.map((item) => buildCard(item, t)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Orders received')),
        actions: const [LanguageButton(), ThemeButton()],
      ),
      body: RefreshIndicator(
        onRefresh: state.loadSupplierOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }
}
