import 'package:flutter/material.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class LoadingButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final String text;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _loading = false;
  bool _success = false;
  bool _error = false;
  int _shake = 0;

  Future<void> _handle() async {
    if (_loading || widget.onPressed == null) return;
    setState(() {
      _loading = true;
      _success = false;
      _error = false;
    });
    try {
      await widget.onPressed!();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
      await Future<void>.delayed(
        Duration(milliseconds: reduceMotion(context) ? 80 : 420),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
        _shake++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
    if (mounted) {
      setState(() {
        _success = false;
        _error = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PiconButton(
      label: widget.text,
      onPressed: widget.onPressed == null ? null : _handle,
      loading: _loading,
      success: _success,
      error: _error,
      shakeToken: _shake,
    );
  }
}
