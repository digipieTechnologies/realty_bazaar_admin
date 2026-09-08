// File: lib/widgets/dividers/app_divider.dart
// Purpose: Standardized divider line for layouts.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class AppDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;

  const AppDivider({super.key, this.height = 1.0, this.thickness = 1.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(height: height, thickness: thickness, color: color ?? AppColors.divider);
  }
}
