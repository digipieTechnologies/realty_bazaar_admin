import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';
import 'api_exception.dart';
import 'pagination_model.dart';

abstract class BaseSupabaseService {
  final SupabaseClient supabase = SupabaseConfig.client;

  /// Helper to handle standard paginated queries
  Future<PaginatedResponse<T>> getPaginated<T>({
    required String table,
    required String select,
    required T Function(Map<String, dynamic>) fromJson,
    int? page,
    int? pageSize,
    Map<String, dynamic>? filters,
    String? searchField,
    String? searchQuery,
    String? sortBy,
    bool ascending = false,
  }) async {
    try {
      var query = supabase.from(table).select(select);

      // Apply Filters
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            if (value is List) {
              query = query.inFilter(key, value);
            } else if (value is Map<String, dynamic>) {
              value.forEach((operator, opValue) {
                switch (operator) {
                  case 'gte':
                    query = query.gte(key, opValue);
                    break;
                  case 'lte':
                    query = query.lte(key, opValue);
                    break;
                  case 'gt':
                    query = query.gt(key, opValue);
                    break;
                  case 'lt':
                    query = query.lt(key, opValue);
                    break;
                  case 'neq':
                    query = query.neq(key, opValue);
                    break;
                  default:
                    query = query.eq(key, value);
                }
              });
            } else {
              query = query.eq(key, value);
            }
          }
        });
      }

      // Search - tokenize searchQuery into individual terms and apply ilike for each on search_text (accelerated by pg_trgm GIN index)
      if (searchField != null && searchQuery != null && searchQuery.trim().isNotEmpty) {
        if (searchField == 'fts' || searchField.contains('vector')) {
          final formattedTerms = searchQuery
              .trim()
              .toLowerCase()
              .split(RegExp(r'\s+'))
              .where((t) => t.isNotEmpty)
              .map((t) => '$t:*')
              .join(' & ');
          query = query.textSearch(searchField, formattedTerms, config: 'simple');
        } else {
          final terms = searchQuery.trim().toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
          for (final term in terms) {
            query = query.ilike(searchField, '%$term%');
          }
        }
      }

      // Pagination
      final p = page ?? 1;
      final ps = pageSize ?? 20;
      final from = (p - 1) * ps;
      final to = from + ps - 1;

      // Execute query with count - call order/range first, then count
      final response = await query
          .order(sortBy ?? 'created_at', ascending: ascending)
          .range(from, to)
          .count(CountOption.exact);

      final List<dynamic> data = response.data as List<dynamic>;
      final int total = response.count;
      final totalPages = (total / ps).ceil();

      return PaginatedResponse(
        items: data.map((json) => fromJson(json as Map<String, dynamic>)).toList(),
        pagination: PaginationMetadata(page: p, pageSize: ps, total: total, totalPages: totalPages),
      );
    } catch (e) {
      throw ApiException('Database error in $table: $e');
    }
  }

  ApiException handleException(dynamic e, String message) {
    if (e is PostgrestException) {
      return ApiException(e.message, code: int.tryParse(e.code ?? '500'));
    }
    if (e is AuthException) {
      return ApiException(e.message);
    }
    return ApiException('$message: $e');
  }
}
