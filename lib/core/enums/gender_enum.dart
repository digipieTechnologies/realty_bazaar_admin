// File: lib/core/enums/gender_enum.dart
// Purpose: Gender enum with default fallback to male, DB api values, and icons.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum Gender { male, female, transgender }

extension GenderParser on String? {
  Gender get asGender {
    switch (this?.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'transgender':
        return Gender.transgender;
      default:
        return Gender.male;
    }
  }
}

extension GenderHelpers on Gender {
  String displayName(BuildContext context) {
    switch (this) {
      case Gender.male:
        return 'gender_male'.tr();
      case Gender.female:
        return 'gender_female'.tr();
      case Gender.transgender:
        return 'gender_transgender'.tr();
    }
  }

  String get apiValue {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.transgender:
        return 'transgender';
    }
  }

  IconData get icon {
    switch (this) {
      case Gender.male:
        return Icons.male_rounded;
      case Gender.female:
        return Icons.female_rounded;
      case Gender.transgender:
        return Icons.transgender_rounded;
    }
  }
}
