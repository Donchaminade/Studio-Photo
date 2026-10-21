import 'package:Picon/utils/app_error.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/session_controller.dart';
import 'package:Picon/widgets/app_status_illustration.dart';
import 'package:flutter/material.dart';

/// Affiche une erreur compréhensible. Jamais de texte technique.
Future<void> showAppError(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
  bool endSession = true,
}) async {
  final app = AppError.from(error);

  if (app.kind == AppErrorKind.session && endSession) {
    await SessionController.expireToLogin(message: app.message);
    return;
  }

  if (!context.mounted) return;

  if (app.kind == AppErrorKind.server || app.kind == AppErrorKind.network) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: AppStatusPanel(
          error: app,
          onRetry: () {
            Navigator.of(ctx).pop();
            onRetry?.call();
          },
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(app.message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Erreur dans un FutureBuilder : texte FR + illustration, jamais le JWT brut.
class AppInlineError extends StatefulWidget {
  final Object error;
  final VoidCallback? onRetry;

  const AppInlineError({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  State<AppInlineError> createState() => _AppInlineErrorState();
}

class _AppInlineErrorState extends State<AppInlineError> {
  late final AppError _app;

  @override
  void initState() {
    super.initState();
    _app = AppError.from(widget.error);
    if (_app.kind == AppErrorKind.session) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SessionController.expireToLogin(message: _app.message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_app.kind == AppErrorKind.session) {
      return const Center(child: CircularProgressIndicator());
    }
    return AppStatusPanel(error: _app, onRetry: widget.onRetry);
  }
}
