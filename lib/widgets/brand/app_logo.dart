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
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(size * 0.25)),
      child: Image.asset('assets/logo/app_logo_transparent.png', fit: BoxFit.contain, color: Colors.white),
    );
  }
}

class CustomAppLogo extends StatelessWidget {
  final double width;
  final double height;
  final BoxDecoration? decoration;
  final Color? logoColor;

  const CustomAppLogo({
    super.key,
    required this.width,
    required this.height,
    this.decoration,
    this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration:
          decoration ??
          BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(width * 0.25)),
      child: Image.asset(
        'assets/logo/app_logo_transparent.png',
        fit: BoxFit.contain,
        color: logoColor ?? Colors.white,
      ),
    );
  }
}
