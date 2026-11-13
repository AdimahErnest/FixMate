import 'dart:typed_data';

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

  test('blue verification requires approved documents and an active plan', () {
    final state = AppState()
      ..userRole = 'Technician'
      ..subscriptionExpiresAt = DateTime.now().add(const Duration(days: 1))
      ..businessVerificationStatus = 'submitted';
    expect(state.isBusinessVerified, isFalse);

    state.businessVerificationStatus = 'approved';
    expect(state.isBusinessVerified, isTrue);

    state.subscriptionExpiresAt = DateTime.now().subtract(
      const Duration(seconds: 1),
    );
    expect(state.isBusinessVerified, isFalse);

    state
      ..userRole = 'Supplier'
      ..subscriptionExpiresAt = DateTime.now().add(const Duration(days: 1))
      ..businessVerificationStatus = 'approved';
    expect(state.isBusinessVerified, isTrue);
  });

  test('subscription and review state changes immediately remove the badge', () {
    final state = AppState()
      ..userRole = 'Supplier'
      ..subscriptionExpiresAt = DateTime.now().add(const Duration(days: 1))
      ..businessVerificationStatus = 'approved';
    expect(state.isBusinessVerified, isTrue);

    state.businessVerificationStatus = 'rejected';
    expect(state.isBusinessVerified, isFalse);

    state
      ..businessVerificationStatus = 'approved'
      ..subscriptionExpiresAt = DateTime.now();
    expect(state.isBusinessVerified, isFalse);
  });

  test('verification file type must match its content signature', () {
    expect(
      verificationDocumentMimeType(
        fileName: 'certificate.pdf',
        bytes: Uint8List.fromList('%PDF-1.7'.codeUnits),
      ),
      'application/pdf',
    );
    expect(
      verificationDocumentMimeType(
        fileName: 'id.jpg',
        bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
      ),
      'image/jpeg',
    );
    expect(
      verificationDocumentMimeType(
        fileName: 'plan.png',
        bytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
        ]),
      ),
      'image/png',
    );
    expect(
      verificationDocumentMimeType(
        fileName: 'plan.webp',
        bytes: Uint8List.fromList('RIFFxxxxWEBP'.codeUnits),
      ),
      'image/webp',
    );
    expect(
      () => verificationDocumentMimeType(
        fileName: 'id.png',
        bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
      ),
      throwsFormatException,
    );
    expect(
      () => verificationDocumentMimeType(
        fileName: 'id.exe',
        bytes: Uint8List.fromList([0]),
      ),
      throwsFormatException,
    );
  });

  test('verification history and decision notifications parse from rows', () {
    final history = BusinessVerificationHistoryEntry.fromRow({
      'id': 'history-1',
      'event_type': 'rejected',
      'note': 'Provide a clearer ID image.',
      'actor_id': 'admin-1',
      'created_at': '2026-10-12T06:00:00Z',
    });
    final notification = AppNotification.fromRow({
      'id': 'notification-1',
      'title': 'Verification changes requested',
      'body': 'Provide a clearer ID image.',
      'notification_type': 'business_verification_rejected',
      'entity_id': 'provider-1',
      'created_at': '2026-10-12T06:00:00Z',
      'read_at': null,
    });

    expect(history.eventType, 'rejected');
    expect(history.note, 'Provide a clearer ID image.');
    expect(notification.type, 'business_verification_rejected');
    expect(notification.isRead, isFalse);
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
