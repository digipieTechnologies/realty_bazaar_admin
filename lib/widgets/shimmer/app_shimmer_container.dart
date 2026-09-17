// File: lib/widgets/shimmer/app_shimmer_container.dart
// Purpose: Placeholder shimmer effect container for loading states.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/app_colors.dart';

class AppShimmerContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmerContainer({super.key, required this.width, required this.height, this.borderRadius = 8.0});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
