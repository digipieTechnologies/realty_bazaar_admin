import 'package:realty_bazaar_admin/app/common_ext.dart';
import 'package:realty_bazaar_admin/widgets/common/cached_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../app/context_ext.dart';
import 'address_model.dart';
import 'marketing_team_model.dart';
import 'user_model.dart';

class BrokerModel extends Equatable {
  static String tableName = "brokers";

  final String? id;
  final String? businessName;
  final String? plan;
  final String? onboardingStatus;
  final bool? isActive;
  final bool? autoApproveVideoRequests;
  final AddressModel? addressId;
  final String? marketingTeamId;
  final MarketingTeamModel? marketingTeam;
  final String? primaryMarketingUserId;
  final UserModel? primaryMarketingUser;
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
    this.marketingTeamId,
    this.marketingTeam,
    this.primaryMarketingUserId,
    this.primaryMarketingUser,
    this.createdAt,
    this.updatedAt,
  });

  static BrokerModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return BrokerModel(id: json?.toString());
    }
    MarketingTeamModel? parsedTeam;
    String? teamId;
    if (json['marketing_team'] != null && json['marketing_team'] is Map) {
      parsedTeam = MarketingTeamModel.fromJson(Map<String, dynamic>.from(json['marketing_team'] as Map));
      teamId = parsedTeam.id;
    } else if (json['marketing_team_id'] != null && json['marketing_team_id'] is Map) {
      parsedTeam = MarketingTeamModel.fromJson(Map<String, dynamic>.from(json['marketing_team_id'] as Map));
      teamId = parsedTeam.id;
    }
    teamId ??= (json['marketing_team_id'] is String) ? json['marketing_team_id'] as String : json['marketing_team_id']?.toString();

    UserModel? parsedPrimaryUser;
    String? primaryUserId;
    if (json['primary_marketing_user'] != null && json['primary_marketing_user'] is Map) {
      parsedPrimaryUser = UserModel.fromJson(Map<String, dynamic>.from(json['primary_marketing_user'] as Map));
      primaryUserId = parsedPrimaryUser.id;
    } else if (json['primary_marketing_user_id'] != null && json['primary_marketing_user_id'] is Map) {
      parsedPrimaryUser = UserModel.fromJson(Map<String, dynamic>.from(json['primary_marketing_user_id'] as Map));
      primaryUserId = parsedPrimaryUser.id;
    }
    primaryUserId ??= (json['primary_marketing_user_id'] is String) ? json['primary_marketing_user_id'] as String : json['primary_marketing_user_id']?.toString();

    return BrokerModel(
      id: json['id']?.toString(),
      businessName: json['business_name']?.toString() ?? '',
      onboardingStatus: json['onboarding_status']?.toString() ?? 'pending',
      isActive: json['is_active'] as bool? ?? true,
      autoApproveVideoRequests:
          (json['auto_approve_video_requests'] ?? json['auto_approve_video_request']) as bool? ?? false,
      addressId: json['address_id'] != null
          ? AddressModel.fromJson(json['address_id'])
          : (json['address'] != null ? AddressModel.fromJson(json['address']) : null),
      marketingTeamId: teamId,
      marketingTeam: parsedTeam,
      primaryMarketingUserId: primaryUserId,
      primaryMarketingUser: parsedPrimaryUser,
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
    if (marketingTeamId != null) data['marketing_team_id'] = marketingTeamId;
    if (primaryMarketingUserId != null) {
      data['primary_marketing_user_id'] = primaryMarketingUserId;
    }
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
    String? marketingTeamId,
    MarketingTeamModel? marketingTeam,
    String? primaryMarketingUserId,
    UserModel? primaryMarketingUser,
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
      marketingTeamId: marketingTeamId ?? this.marketingTeamId,
      marketingTeam: marketingTeam ?? this.marketingTeam,
      primaryMarketingUserId: primaryMarketingUserId ?? this.primaryMarketingUserId,
      primaryMarketingUser: primaryMarketingUser ?? this.primaryMarketingUser,
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
    marketingTeamId,
    marketingTeam,
    primaryMarketingUserId,
    primaryMarketingUser,
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
