// File: lib/models/user_model.dart
// Purpose: Strongly typed UserModel with Gender enum, Date of Birth, Notes, and Cover Image fields.

import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/widgets/images/cached_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/enums/gender_enum.dart';
import 'attachment_model.dart';
import 'broker_model.dart';
import 'user_role.dart';

class UserModel extends Equatable {
  static String tableName = "users";

  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? phoneCountryCode;
  final String? phoneCountryIso;
  final UserRole role;
  final Gender gender;
  final DateTime? dob;
  final String? notes;
  final AttachmentModel? coverImage;
  final bool? isActive;
  final bool? isDeleted;
  final BrokerModel? broker;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;

  const UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.phoneCountryCode = '91',
    this.phoneCountryIso = 'IN',
    this.role = UserRole.broker,
    this.gender = Gender.male,
    this.dob,
    this.notes,
    this.coverImage,
    this.isActive,
    this.isDeleted,
    this.broker,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  static UserModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return UserModel(id: json?.toString());
    }

    final parsedCoverImage = json['cover_image'] != null
        ? AttachmentModel.fromJson(json['cover_image'])
        : null;

    return UserModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      phoneCountryCode: json['phone_country_code']?.toString() ?? '91',
      phoneCountryIso: json['phone_country_iso']?.toString() ?? 'IN',
      role: json['role']?.toString().asUserRole ?? UserRole.broker,
      gender: (json['gender']?.toString()).asGender,
      dob: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'].toString())
          : (json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null),
      notes: json['notes']?.toString(),
      coverImage: parsedCoverImage,
      isActive: json['is_active'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      broker: json['broker_id'] != null ? BrokerModel.fromJson(json['broker_id']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['phone'] = phone;
    data['phone_country_code'] = phoneCountryCode ?? '91';
    data['phone_country_iso'] = phoneCountryIso ?? 'IN';
    data['role'] = role.apiValue;
    data['gender'] = gender.apiValue;
    if (dob != null) {
      data['date_of_birth'] = DateFormat('yyyy-MM-dd').format(dob!);
    }
    if (notes != null) data['notes'] = notes;
    if (coverImage != null) data['cover_image'] = coverImage!.toJson();
    data['is_active'] = isActive;
    data['is_deleted'] = isDeleted;
    data['broker_id'] = broker?.id;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    return data;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? phoneCountryCode,
    String? phoneCountryIso,
    UserRole? role,
    Gender? gender,
    DateTime? dob,
    String? notes,
    AttachmentModel? coverImage,
    bool? isActive,
    bool? isDeleted,
    BrokerModel? brokerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneCountryIso: phoneCountryIso ?? this.phoneCountryIso,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      notes: notes ?? this.notes,
      coverImage: coverImage ?? this.coverImage,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      broker: brokerId ?? this.broker,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDob {
    if (dob == null) return '-';
    return DateFormat('dd MMM yyyy').format(dob!);
  }

  int? get ageInYears {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob!.year;
    if (now.month < dob!.month || (now.month == dob!.month && now.day < dob!.day)) {
      age--;
    }
    return age;
  }

  String get initials {
    if (name == null || name!.isEmpty) return '';
    final parts = name!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
  }

  Widget avatarImage({required BuildContext context, double width = 48, double height = 48}) {
    final colorScheme = Theme.of(context).colorScheme;
    return CachedImage(
      width: width,
      height: height,
      imageUrl: coverImage?.url ?? imageUrl,
      borderRadius: BorderRadius.circular(12),
      backgroundColor: colorScheme.surface,
      borderColor: colorScheme.outlineVariant.withValues(alpha: 0.6),
      errorWidget: (ctx) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            initials,
            style: context.labelSmallBold?.copyWith(
              fontSize: (width + height) * 0.18,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    phoneCountryCode,
    phoneCountryIso,
    role,
    gender,
    dob,
    notes,
    coverImage,
    isActive,
    isDeleted,
    broker,
    createdAt,
    updatedAt,
  ];
}
