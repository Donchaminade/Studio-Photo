import 'package:Picon/widgets/picon_premium.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PrintedReceipt prints then stamps and calls onPrinted', (tester) async {
    var printed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PrintedReceipt(
            ticket: const SizedBox(height: 400, child: Text('TICKET')),
            onPrinted: () => printed = true,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(printed, isTrue);
    expect(find.text('PAYÉ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CheckoutStage switches from processing to success check', (tester) async {
    Widget app(CheckoutPhase p) => MaterialApp(
          home: Scaffold(body: Center(child: CheckoutStage(phase: p, title: 't', subtitle: 's'))),
        );
    await tester.pumpWidget(app(CheckoutPhase.processing));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    await tester.pumpWidget(app(CheckoutPhase.success));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
