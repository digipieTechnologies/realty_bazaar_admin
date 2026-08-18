import 'package:equatable/equatable.dart';

class SocialAccountModel extends Equatable {
  static String tableName = "social_accounts";

  final String? id;
  final String? brokerId;
  final String? platform;
  final String? accountName;
  final String? accountId;
  final bool? isConnected;
  final int? followersCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SocialAccountModel({
    this.id,
    this.brokerId,
    this.platform,
    this.accountName,
    this.accountId,
    this.isConnected,
    this.followersCount,
    this.createdAt,
    this.updatedAt,
  });

  static SocialAccountModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return SocialAccountModel(id: json?.toString());
    }
    return SocialAccountModel(
      id: json['id']?.toString(),
      brokerId: json['broker_id']?.toString(),
      platform: json['platform']?.toString() ?? 'Instagram',
      accountName: json['account_name']?.toString() ?? '',
      accountId: json['account_id']?.toString() ?? '',
      isConnected: json['is_connected'] as bool? ?? true,
      followersCount: int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
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
    data['broker_id'] = brokerId;
    data['platform'] = platform;
    data['account_name'] = accountName;
    data['account_id'] = accountId;
    data['is_connected'] = isConnected;
    data['followers_count'] = followersCount;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    return data;
  }

  @override
  List<Object?> get props => [
    id,
    brokerId,
    platform,
    accountName,
    accountId,
    isConnected,
    followersCount,
    createdAt,
    updatedAt,
  ];
}
