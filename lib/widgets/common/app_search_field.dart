import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppSearchField extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String> onSearch;
  final Duration debounceDuration;
  final TextEditingController? controller;

  const AppSearchField({
    super.key,
    this.hintText,
    required this.onSearch,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.controller,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearch(value.trim());
    });
  }

  void _onClear() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surface,
        hintText: widget.hintText ?? 'search_placeholder'.tr(),
        prefixIcon: Icon(Icons.search_outlined, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(CupertinoIcons.xmark_circle, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
              onPressed: _onClear,
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class AppSearchBar extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String> onSearch;
  final bool isMobile;
  final String? addLabel;
  final VoidCallback? onAdd;
  final TextEditingController? controller;
  final VoidCallback? onFilter;
  final int activeFilterCount;

  const AppSearchBar({
    super.key,
    required this.onSearch,
    this.isMobile = true,
    this.hintText,
    this.onAdd,
    this.addLabel,
    this.controller,
    this.onFilter,
    this.activeFilterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: AppSearchField(controller: controller, hintText: hintText, onSearch: onSearch),
        ),
        if (onFilter != null) ...[
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: activeFilterCount > 0,
            label: Text('$activeFilterCount'),
            child: IconButton(
              onPressed: onFilter,
              icon: const Icon(Icons.filter_list),
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: colorScheme.surfaceContainerHigh,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
        ],
        if (onAdd != null) ...[
          const SizedBox(width: 8),
          if (isMobile || addLabel == null)
            IconButton(
              onPressed: onAdd,
              icon: Icon(Icons.add, size: 24, color: colorScheme.onPrimary),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            FilledButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add, size: 18, color: colorScheme.onPrimary),
              label: Text(addLabel!),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ],
    );
  }
}
