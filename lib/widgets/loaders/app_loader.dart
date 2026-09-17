// File: lib/widgets/loaders/app_loader.dart
// Purpose: Unified loading indicator mirroring brokerflow-app.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoader({super.key, this.size = 24.0, this.color, this.strokeWidth = 2.5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
      ),
    );
  }
}
