import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../services/fapshi_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final FapshiService _fapshiService = FapshiService();
  String _selectedPlan = 'monthly';
  String? _pendingTransactionId;
  Uri? _pendingPaymentLink;
  String? _paymentStatusMessage;
  DateTime? _lastStatusCheck;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadBusinessSubscription();
    });
  }

  Future<void> _startPayment() async {
    setState(() => _isLoading = true);
    try {
      final checkout = await _fapshiService.createSubscriptionCheckout(
        _selectedPlan,
      );
      if (!mounted) return;
      setState(() {
        _pendingTransactionId = checkout.transId;
        _pendingPaymentLink = checkout.link;
        _paymentStatusMessage =
            'Complete payment in the secure checkout, then check its status here.';
      });
      await _openCheckout();
    } on FapshiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCheckout() async {
    final link = _pendingPaymentLink;
    if (link == null) return;
    try {
      final opened = await launchUrl(
        link,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMessage('Could not open the secure Fapshi checkout.');
      }
    } catch (_) {
      if (mounted) _showMessage('Could not open the secure Fapshi checkout.');
    }
  }

  Future<void> _checkPaymentStatus() async {
    final transId = _pendingTransactionId;
    if (transId == null) return;
    final now = DateTime.now();
    final lastCheck = _lastStatusCheck;
    if (lastCheck != null &&
        now.difference(lastCheck) < const Duration(seconds: 11)) {
      _showMessage('Please wait a few seconds before checking again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastStatusCheck = now;
    });
    try {
      final status = await _fapshiService.checkSubscriptionStatus(transId);
      if (!mounted) return;
      setState(() {
        _paymentStatusMessage = switch (status) {
          'active' => 'Payment confirmed. Your subscription is active.',
          'failed' => 'Payment failed. You can start a new payment.',
          'expired' =>
            'This payment link expired. Start a new payment to subscribe.',
          _ => 'Payment is still pending. Complete checkout, then check again.',
        };
        if (status == 'active') _pendingPaymentLink = null;
        if (status == 'failed' || status == 'expired') {
          _pendingTransactionId = null;
          _pendingPaymentLink = null;
        }
      });
      if (status == 'active') {
        await context.read<AppState>().loadBusinessSubscription();
      }
    } on FapshiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isSupplier = state.userRole == 'Supplier';
    final monthlyPrice = isSupplier ? 34 : 9;
    final yearlyPrice = isSupplier ? 340 : 90;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your plan',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              isSupplier
                  ? 'Supplier Account Pricing (USD)'
                  : 'Technician Account Pricing (USD)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (state.subscriptionLoading)
              const LinearProgressIndicator()
            else if (state.subscriptionLoadFailed)
              Row(
                children: [
                  const Expanded(
                    child: Text('Could not check your subscription status.'),
                  ),
                  TextButton(
                    onPressed: state.loadBusinessSubscription,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (state.hasActiveBusinessSubscription)
              Text(
                'Subscription active until ${state.subscriptionExpiresAt!.toLocal().toString().split(' ').first}.',
                style: const TextStyle(color: Colors.green),
              )
            else
              const Text(
                'An active subscription is required to publish products or manage service work.',
              ),
            const SizedBox(height: 24),
            _buildPlanCard(
              title: 'Monthly Plan',
              price: monthlyPrice,
              duration: '/month',
              isSelected: _selectedPlan == 'monthly',
              onTap: () => setState(() => _selectedPlan = 'monthly'),
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              title: 'Yearly Plan',
              price: yearlyPrice,
              duration: '/year',
              isSelected: _selectedPlan == 'yearly',
              onTap: () => setState(() => _selectedPlan = 'yearly'),
              badge: 'Save 17%',
            ),
            if (_paymentStatusMessage != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_paymentStatusMessage!),
                      if (_pendingTransactionId != null) ...[
                        const SizedBox(height: 12),
                        if (_pendingPaymentLink != null)
                          OutlinedButton(
                            onPressed: _isLoading ? null : _openCheckout,
                            child: const Text('Open checkout'),
                          ),
                        FilledButton(
                          onPressed: _isLoading ? null : _checkPaymentStatus,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Check payment status'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.subscriptionLoading ||
                        _isLoading ||
                        (_pendingTransactionId != null &&
                            _paymentStatusMessage !=
                                'Payment confirmed. Your subscription is active.')
                    ? null
                    : _startPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Proceed to secure payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required int price,
    required String duration,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18)),
                if (badge != null) ...[
                  const SizedBox(height: 5),
                  Text(badge, style: const TextStyle(color: Colors.green)),
                ],
              ],
            ),
            Text(
              '\$$price USD$duration',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
