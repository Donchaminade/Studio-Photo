import 'package:Picon/splash_screen.dart';
import 'package:Picon/widgets/photo_lightbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash premium : logo + PICON centrés', (t) async {
    await t.pumpWidget(const MaterialApp(home: SplashScreen(autoNavigate: false)));
    await t.pump(const Duration(milliseconds: 2700));
    final c = t.getCenter(find.text('PICON'));
    expect((c.dx - t.view.physicalSize.width / t.view.devicePixelRatio / 2).abs() < 1, isTrue);
  });

  testWidgets('visionneuse : infos format/qté et fermeture', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showPhotoLightbox(ctx, imageUrl: '', format: '10x15 cm', quantity: 2),
          child: const Text('ouvrir'),
        ),
      ),
    ));
    await t.tap(find.text('ouvrir'));
    await t.pumpAndSettle();
    expect(find.text('10x15 cm'), findsOneWidget);
    expect(find.text('× 2'), findsOneWidget);
    await t.tap(find.byTooltip('Fermer'));
    await t.pumpAndSettle();
    expect(find.text('10x15 cm'), findsNothing);
  });
}
