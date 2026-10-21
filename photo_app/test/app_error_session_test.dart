import 'package:Picon/utils/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un refus ou une confirmation ne ferment pas la session', () {
    final business = AppError.from(
      "Vous n'êtes pas autorisé à confirmer le paiement de cette commande.",
      statusCode: 400,
    );
    expect(business.kind, isNot(AppErrorKind.session));

    final forbidden = AppError.from('Accès interdit.', statusCode: 403);
    expect(forbidden.kind, isNot(AppErrorKind.session));

    final unauthorized = AppError.from(
      'Non autorisé. Veuillez vous connecter.',
      statusCode: 401,
    );
    expect(unauthorized.kind, isNot(AppErrorKind.session));

    final confirm = AppError.from(
      'Confirmation reçue. Paiement en cours de validation par nos équipes.',
    );
    expect(confirm.kind, isNot(AppErrorKind.session));
  });

  test('un JWT expiré reste une session morte', () {
    final jwt = AppError.from(
      'JWT expired at 2020-01-01T00:00:00Z. Current time: 2026-01-01T00:00:00Z',
      statusCode: 500,
    );
    expect(jwt.kind, AppErrorKind.session);
  });
}
