import 'package:supabase_flutter/supabase_flutter.dart';

import 'base_filter_model.dart';
import 'filter_field.dart';

class SupabaseQueryBuilder {
  /// Dynamically applies the filter values to a Supabase query builder.
  static PostgrestFilterBuilder apply({
    required PostgrestFilterBuilder query,
    required BaseFilterModel filter,
    required FilterDefinition definition,
    PostgrestFilterBuilder Function(PostgrestFilterBuilder query, String key, dynamic value)? customMapper,
    List<String> ignoreKeys = const [],
  }) {
    var q = query;
    final map = filter.toJson();

    map.forEach((key, value) {
      if (value == null) return;

      // Skip ignored keys
      if (ignoreKeys.contains(key)) {
        return;
      }

      // Skip pagination and sorting fields from direct DB filtering
      if (key == 'page' || key == 'pageSize' || key == 'sortBy' || key == 'sortOrder') {
        return;
      }

      // Delegate custom fields to the provided mapper if it handles it
      bool handled = false;
      if (customMapper != null) {
        final previousQ = q;
        final newQ = customMapper(q, key, value);
        if (newQ != previousQ) {
          q = newQ;
          handled = true;
        }
      }

      if (handled) return;

      // Standard filter mappings
      final field = definition.fields.firstWhere(
        (f) => f.key == key,
        orElse: () => FilterField(key: key, type: FilterType.singleSelect, labelKey: ''),
      );

      switch (field.type) {
        case FilterType.multiSelect:
          if (value is List && value.isNotEmpty) {
            q = q.inFilter(key, value);
          }
          break;
        case FilterType.boolean:
          if (value is bool) {
            q = q.eq(key, value);
          }
          break;
        case FilterType.numberRange:
        case FilterType.priceRange:
          if (value is Map<String, dynamic>) {
            if (value['gte'] != null) q = q.gte(key, value['gte']);
            if (value['lte'] != null) q = q.lte(key, value['lte']);
          }
          break;
        default:
          q = q.eq(key, value);
          break;
      }
    });

    return q;
  }
}
