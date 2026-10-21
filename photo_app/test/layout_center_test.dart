import 'package:Picon/login_screen.dart';
import 'package:Picon/signup_screen.dart';
import 'package:Picon/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(390, 844), Size(430, 932), Size(820, 1180)];
  final screens = <String, Widget Function()>{
    'login': () => const LoginScreen(),
    'signup': () => const SignupScreen(),
  };
  for (final e in screens.entries) {
    for (final sz in sizes) {
      for (final kb in [false, true]) {
        testWidgets('${e.key} ${sz.width.toInt()}x${sz.height.toInt()} clavier=$kb', (tester) async {
          tester.view.physicalSize = sz;
          tester.view.devicePixelRatio = 1;
          if (kb) tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MaterialApp(theme: buildPiconTheme(), home: e.value()));
          await tester.pump(const Duration(milliseconds: 900));
          expect(tester.takeException(), isNull);
          // Le formulaire est centré horizontalement et limité à 420 px.
          final card = tester.getRect(find.byType(Form).first);
          expect(card.width, lessThanOrEqualTo(420));
          expect((card.center.dx - sz.width / 2).abs(), lessThan(2));
        });
      }
    }
  }
}
