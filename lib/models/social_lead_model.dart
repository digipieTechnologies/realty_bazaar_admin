import 'package:equatable/equatable.dart';

class SocialLeadModel extends Equatable {
  static String tableName = "social_leads";

  final String? id;
  final String? brokerId;
  final String? propertyId;
  final String? postId;
  final String? leadName;
  final String? leadEmail;
  final String? leadPhone;
  final String? platform;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SocialLeadModel({
    this.id,
    this.brokerId,
    this.propertyId,
    this.postId,
    this.leadName,
    this.leadEmail,
    this.leadPhone,
    this.platform,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  static SocialLeadModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return SocialLeadModel(id: json?.toString());
    }
    return SocialLeadModel(
      id: json['id']?.toString(),
      brokerId: json['broker_id']?.toString(),
      propertyId: json['property_id']?.toString(),
      postId: json['post_id']?.toString(),
      leadName: json['lead_name']?.toString() ?? '',
      leadEmail: json['lead_email']?.toString() ?? '',
      leadPhone: json['lead_phone']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'Instagram',
      status: json['status']?.toString() ?? 'new',
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
    data['property_id'] = propertyId;
    data['post_id'] = postId;
    data['lead_name'] = leadName;
    data['lead_email'] = leadEmail;
    data['lead_phone'] = leadPhone;
    data['platform'] = platform;
    data['status'] = status;
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
    propertyId,
    postId,
    leadName,
    leadEmail,
    leadPhone,
    platform,
    status,
    createdAt,
    updatedAt,
  ];
}
