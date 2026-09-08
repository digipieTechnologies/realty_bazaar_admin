import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/filters/filter_field.dart';
import '../../core/filters/filter_provider.dart';

class EnterpriseQuickFilters extends StatelessWidget {
  final FilterProvider provider;
  final List<FilterField> fields;
  final bool isMobile;

  const EnterpriseQuickFilters({
    super.key,
    required this.provider,
    required this.fields,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<FilterProvider>(
        builder: (context, provider, child) {
          final activeMap = provider.activeFilters.toJson();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 1, vertical: 8),
            child: Row(
              spacing: 8.0,
              children: fields.map((field) {
                final isSelected = activeMap[field.key] == true;
                return FilterChip(
                  label: Text(field.labelKey.tr()),
                  selected: isSelected,
                  color: WidgetStatePropertyAll(isSelected ? Theme.of(context).colorScheme.primary : null),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (selected) {
                    // Instantly update and apply the quick filter
                    for (final f in fields) {
                      provider.updateDraftValue(f.key, null);
                    }
                    if (selected) {
                      provider.updateDraftValue(field.key, true);
                    }
                    provider.apply();
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
