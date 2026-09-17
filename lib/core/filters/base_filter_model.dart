import 'package:equatable/equatable.dart';

abstract class BaseFilterModel extends Equatable {
  const BaseFilterModel();

  /// Converts the filter state into a JSON-serializable map.
  Map<String, dynamic> toJson();

  /// Creates a copy of the filter model using the updated map of values.
  BaseFilterModel copyWithMap(Map<String, dynamic> map);

  /// Checks if any filter is active (usually ignoring pagination/sorting).
  bool get hasActiveFilters;

  /// Resets all filters to their default values (preserving pagination defaults).
  BaseFilterModel reset();
}
