import 'package:fixmate/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only business roles with unexpired subscriptions are active', () {
    final state = AppState()
      ..userRole = 'Technician'
      ..subscriptionExpiresAt = DateTime.now().add(const Duration(days: 1));
    expect(state.hasActiveBusinessSubscription, isTrue);

    state.subscriptionExpiresAt = DateTime.now().subtract(
      const Duration(seconds: 1),
    );
    expect(state.hasActiveBusinessSubscription, isFalse);

    state
      ..userRole = 'Customer'
      ..subscriptionExpiresAt = DateTime.now().add(const Duration(days: 1));
    expect(state.hasActiveBusinessSubscription, isFalse);
  });

  test('hidden listings stay out of the customer catalog', () {
    final listed = Product(
      id: 'listed',
      name: 'Listed',
      price: 100,
      isListed: true,
    );
    final hidden = Product(
      id: 'hidden',
      name: 'Hidden',
      price: 100,
      isListed: false,
    );
    final state = AppState()
      ..products = [listed, hidden]
      ..userRole = 'Customer';

    expect(state.catalogProducts, [listed]);

    state.userRole = 'Supplier';
    expect(state.catalogProducts, [listed, hidden]);
  });

  test(
    'paid checkout removes only quantities present in the checkout snapshot',
    () {
      final state = AppState();
      state.cartItems.add(
        CartItem(
          productId: 'product-1',
          name: 'Part',
          price: 500,
          supplierName: 'Supplier',
          quantity: 2,
        ),
      );
      state.setProductCheckoutCartSnapshot();
      state.cartItems.first.quantity += 1;
      state.cartItems.add(
        CartItem(
          productId: 'product-2',
          name: 'Tool',
          price: 700,
          supplierName: 'Supplier',
        ),
      );

      state.clearCartAfterPaidOrder();

      expect(state.cartItems, hasLength(2));
      expect(state.cartItems.first.productId, 'product-1');
      expect(state.cartItems.first.quantity, 1);
      expect(state.cartItems.last.productId, 'product-2');
    },
  );

  test('a restored paid checkout does not clear a new in-memory cart', () {
    final state = AppState();
    state.cartItems.add(
      CartItem(
        productId: 'new-product',
        name: 'New item',
        price: 900,
        supplierName: 'Supplier',
      ),
    );

    state.clearCartAfterPaidOrder();

    expect(state.cartItems, hasLength(1));
  });
}
