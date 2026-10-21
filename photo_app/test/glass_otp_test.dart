import 'package:Picon/widgets/glass_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))),
    );

void main() {
  testWidgets('GlassOtpField completes after 4 digits', (tester) async {
    String? done;
    final c = TextEditingController();
    await tester.pumpWidget(_wrap(GlassOtpField(
        controller: c, stage: OtpStage.idle, onCompleted: (v) => done = v)));
    await tester.enterText(find.byType(EditableText), '1234');
    await tester.pumpAndSettle();
    expect(done, '1234');
  });

  testWidgets('Panel shows success check and verify button states',
      (tester) async {
    final c = TextEditingController();
    for (final st in OtpStage.values) {
      await tester.pumpWidget(_wrap(GlassOtpPanel(
        stage: st,
        title: 'Créez votre code',
        subtitle: 's',
        successTitle: 'OK',
        successSubtitle: 'ok',
        field: GlassOtpField(controller: c, stage: st),
        footer: OtpVerifyButton(stage: st, label: 'Valider', onPressed: () {}),
      )));
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
    }
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
  });
}
