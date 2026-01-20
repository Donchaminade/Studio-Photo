import 'package:flutter/material.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/music_wave_loader.dart';

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
  void _handlePress() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _handlePress,
        child: Text(widget.text),
      ),
    );
  }
}
