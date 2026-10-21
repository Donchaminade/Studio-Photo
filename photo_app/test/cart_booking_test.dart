import 'package:Picon/portfolio_screen.dart';
import 'package:Picon/utils/app_theme.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('portfolio : squelette pendant le vrai chargement API', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildPiconTheme(), home: const PortfolioScreen()));
    // Premier rendu : la requête /public/dimensions est encore en cours.
    expect(find.byType(PiconSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('squelettes : liste et grille sans exception', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Column(children: [
        Expanded(child: PiconSkeletonList(count: 3)),
        Expanded(child: PiconSkeletonGrid(count: 4)),
      ])),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.byType(PiconSkeleton), findsWidgets);
  });
}
