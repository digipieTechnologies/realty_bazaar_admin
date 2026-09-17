import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/widgets/common/cached_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../app/context_ext.dart';
import 'address_model.dart';

class BrokerModel extends Equatable {
  static String tableName = "brokers";

  final String? id;
  final String? businessName;
  final String? plan;
  final String? onboardingStatus;
  final bool? isActive;
  final bool? autoApproveVideoRequests;
  final AddressModel? addressId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BrokerModel({
    this.id,
    this.businessName,
    this.plan = "Free",
    this.onboardingStatus,
    this.isActive,
    this.autoApproveVideoRequests,
    this.addressId,
    this.createdAt,
    this.updatedAt,
  });

  static BrokerModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return BrokerModel(id: json?.toString());
    }
    return BrokerModel(
      id: json['id']?.toString(),
      businessName: json['business_name']?.toString() ?? '',
      onboardingStatus: json['onboarding_status']?.toString() ?? 'pending',
      isActive: json['is_active'] as bool? ?? true,
      autoApproveVideoRequests:
          (json['auto_approve_video_requests'] ?? json['auto_approve_video_request']) as bool? ?? false,
      addressId: json['address_id'] != null ? AddressModel.fromJson(json['address_id']) : null,
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
    data['business_name'] = businessName;
    data['onboarding_status'] = onboardingStatus;
    data['is_active'] = isActive;
    data['auto_approve_video_requests'] = autoApproveVideoRequests;
    data['address_id'] = addressId?.id;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    return data;
  }

  BrokerModel copyWith({
    String? id,
    String? businessName,
    String? plan,
    String? onboardingStatus,
    bool? isActive,
    bool? autoApproveVideoRequests,
    AddressModel? addressId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrokerModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      isActive: isActive ?? this.isActive,
      autoApproveVideoRequests: autoApproveVideoRequests ?? this.autoApproveVideoRequests,
      addressId: addressId ?? this.addressId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    businessName,
    onboardingStatus,
    isActive,
    autoApproveVideoRequests,
    addressId,
    createdAt,
    updatedAt,
  ];

  Widget avatarImage({
    required BuildContext context,
    double width = 48,
    double height = 48,
    String? imageUrl,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return CachedImage(
      width: width,
      height: height,
      imageUrl: imageUrl,
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
            businessName?.forImage ?? '',
            style: context.labelSmallBold?.copyWith(
              fontSize: (width + height) * 0.18,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
