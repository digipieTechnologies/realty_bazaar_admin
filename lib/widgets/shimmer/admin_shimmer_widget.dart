// File: lib/widgets/shimmer/admin_shimmer_widget.dart
// Purpose: Full-screen loading shimmer widget for dashboard and content screens.

import 'package:flutter/material.dart';

import 'app_shimmer_container.dart';

class AdminShimmerWidget extends StatelessWidget {
  const AdminShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppShimmerContainer(width: 200, height: 28),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: AppShimmerContainer(width: double.infinity, height: 110, borderRadius: 16)),
              SizedBox(width: 16),
              Expanded(child: AppShimmerContainer(width: double.infinity, height: 110, borderRadius: 16)),
              SizedBox(width: 16),
              Expanded(child: AppShimmerContainer(width: double.infinity, height: 110, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 32),
          const Expanded(
            child: AppShimmerContainer(width: double.infinity, height: double.infinity, borderRadius: 16),
          ),
        ],
      ),
    );
  }
}
