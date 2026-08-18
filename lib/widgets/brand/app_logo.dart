// File: lib/widgets/brand/app_logo.dart
// Purpose: Reusable logo widget mirroring brokerflow-app.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 40.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.apartment_rounded, color: Colors.white, size: size * 0.55),
      ),
    );
  }
}
