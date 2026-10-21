import 'package:Picon/order_receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> order({String status = 'PENDING_PAYMENT', String pay = 'CUSTOMER_REPORTED_PAID', bool proof = true}) => {
      'id': 1042,
      'status': status,
      'paymentStatus': pay,
      'paymentMethod': 'Flooz',
      'totalAmount': 1100,
      'createdAt': '2026-10-21T10:30:00',
      'updatedAt': '2026-10-21T12:05:00',
      if (proof) 'paymentProofImageUrl': '/uploads/proof.jpg',
      'orderItems': [
        {'id': 1, 'imageUrl': '', 'photoSize': '10x15 cm', 'quantity': 2, 'pricePerUnit': 300},
        {'id': 2, 'imageUrl': '', 'photoSize': '13x18 cm', 'quantity': 1, 'pricePerUnit': 500},
      ],
    };

Future<void> pump(WidgetTester t, Map<String, dynamic> o) async {
  t.view.physicalSize = const Size(390 * 3, 844 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: OrderReceiptScreen(orderId: 1042, initialOrder: o, proofSentAt: DateTime(2026, 10, 21, 11), refresh: false),
  ));
  await t.pump(const Duration(seconds: 5));
}

void main() {
  test('variantes déduites du statut API', () {
    expect(receiptVariantFor(order()), ReceiptVariant.review);
    expect(receiptVariantFor(order(pay: 'PAID')), ReceiptVariant.paid);
    expect(receiptVariantFor(order(status: 'PROCESSING', pay: 'PENDING_PAYMENT')), ReceiptVariant.paid);
    expect(receiptVariantFor(order(status: 'COMPLETED')), ReceiptVariant.paid);
    expect(receiptVariantFor(order(pay: 'REJECTED')), ReceiptVariant.rejected);
    expect(receiptVariantFor(order(status: 'CANCELLED', pay: 'CUSTOMER_REPORTED_PAID')), ReceiptVariant.rejected);
    expect(hasReceipt(order(pay: 'PENDING_PAYMENT', proof: false)), isFalse);
  });

  testWidgets('reçu 1 : en vérification, sans tampon PAYÉ', (t) async {
    await pump(t, order());
    expect(find.text('Bon de commande'), findsOneWidget);
    expect(find.text('EN VÉRIFICATION'), findsOneWidget);
    expect(find.textContaining("n'est pas une preuve de paiement validé"), findsOneWidget);
    expect(find.text('PAYÉ'), findsNothing);
    expect(find.text('REÇU N°'), findsNothing);
  });

  testWidgets('reçu 1 refusé : PAIEMENT REFUSÉ, jamais de reçu 2', (t) async {
    await pump(t, order(pay: 'REJECTED'));
    expect(find.text('PAIEMENT REFUSÉ'), findsOneWidget);
    expect(find.text('Reçu de paiement'), findsNothing);
    expect(find.text('PAYÉ'), findsNothing);
  });

  testWidgets('reçu 2 : PAYÉ, n° de reçu, date de validation (updatedAt)', (t) async {
    await pump(t, order(pay: 'PAID'));
    expect(find.text('Reçu de paiement'), findsOneWidget);
    expect(find.text('RP-001042'), findsWidgets);
    expect(find.text('VALIDÉ LE'), findsOneWidget);
    expect(find.text('21/10/2026 12:05'), findsOneWidget);
    expect(find.text('PAYÉ'), findsWidgets);
    expect(find.text('EN VÉRIFICATION'), findsNothing);
  });
}
