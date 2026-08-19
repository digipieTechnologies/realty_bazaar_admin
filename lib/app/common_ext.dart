import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/utils/formatters/currency_formatter.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

final moneyFormatterCommon = NumberFormat.currency(locale: "HI", symbol: "");

extension StringsExtension on String {
  String sCap() {
    if (!isEmptyORNull) {
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    } else {
      return this;
    }
  }

  String lastChars(int n) {
    if (n >= length) {
      return this;
    }
    return substring(length - n);
  }

  String wordCap() {
    return isEmptyORNull
        ? ""
        : toLowerCase()
              .split(' ')
              .map((word) {
                final String leftText = (word.length > 1) ? word.substring(1, word.length) : '';
                if (word.length > 1) {
                  return word[0].toUpperCase() + leftText;
                } else {
                  return word.toUpperCase() + leftText;
                }
              })
              .join(' ');
  }

  String commaCap() {
    return toLowerCase()
        .split(',')
        .map((word) {
          final String leftText = (word.length > 1) ? word.substring(1, word.length) : '';
          if (word.length > 1) {
            return word[0].toUpperCase() + leftText;
          } else {
            return word.toUpperCase() + leftText;
          }
        })
        .join(', ');
  }

  String justifyContent() {
    String newQuery = "";
    final kList = split(" ");
    for (var element in kList) {
      if (element.removeSpaces().isNotEmpty) {
        newQuery += " $element";
      }
    }
    if (newQuery.isEmpty) {
      newQuery = this;
    }
    return newQuery.trim();
  }

  String removeSpaces() => replaceAll(RegExp(r"\s+\b|\b\s"), "");

  bool get isEmptyORNull => isEmpty || removeSpaces().isEmpty;

  int toInt() => int.tryParse(this) ?? 0;

  double toDouble() => double.tryParse(this) ?? 0.0;

  Uri toUri() => Uri.parse(this);

  /// will return count of no of lines from passed string
  int get lines => '\n'.allMatches(this).length + 1;

  String? toMap() {
    var re = RegExp(r'(?<={)(.*)(?=})');
    var match = re.firstMatch(this);
    return match?.group(0);
  }

  String forImage() {
    if (isEmptyORNull) {
      return "";
    }
    final list = split(" ");
    final firstLetter = list[0].substring(0, 1);

    if (list.length >= 2) {
      final lastLetter = list[1].substring(0, 1);
      return (firstLetter + lastLetter).toUpperCase();
    }
    return firstLetter.toUpperCase();
  }

  String get formatted => currencyFormatter.formatString(toString().toDouble().toStringAsFixed(2));

  String get formattedCurrencyL =>
      "$currency${currencyFormatter.formatString(toString().toDouble().toStringAsFixed(2))}";

  String formatIndianCurrency({bool compact = false, bool showSymbol = true, int decimals = 2}) {
    return (double.tryParse(
      this,
    )).formatIndianCurrency(compact: compact, showSymbol: showSymbol, decimals: decimals);
  }

  String get formatCurrency {
    return formatIndianCurrency(compact: false, showSymbol: true);
  }

  Color? toColor() {
    var hexColor = replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }

    return null;
  }

  String substringSafe(int start, [int? end]) {
    String s = this;

    if (end != null && end > s.length) {
      return s.substring(0, s.length);
    }

    if (end != null && end < s.length) {
      return s.substring(0, end);
    }

    return s;
  }

  String get splitFirst {
    final value = split(" ");
    if (value.isEmpty) {
      return this;
    }
    return value.first;
  }

  String get splitLast {
    final value = split(" ");

    if (value.length > 1) {
      value.removeAt(0);
      return value.join(" ");
    }
    if (value.isEmpty) {
      return this;
    }
    return value.first;
  }

  List<String> toCovertList() {
    List<String> userList = [];
    for (int j = 0; j < length; j++) {
      for (int i = j; i < length; i++) {
        final value = substring(j, i + 1);
        userList.add(value.toLowerCase().trim());
      }
    }

    userList = userList.unique((element) => element);
    return userList;
  }

  String get extension => path.extension(this);

  String get urlFileName {
    RegExp regExp = RegExp(r'.+(\/|%2F)(.+)\?.+');
    //This Regex won't work if you remove ?alt...token
    var matches = regExp.allMatches(this);
    var match = matches.elementAt(0);
    return Uri.decodeFull(match.group(2)!);
  }

  String wordCapCode() {
    return isEmptyORNull
        ? ""
        : toLowerCase()
              .split(' ')
              .map((word) {
                if (word.length > 1) {
                  return word[0].toUpperCase();
                } else {
                  return word.toUpperCase();
                }
              })
              .join(' ');
  }

  String? get toFirstName {
    if (trim().isEmpty) return null;
    List<String> list = split(" ");
    return list.firstOrNull?.trim();
  }

  String? get toLastName {
    if (trim().isEmpty) return null;
    List<String> list = split(" ");
    list.removeWhere((element) => element == toFirstName);
    if (list.isEmpty) return null;
    final lastName = list.join(" ");
    return lastName.trim();
  }
}

extension StringsNullExt on String? {
  String get v => (this == null || this == "") ? '' : this!;

  String get na => (this == null || this?.removeSpaces() == "") ? 'NA' : this!;

  String get formatted => currencyFormatter.formatString(toString().toDouble().toStringAsFixed(2));

  String get formattedCurrencyL =>
      "$currency${currencyFormatter.formatString(toString().toDouble().toStringAsFixed(2))}";

