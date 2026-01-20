import 'dart:math';
import 'package:flutter/material.dart';
import 'package:photo_app/utils/colors.dart';

class GeometricBackground extends StatelessWidget {
  const GeometricBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        Positioned(
          top: -120,
          left: -120,
          child: Transform.rotate(
            angle: -pi / 4,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.9), // Darker rotated square for depth effect top left
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          right: -100,
          child: CircleAvatar(
            radius: 180,
            backgroundColor: AppColors.primary.withOpacity(0.2), // Large faded circle for depth effect bottom right
          ),
        ),
         Positioned(
          top: 200,
          right: -50,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withOpacity(0.3), // Lighter circle for depth effect right
          ),
        ),

        Positioned(
          top: 200,
          left: -80,
          child: Transform.rotate(
            angle: pi / 6,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
         Positioned(
          bottom: 150,
          left: -40,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.3), // Lighter circle for depth effect left
          ),
        ),

        // Positioned(
        //   top: 100,
        //   left: -30,
        //   child: Transform.rotate(
        //     angle: pi / 6,
        //     child: Container(
        //       width: 100,
        //       height: 100,
        //       decoration: BoxDecoration(
        //         color: AppColors.primary.withOpacity(0.8),
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //     ),
        //   ),
        // )


      ],
    );
  }
}
