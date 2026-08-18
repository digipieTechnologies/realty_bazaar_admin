import 'package:intl/intl.dart';

/// Cached DateFormat provider to optimize performance by reusing instances.
/// Recreating DateFormat instances in build methods causes unnecessary allocations
/// and can slow down list rendering significantly.
class DateFormatter {
  // Cache to store DateFormat instances by pattern and locale
  static final Map<String, DateFormat> _cache = {};

  /// Get a cached DateFormat instance for the given pattern and locale
  static DateFormat getFormat(String pattern, [String? locale]) {
    final activeLocale = locale ?? Intl.defaultLocale ?? 'en_US';
    final key = '${pattern}_$activeLocale';

    return _cache.putIfAbsent(key, () => DateFormat(pattern, activeLocale));
  }

  /// Helper for yMMMd format (e.g., "Jan 1, 2024")
  static DateFormat get yMMMd => getFormat(DateFormat.YEAR_ABBR_MONTH_DAY);

  /// Helper for yMMMMd format (e.g., "January 1, 2024")
  static DateFormat get yMMMMd => getFormat(DateFormat.YEAR_MONTH_DAY);

  /// Helper for yMMMMd_jm format (e.g., "January 1, 2024 5:00 PM")
  static DateFormat get yMMMMdJm {
    final activeLocale = Intl.defaultLocale ?? 'en_US';
    final key = 'yMMMMdJm_$activeLocale';
    return _cache.putIfAbsent(key, () => DateFormat.yMMMMd(activeLocale).add_jm());
  }

  /// Helper for yyyyMMdd format (e.g., "2024-01-01"))
  static DateFormat get yyyyMMdd => getFormat(DateFormat.YEAR_NUM_MONTH_DAY);

  static DateFormat get yMMMdJm {
    final activeLocale = Intl.defaultLocale ?? 'en_US';
    final key = 'yMMMdJm_$activeLocale';
    return _cache.putIfAbsent(key, () => DateFormat.yMMMd(activeLocale).add_jm());
  }

  /// Clear the cache (useful when changing app language)
  static void clearCache() {
    _cache.clear();
  }
}