  String formatIndianCurrency({bool compact = false, bool showSymbol = true, int decimals = 2}) {
    return (double.tryParse(
      this ?? '',
    )).formatIndianCurrency(compact: compact, showSymbol: showSymbol, decimals: decimals);
  }

  String get formatCurrency {
    return formatIndianCurrency(compact: false, showSymbol: true);
  }
}

extension Duplicates<T> on List<T> {
  void addAllByAvoidingDuplicates(Iterable<T> values) => replaceRange(0, length, {
    ...([...this] + [...values]),
  });

  int get numberOfDuplicates => length - {...this}.length;

  bool get containsDuplicates => numberOfDuplicates > 0;

  List<T> get uniques => [
    ...{...this},
  ];

  void removeDuplicates() => replaceRange(0, length, uniques);

  List<T> get duplicates => [
    for (var i = 0; i < length; i++) [...this].skip(i + 1).contains(this[i]) ? this[i] : null,
  ].whereType<T>().toList();

  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) => fold(
    <K, List<T>>{},
    (Map<K, List<T>> map, T element) => map..putIfAbsent(keyFunction(element), () => <T>[]).add(element),
  );
}

extension NumberExt on num? {
  String get formatted => currencyFormatter.formatString(toString().toDouble().toStringAsFixed(2));

  String get formattedCurrencyL =>
      "$currency${currencyFormatter.formatString(toString().toDouble().toStringAsFixed(2))}";

  String formatIndianCurrency({bool compact = false, bool showSymbol = true, int decimals = 2}) {
    if (this == null) return showSymbol ? '₹ 0' : '0';
    final amount = (this!).toDouble();
    final symbol = showSymbol ? (compact ? '₹' : '₹') : '';

    if (amount >= 10000000) {
      final val = amount / 10000000;
      final formatted = val % 1 == 0 ? val.toStringAsFixed(0) : val.toStringAsFixed(decimals);
      return '$symbol$formatted${compact ? 'Cr' : ' Crore'}';
    } else if (amount >= 100000) {
      final val = amount / 100000;
      final formatted = val % 1 == 0 ? val.toStringAsFixed(0) : val.toStringAsFixed(decimals);
      return '$symbol$formatted${compact ? 'L' : ' Lakh'}';
    } else if (compact && amount >= 1000) {
      final val = amount / 1000;
      final formatted = val % 1 == 0 ? val.toStringAsFixed(0) : val.toStringAsFixed(decimals);
      return '$symbol${formatted}k';
    } else {
      final formatted = moneyFormatterCommon.format(amount);
      return '$symbol$formatted';
    }
  }

  String get formatCurrency {
    return formatIndianCurrency(compact: false, showSymbol: true);
  }

  String get getWithSign => "${(this ?? 0) > 0 ? "+" : ""}$this";

  Color differenceColor(BuildContext context) {
    final qty = this ?? 0;
    if (qty < 0) {
      return context.errorColor;
    }
    if (qty > 0) {
      return context.successColor;
    }
    return context.colorScheme.onSurface.withValues(alpha: 0.6);
  }

  bool get isInteger => this != null && this is int || this == this!.roundToDouble();

  String get toQty {
    var qty = this ?? 0;
    String viewQty = toString();
    if (isInteger) {
      viewQty = (qty >= 0 ? qty : 0).toInt().toString();
    } else {
      viewQty = (qty >= 0 ? qty : 0).toInt().toStringAsFixed(2);
    }

    return viewQty;
  }
}

extension DoubletExtension on double {
  int toInt() {
    return int.parse(toString());
  }

  String get formatInKm {
    if (this < 1) {
      return "${(this * 1000).toStringAsFixed(0)} meters";
    }

    final value = toStringAsFixed(2).split(".");

    if (value.isNotEmpty) {
      if (value.length >= 2) {
        if (value[1].toInt() <= 00) {
          return "${value[0]} kms";
        }
      }
    }

    return "${toStringAsFixed(2)} kms";
  }

  String get formatInKmShort {
    if (this < 1) {
      return "${(this * 1000).toStringAsFixed(0)} mt";
    }

    final value = toStringAsFixed(2).split(".");

    if (value.isNotEmpty) {
      if (value.length >= 2) {
        if (value[1].toInt() <= 00) {
          return "${value[0]} km";
        }
      }
    }

    return "${toStringAsFixed(2)} km";
  }

  String get formatInMl =>
      this < 1 ? "${(this * 1609.344).toStringAsFixed(2)} meters" : "${toStringAsFixed(2)} ml";

  double get nonNegative => this > 0 ? this : 0;
}

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <dynamic>{};
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

extension DateTimeX on DateTime {
  /// if is isCountNewYear is true then return 1st week of new year other wise return 53th week of current year/date.
  int getWeekNumber({bool isCountNewYear = false}) {
    final firstDayOfYear = DateTime(year, 1, 1);

    final daysSinceFirstDay = difference(firstDayOfYear).inDays;

    final mondayOffset = (firstDayOfYear.weekday - DateTime.sunday) % 7;

    final totalDays = daysSinceFirstDay + mondayOffset;

    final number = (totalDays / 7).ceil();
    if (number >= 53 && isCountNewYear) {
      return 1;
    }
    return number;
  }

  String humanReadableTime() {
    return DateFormat('dd MMM, hh:mm a').format(toLocal());
  }

  DateTime get date {
    var now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today;
  }

  DateTime get midnight {
    return DateTime(year, month, day, 0, 0);
  }

  DateTime get yesTerDayMidNight {
    return DateTime(year, month, day - 1, 0, 0);
  }
}

extension ColorX on Color? {
  String? get toColorCode =>
      this == null ? null : '#${this!.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
