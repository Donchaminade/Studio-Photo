/// Erreur destinée à l’utilisateur : jamais de stack, HTML, ni code technique.
enum AppErrorKind { server, network, session, auth, generic }

class AppError implements Exception {
  final AppErrorKind kind;
  final String message;

  const AppError(this.kind, this.message);

  factory AppError.server() => const AppError(
        AppErrorKind.server,
        'Le service est momentanément indisponible. Réessayez dans quelques instants.',
      );

  factory AppError.network() => const AppError(
        AppErrorKind.network,
        'Impossible de joindre le serveur. Vérifiez votre connexion internet.',
      );

  factory AppError.session() => const AppError(
        AppErrorKind.session,
        'Votre session a expiré. Reconnectez-vous pour continuer.',
      );

  factory AppError.auth(String message) => AppError(AppErrorKind.auth, message);

  factory AppError.generic(String message) =>
      AppError(AppErrorKind.generic, message);

  factory AppError.from(Object error, {int? statusCode, String? body}) {
    if (error is AppError) return error;

    final raw = '${body ?? ''} ${error.toString()}'.toLowerCase();

    // Uniquement un jeton JWT réellement expiré. Un 401, un 403, « non autorisé »
    // ou un message de confirmation ne ferment pas la session : ces textes
    // reviennent aussi pour un accès refusé ou une commande confirmée.
    if (_looksLikeExpiredSession(raw)) {
      return AppError.session();
    }

    if (statusCode != null && _isServerStatus(statusCode)) {
      return AppError.server();
    }

    if (_looksLikeServerPage(raw)) return AppError.server();
    if (raw.contains('formatexception') ||
        raw.contains('unexpected character') ||
        raw.contains('error code: 1033') ||
        raw.contains('error code:1033')) {
      return AppError.server();
    }
    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection refused') ||
        raw.contains('network is unreachable') ||
        raw.contains('délai dépassé') ||
        raw.contains('timeout')) {
      return AppError.network();
    }

    var text = error.toString();
    if (text.startsWith('Exception: ')) {
      text = text.substring(11);
    }
    if (text.startsWith('AppError: ')) {
      text = text.substring(10);
    }
    if (_isTechnical(text)) return AppError.server();
    if (text.trim().isEmpty) {
      return const AppError(
        AppErrorKind.generic,
        'Une erreur est survenue. Réessayez.',
      );
    }
    return AppError(AppErrorKind.generic, text);
  }

  static bool _isServerStatus(int status) {
    return status == 502 ||
        status == 503 ||
        status == 504 ||
        status == 520 ||
        status == 521 ||
        status == 522 ||
        status == 523 ||
        status == 524 ||
        status == 525 ||
        status == 530 ||
        status >= 500;
  }

  static bool _looksLikeServerPage(String raw) {
    return raw.contains('<html') ||
        raw.contains('<!doctype') ||
        raw.contains('cloudflare') ||
        raw.contains('error code:') ||
        raw.contains('cf-error');
  }

  static bool _looksLikeExpiredSession(String raw) {
    return raw.contains('jwt expired') ||
        raw.contains('expiredjwt') ||
        raw.contains('token expired') ||
        raw.contains('allowed clock skew');
  }

  static bool _isTechnical(String text) {
    final t = text.toLowerCase();
    return t.contains('formatexception') ||
        t.contains('unexpected character') ||
        t.contains('stacktrace') ||
        t.contains('status code') ||
        t.contains('error code:') ||
        t.contains('at character') ||
        t.contains('httpexception') ||
        t.contains('socketexception') ||
        t.contains('jwt expired') ||
        t.contains('milliseconds ago') ||
        t.contains('clock skew');
  }

  @override
  String toString() => message;
}
