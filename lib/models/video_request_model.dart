import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'marketing_team_model.dart';
import 'property_model.dart';
import 'user_model.dart';
import 'video_request_enums.dart';

class VideoRequestModel extends Equatable {
  static String tableName = "video_requests";

  final String? id;
  final PropertyModel? property;
  final BrokerModel? broker;
  final String? marketingTeamId;
  final MarketingTeamModel? marketingTeam;
  final String? primaryMarketingUserId;
  final UserModel? primaryMarketingUser;
  final VideoRequestStatus status;
  final VideoRequestApprovalStatus adminApprovalStatus;
  final String? notes;
  final String? cancelReason;
  final String? adminCancelReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const VideoRequestModel({
    this.id,
    this.property,
    this.broker,
    this.marketingTeamId,
    this.marketingTeam,
    this.primaryMarketingUserId,
    this.primaryMarketingUser,
    this.status = VideoRequestStatus.pending,
    this.adminApprovalStatus = VideoRequestApprovalStatus.pending,
    this.notes,
    this.cancelReason,
    this.adminCancelReason,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  MarketingTeamModel? get effectiveMarketingTeam => marketingTeam ?? broker?.marketingTeam;

  UserModel? get effectivePrimaryRep => primaryMarketingUser ?? broker?.primaryMarketingUser;

  static VideoRequestModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return VideoRequestModel(id: json?.toString());
    }

    MarketingTeamModel? parsedTeam;
    if (json['marketing_team'] != null) {
      parsedTeam = MarketingTeamModel.fromJson(json['marketing_team']);
    } else if (json['marketing_team_id'] != null && json['marketing_team_id'] is Map) {
      parsedTeam = MarketingTeamModel.fromJson(json['marketing_team_id']);
    }

    UserModel? parsedUser;
    if (json['primary_marketing_user'] != null) {
      parsedUser = UserModel.fromJson(json['primary_marketing_user']);
    } else if (json['primary_marketing_user_id'] != null && json['primary_marketing_user_id'] is Map) {
      parsedUser = UserModel.fromJson(json['primary_marketing_user_id']);
    }

    return VideoRequestModel(
      id: json['id']?.toString(),
      property: json['property_id'] != null ? PropertyModel.fromJson(json['property_id']) : null,
      broker: json['broker_id'] != null ? BrokerModel.fromJson(json['broker_id']) : null,
      marketingTeamId: (json['marketing_team_id'] is Map)
          ? json['marketing_team_id']['id']?.toString()
          : json['marketing_team_id']?.toString() ?? parsedTeam?.id,
      marketingTeam: parsedTeam,
      primaryMarketingUserId: (json['primary_marketing_user_id'] is Map)
          ? json['primary_marketing_user_id']['id']?.toString()
          : json['primary_marketing_user_id']?.toString() ?? parsedUser?.id,
      primaryMarketingUser: parsedUser,
      status: json['status']?.toString().asVideoRequestStatus ?? VideoRequestStatus.pending,
      adminApprovalStatus:
          json['admin_approval_status']?.toString().asVideoRequestApprovalStatus ??
          VideoRequestApprovalStatus.pending,
      notes: json['notes']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
      adminCancelReason: json['admin_cancel_reason']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    if (property != null) data['property_id'] = property!.id;
    if (broker != null) data['broker_id'] = broker!.id;
    if (marketingTeamId != null) data['marketing_team_id'] = marketingTeamId;
    if (primaryMarketingUserId != null) {
      data['primary_marketing_user_id'] = primaryMarketingUserId;
    }
    data['status'] = status.apiValue;
    data['admin_approval_status'] = adminApprovalStatus.apiValue;
    if (notes != null) data['notes'] = notes;
    if (cancelReason != null) data['cancel_reason'] = cancelReason;
    if (adminCancelReason != null) data['admin_cancel_reason'] = adminCancelReason;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    if (completedAt != null) {
      data['completed_at'] = completedAt?.toUtc().toIso8601String();
    }
    return data;
  }

  VideoRequestModel copyWith({
    String? id,
    PropertyModel? property,
    BrokerModel? broker,
    String? marketingTeamId,
    MarketingTeamModel? marketingTeam,
    String? primaryMarketingUserId,
    UserModel? primaryMarketingUser,
    VideoRequestStatus? status,
    VideoRequestApprovalStatus? adminApprovalStatus,
    String? notes,
    String? cancelReason,
    String? adminCancelReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return VideoRequestModel(
      id: id ?? this.id,
      property: property ?? this.property,
      broker: broker ?? this.broker,
      marketingTeamId: marketingTeamId ?? this.marketingTeamId,
      marketingTeam: marketingTeam ?? this.marketingTeam,
      primaryMarketingUserId: primaryMarketingUserId ?? this.primaryMarketingUserId,
      primaryMarketingUser: primaryMarketingUser ?? this.primaryMarketingUser,
      status: status ?? this.status,
      adminApprovalStatus: adminApprovalStatus ?? this.adminApprovalStatus,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
      adminCancelReason: adminCancelReason ?? this.adminCancelReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    property,
    broker,
    marketingTeamId,
    marketingTeam,
    primaryMarketingUserId,
    primaryMarketingUser,
    status,
    adminApprovalStatus,
    notes,
    cancelReason,
    adminCancelReason,
    createdAt,
    updatedAt,
    completedAt,
  ];
}
