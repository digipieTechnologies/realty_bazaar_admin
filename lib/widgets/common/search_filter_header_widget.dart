// File: lib/widgets/common/search_filter_header_widget.dart
// Purpose: Reusable search input & filter action header toolbar.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class SearchFilterHeaderWidget extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onSearchChanged;
  final Widget? actionButton;
  final Widget? filterDropdown;

  const SearchFilterHeaderWidget({
    super.key,
    this.hintText = 'Search...',
    this.onSearchChanged,
    this.actionButton,
    this.filterDropdown,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  hintText: hintText,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18.0, color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          if (filterDropdown != null) ...[const SizedBox(width: 12.0), filterDropdown!],
          if (actionButton != null) ...[const SizedBox(width: 12.0), actionButton!],
        ],
      ),
    );
  }
}
