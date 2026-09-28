// FixMate — Customer order history

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadCustomerOrders();
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

  Widget buildItem(CustomerOrderItem item, String Function(String) t) {
    final color = statusColor(item.status);
    final showContact = item.supplierPhone.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${item.quantity} × ${t(item.productName)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
        if (item.supplierName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${t('Sold by')}: ${item.supplierName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (showContact) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: FixMateTheme.gold),
              const SizedBox(width: 6),
              Expanded(child: SelectableText(item.supplierPhone)),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Text(
          formatPrice(item.subtotal),
          style: const TextStyle(
            color: FixMateTheme.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildOrder(CustomerOrder order, String Function(String) t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: FixMateTheme.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatDate(order.createdAt),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  formatPrice(order.total),
                  style: const TextStyle(
                    color: FixMateTheme.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${t('Payment')}: ${paymentLabel(order.paymentStatus, t)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            for (var i = 0; i < order.items.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              buildItem(order.items[i], t),
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
    final orders = state.customerOrders;

    final children = <Widget>[];
    if (state.customerOrdersLoading && orders.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (state.customerOrdersFailed && orders.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(t('Could not load orders.')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: state.loadCustomerOrders,
              child: Text(t('Retry')),
            ),
          ],
        ),
      ));
    } else if (orders.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 70, color: FixMateTheme.gold),
            const SizedBox(height: 16),
            Text(
              t('No orders yet.'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              t('Your orders will appear here after checkout.'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ));
    } else {
      children.addAll(orders.map((order) => buildOrder(order, t)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('My Orders')),
        actions: const [LanguageButton(), ThemeButton()],
      ),
      body: RefreshIndicator(
        onRefresh: state.loadCustomerOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }
}
