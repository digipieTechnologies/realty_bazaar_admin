import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../app/app_colors.dart';
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
    this.plan,
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
      plan: json['plan']?.toString() ?? 'Free',
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
    data['plan'] = plan;
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
      plan: plan ?? this.plan,
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
    plan,
    onboardingStatus,
    isActive,
    autoApproveVideoRequests,
    addressId,
    createdAt,
    updatedAt,
  ];

  Widget avatarImage({double radius = 16, double iconSize = 18}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
      child: Icon(Icons.business_rounded, color: AppColors.secondary, size: iconSize),
    );
  }
}
