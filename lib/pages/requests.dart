// FixMate — Customer/technician view of service requests
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/business_rating_dialog.dart';
import 'subscription.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  String? busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadServiceRequests();
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'declined':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String statusLabel(String status, String Function(String) t) {
    switch (status) {
      case 'accepted':
        return t('Accepted');
      case 'completed':
        return t('Completed');
      case 'declined':
        return t('Declined');
      case 'cancelled':
        return t('Cancelled');
      default:
        return t('Pending');
    }
  }

  String formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year}  $hour:$minute';
  }

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

  Future<void> changeStatus(ServiceRequestData request, String status) async {
    final state = context.read<AppState>();
    final t = state.tr;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => busyId = request.id);
    final ok = await state.updateRequestStatus(request.id, status);
    if (!mounted) return;
    setState(() => busyId = null);

    messenger.showSnackBar(SnackBar(
      content: Text(ok ? t('Request updated.') : t('Could not update the request.')),
    ));
  }

  Future<void> confirmAndChange(
    ServiceRequestData request,
    String status,
    String message,
  ) async {
    if (!await confirm(message)) return;
    if (!mounted) return;
    await changeStatus(request, status);
  }

  Widget buildRequestCard(
    ServiceRequestData request,
    String? myId,
    String Function(String) t,
  ) {
    final received = request.technicianId == myId;
    final otherName = received ? request.customerName : request.technicianName;
    final otherPhone = received ? request.customerPhone : request.technicianPhone;
    final showContact = (request.status == 'accepted' || request.status == 'completed') &&
        otherPhone.isNotEmpty;
    final busy = busyId == request.id;
    final color = statusColor(request.status);

    Widget? actions;
    if (received && request.status == 'pending') {
      actions = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy
                  ? null
                  : () => confirmAndChange(
                        request,
                        'declined',
                        t('Decline this request?'),
                      ),
              child: Text(t('Decline')),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: busy ? null : () => changeStatus(request, 'accepted'),
              child: Text(t('Accept')),
            ),
          ),
        ],
      );
    } else if (received && request.status == 'accepted') {
      actions = SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy || !context.read<AppState>().hasActiveBusinessSubscription
              ? null
              : () => changeStatus(request, 'completed'),
          child: Text(t('Mark as completed')),
        ),
      );

    } else if (!received &&
        (request.status == 'pending' || request.status == 'accepted')) {
      actions =
       SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          onPressed: busy
              ? null
              : () => confirmAndChange(
                    request,
                    'cancelled',
                    t('Cancel this request?'),
                  ),
          child: Text(t('Cancel request')),
        ),
      );
    }
    if (received &&
        (request.status == 'pending' || request.status == 'accepted') &&
        !context.read<AppState>().hasActiveBusinessSubscription) {
      actions = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('An active subscription is required to manage service requests.'),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionPage()),
            ),
            child: const Text('View subscription plans'),
          ),
        ],
      );
    }
    if (!received &&
        request.status == 'completed' &&
        !request.hasReview) {
      actions = FilledButton.tonalIcon(
        onPressed: () async {
          final ok = await showBusinessRatingDialog(
            context,
            providerId: request.technicianId,
            sourceType: 'service_request',
            sourceId: request.id,
            providerName: request.technicianName,
          );
          if (ok && mounted) {
            await context.read<AppState>().loadServiceRequests();
          }
        },
        icon: const Icon(Icons.star_outline),
        label: const Text('Rate technician'),
      );
    } else if (!received &&
        request.status == 'completed' &&
        request.hasReview) {
      actions = const Text('Rating submitted');
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
                    t(request.serviceType),
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
                    statusLabel(request.status, t),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  received ? Icons.call_received : Icons.call_made,
                  size: 18,
                  color: FixMateTheme.gold,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(otherName)),
              ],
            ),
            if (showContact) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: FixMateTheme.gold),
                  const SizedBox(width: 6),
                  Expanded(child: SelectableText(otherPhone)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(request.description),
            const SizedBox(height: 8),
            Text(
              formatDate(request.createdAt),
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
    final myId = supabase.auth.currentUser?.id;

    int rank(String status) =>
        status == 'pending' ? 0 : status == 'accepted' ? 1 : 2;

    final requests = [...state.serviceRequests]
      ..sort((a, b) {
        final byStatus = rank(a.status).compareTo(rank(b.status));
        return byStatus != 0 ? byStatus : b.createdAt.compareTo(a.createdAt);
      });

    final children = <Widget>[];
    if (state.requestsLoading && requests.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (state.requestsFailed && requests.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(t('Could not load your requests.')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: state.loadServiceRequests,
              child: Text(t('Retry')),
            ),
          ],
        ),
      ));
    } else if (requests.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.assignment_outlined, size: 70, color: FixMateTheme.gold),
            const SizedBox(height: 16),
            Text(
              t('No requests yet.'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ));
    } else {
      children.addAll(requests.map((r) => buildRequestCard(r, myId, t)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('My Requests')),
        actions: const [LanguageButton(), ThemeButton()],
      ),
      body: RefreshIndicator(
        onRefresh: state.loadServiceRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }
}
