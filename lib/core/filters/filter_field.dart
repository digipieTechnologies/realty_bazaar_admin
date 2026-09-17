import 'package:flutter/widgets.dart';

enum FilterType {
  search,
  status,
  dateRange,
  singleSelect,
  multiSelect,
  numberRange,
  priceRange,
  rangeSlider,
  boolean,
  sortBy,
  quickFilter,
}

class FilterOption {
  final dynamic value;
  final String labelKey; // Translation key
  final bool isPlainLabel; // If true, display labelKey directly without translating it.

  const FilterOption({required this.value, required this.labelKey, this.isPlainLabel = false});
}

class FilterField {
  final String key;
  final FilterType type;
  final String labelKey; // Translation key
  final dynamic defaultValue;
  final List<FilterOption>? staticOptions;
  final Future<List<FilterOption>> Function(BuildContext)? dynamicOptionsResolver;
  final Future<List<FilterOption>> Function(BuildContext, String)? dynamicSearchResolver;

  final String? hintText;
  final bool isAdvanced;
  final bool isQuickFilter;

  // Range configurations
  final double? min;
  final double? max;

  const FilterField({
    required this.key,
    required this.type,
    required this.labelKey,
    this.hintText,
    this.defaultValue,
    this.staticOptions,
    this.dynamicOptionsResolver,
    this.dynamicSearchResolver,
    this.isAdvanced = false,
    this.isQuickFilter = false,
    this.min,
    this.max,
  });
}

class FilterDefinition {
  final List<FilterField> fields;
  final String defaultSortBy;
  final String defaultSortOrder;

  const FilterDefinition({required this.fields, required this.defaultSortBy, this.defaultSortOrder = 'desc'});
}
