// FixMate — Cart page and checkout

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../services/fapshi_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

String _newCheckoutId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

class _CartPageState extends State<CartPage> {
  final FapshiService _payments = FapshiService();
  String? _pendingOrderId;
  String? _checkoutId;
  Uri? _pendingPaymentLink;
  bool _checkoutBusy = false;
  bool _restoringCheckout = true;

  String get _checkoutPrefKey =>
      'fixmate.pendingProductCheckout.${Supabase.instance.client.auth.currentUser?.id ?? 'anonymous'}';

  @override
  void initState() {
    super.initState();
    _restorePendingCheckout();
  }

  Future<void> _restorePendingCheckout() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _checkoutId = preferences.getString('$_checkoutPrefKey.id');
        _pendingOrderId = preferences.getString('$_checkoutPrefKey.order');
        final savedLink = preferences.getString('$_checkoutPrefKey.link');
        _pendingPaymentLink = savedLink == null
            ? null
            : Uri.tryParse(savedLink);
        _restoringCheckout = false;
      });
    } catch (_) {
      if (mounted) setState(() => _restoringCheckout = false);
    }
  }

  String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} FCFA';
  }

  Future<void> checkout(AppState state) async {
    final t = state.tr;
    final messenger = ScaffoldMessenger.of(context);
    if (_checkoutBusy) return;
    setState(() => _checkoutBusy = true);
    try {
      if (_pendingOrderId != null) {
        final status = await _payments.checkProductOrderStatus(
          _pendingOrderId!,
        );
        if (!mounted) return;
        if (status == 'paid') {
          await _clearStoredCheckout();
          if (!mounted) return;
          state.clearCartAfterPaidOrder();
          await state.loadCustomerOrders();
          if (!mounted) return;
          setState(() => _pendingOrderId = null);
          _checkoutId = null;
          _pendingPaymentLink = null;
          messenger.showSnackBar(
            SnackBar(content: Text(t('Order placed! Thank you.'))),
          );
        } else if (status == 'failed') {
          await _clearStoredCheckout();
          if (!mounted) return;
          state.discardProductCheckoutCartSnapshot();
          setState(() => _pendingOrderId = null);
          _checkoutId = null;
          _pendingPaymentLink = null;
          messenger.showSnackBar(
            SnackBar(
              content: Text(t('Payment failed. No payment was confirmed.')),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(t('Payment is still pending.'))),
          );
        }
        return;
      }

      Future<bool> recoverPendingCheckout(AppState state) async {
        final checkoutId = _checkoutId;
        if (checkoutId == null) return false;
        try {
          final recovery = await _payments.recoverProductOrderCheckout(
            checkoutId,
          );
          if (!mounted) return true;
          if (recovery.status == 'failed') {
            await _clearStoredCheckout();
            if (!mounted) return true;
            state.discardProductCheckoutCartSnapshot();
            setState(() {
              _checkoutId = null;
              _pendingOrderId = null;
              _pendingPaymentLink = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.tr('Payment failed. No payment was confirmed.'),
                ),
              ),
            );
            return true;
          }
          final preferences = await SharedPreferences.getInstance();
          await preferences.setString(
            '$_checkoutPrefKey.order',
            recovery.orderId,
          );
          if (recovery.link != null) {
            await preferences.setString(
              '$_checkoutPrefKey.link',
              recovery.link.toString(),
            );
          }
          if (!mounted) return true;
          setState(() {
            _pendingOrderId = recovery.orderId;
            _pendingPaymentLink = recovery.link;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.tr('Your pending checkout was restored.')),
            ),
          );
          return true;
        } on FapshiException catch (error) {
          if (error.statusCode == 404) {
            state.discardProductCheckoutCartSnapshot();
            _checkoutId = null;
            await _clearStoredCheckout();
            return false;
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.tr(error.message))));
          }
          return true;
        }
      }

      if (_pendingOrderId == null && _checkoutId != null) {
        final recovered = await recoverPendingCheckout(state);
        if (recovered || !mounted) return;
      }

      if (state.cartItems.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(t('Your cart is empty.'))),
        );
        return;
      }
      final items = <Map<String, Object>>[];
      for (final item in state.cartItems) {
        final productId = item.productId;
        if (productId == null ||
            !RegExp(
              r'^[0-9a-f-]{36}$',
              caseSensitive: false,
            ).hasMatch(productId)) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                t(
                  'A cart item is unavailable for online checkout. Remove it and add a listed product.',
                ),
              ),
            ),
          );
          return;
        }
        items.add({'product_id': productId, 'quantity': item.quantity});
      }

      state.setProductCheckoutCartSnapshot();
      _checkoutId ??= _newCheckoutId();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('$_checkoutPrefKey.id', _checkoutId!);
      final checkout = await _payments.createProductOrderCheckout(
        items,
        _checkoutId!,
      );
      if (!mounted) return;
      setState(() {
        _pendingOrderId = checkout.orderId;
        _pendingPaymentLink = checkout.link;
      });
      await preferences.setString('$_checkoutPrefKey.order', checkout.orderId);
      await preferences.setString(
        '$_checkoutPrefKey.link',
        checkout.link.toString(),
      );
      final launched = await launchUrl(
        checkout.link,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              t(
                'Could not open the payment page. Tap CHECKOUT to check payment status or try opening the link again.',
              ),
            ),
          ),
        );
      }
    } on FapshiException catch (error) {
      if (error.retryable && _pendingOrderId == null) {
        _checkoutId = null;
        state.discardProductCheckoutCartSnapshot();
        try {
          await _clearStoredCheckout();
        } catch (storageError) {
          debugPrint(
            'Could not clear failed checkout reference: $storageError',
          );
        }
      }
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(t(error.message))));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(t('Could not start checkout. Please try again.')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkoutBusy = false);
    }
  }

  Future<void> _clearStoredCheckout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_checkoutPrefKey.id');
    await preferences.remove('$_checkoutPrefKey.order');
    await preferences.remove('$_checkoutPrefKey.link');
  }

  Future<void> _reopenPaymentPage() async {
    final link = _pendingPaymentLink;
    if (link == null) return;
    try {
      final opened = await launchUrl(
        link,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AppState>().tr(
                'Could not open the Fapshi payment page.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AppState>().tr(
                'Could not open the Fapshi payment page.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('My Cart')),
        actions: const [LanguageButton(), ThemeButton()],
      ),
      body:
          state.cartItems.isEmpty &&
              _pendingOrderId == null &&
              _checkoutId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 70,
                      color: FixMateTheme.gold,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t('Your cart is empty.'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('Add products from the shop.'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = state.cartItems[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(item.key),
                          direction: _pendingOrderId == null
                              ? DismissDirection.endToStart
                              : DismissDirection.none,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) {
                            final removedItem = item;
                            final removedIndex = index;
                            final messenger = ScaffoldMessenger.of(context);
                            state.removeFromCart(removedItem.key);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(t('Removed from cart')),
                                action: SnackBarAction(
                                  label: t('UNDO'),
                                  onPressed: () => state.restoreCartItem(
                                    removedItem,
                                    removedIndex,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.build,
                                    color: FixMateTheme.gold,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t(item.name),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${formatPrice(item.price)} × ${item.quantity}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatPrice(
                                            item.price * item.quantity,
                                          ),
                                          style: const TextStyle(
                                            color: FixMateTheme.gold,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: item.quantity > 1
                                        ? t('Decrease')
                                        : t('Remove'),
                                    onPressed: _pendingOrderId == null
                                        ? () => state.decreaseQuantity(item.key)
                                        : null,
                                    icon: Icon(
                                      item.quantity > 1
                                          ? Icons.remove_circle_outline
                                          : Icons.delete_outline,
                                      color: item.quantity > 1
                                          ? null
                                          : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: t('Increase'),
                                    onPressed: _pendingOrderId == null
                                        ? () => state.increaseQuantity(item.key)
                                        : null,
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: FixMateTheme.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (state.cartItems.isEmpty) ...[
                        Text(
                          t(
                            'You have a checkout in progress. Restore it to check payment or reopen the payment page.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_pendingOrderId != null &&
                          _pendingPaymentLink != null)
                        TextButton.icon(
                          onPressed: _checkoutBusy ? null : _reopenPaymentPage,
                          icon: const Icon(Icons.open_in_new),
                          label: Text(t('REOPEN PAYMENT PAGE')),
                        ),
                      Row(
                        children: [
                          Text(
                            t('Total'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatPrice(state.cartTotal),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: FixMateTheme.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _checkoutBusy || _restoringCheckout
                              ? null
                              : () => checkout(state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FixMateTheme.buttonGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _checkoutBusy || _restoringCheckout
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _pendingOrderId == null
                                      ? (_checkoutId == null
                                            ? t('CHECKOUT')
                                            : t('RESUME CHECKOUT'))
                                      : t('CHECK PAYMENT STATUS'),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
