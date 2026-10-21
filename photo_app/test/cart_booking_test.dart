import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Picon/booking_screen.dart';
import 'package:Picon/home_screen.dart';
import 'package:Picon/pricing_screen.dart';
import 'package:Picon/utils/app_theme.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUp(() {});

  testWidgets('choisir un tarif ajoute le tirage au panier', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: buildPiconTheme(), home: const HomeScreen(userName: 'Tega', userId: 1)));
    await _settle(tester);

    await tester.tap(find.text('Prix & dimensions'));
    await _settle(tester);
    expect(find.byType(PricingScreen), findsOneWidget);

    await tester.tap(find.text('Ajouter au panier'));
    await _settle(tester);

    expect(find.byType(PricingScreen), findsNothing);
    expect(find.text('Tirages choisis'), findsOneWidget);
    expect(find.textContaining('9x13 cm'), findsWidgets);
    expect(find.text('Valider'), findsOneWidget);
  });

  testWidgets("le bouton Réserver ouvre l'écran de réservation", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: buildPiconTheme(), home: const HomeScreen(userName: 'Tega', userId: 1)));
    await _settle(tester);

    await tester.tap(find.text('Réserver'));
    await _settle(tester);
    expect(find.byType(BookingScreen), findsOneWidget);
  });
}
