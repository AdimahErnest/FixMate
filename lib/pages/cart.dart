// FixMate — Cart page and checkout

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('My Cart')),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: state.cartItems.isEmpty
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
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatPrice(item.price * item.quantity),
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
                                    onPressed: () =>
                                        state.decreaseQuantity(item.key),
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
                                    onPressed: () =>
                                        state.increaseQuantity(item.key),
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
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            if (state.cartItems.isEmpty) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(t('Your cart is empty.'))),
                              );
                              return;
                            }

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            final ok = await state.completePurchaseSupabase();
                            navigator.pop(); // close loader
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? t('Order placed! Thank you.')
                                      : t('Could not place your order. Please try again.'),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FixMateTheme.gold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(t('CHECKOUT')),
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
