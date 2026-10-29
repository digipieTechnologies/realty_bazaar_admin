import 'package:equatable/equatable.dart';

class LeadActivityModel extends Equatable {
  static const String tableName = 'lead_activities';

  final String id;
  final String leadId;
  final String? brokerId;
  final String activityType;
  final String title;
  final String? description;
  final Map<String, dynamic> metadata;
  final String? createdByUserId;
  final DateTime createdAt;

  const LeadActivityModel({
    required this.id,
    required this.leadId,
    this.brokerId,
    required this.activityType,
    required this.title,
    this.description,
    this.metadata = const {},
    this.createdByUserId,
    required this.createdAt,
  });

  static LeadActivityModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return LeadActivityModel(
        id: json?.toString() ?? '',
        leadId: '',
        activityType: '',
        title: '',
        createdAt: DateTime.now(),
      );
    }

    Map<String, dynamic> parsedMetadata = {};
    if (json['metadata'] is Map) {
      parsedMetadata = Map<String, dynamic>.from(json['metadata'] as Map);
    }

    return LeadActivityModel(
      id: json['id']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? '',
      brokerId: json['broker_id']?.toString(),
      activityType: json['activity_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      metadata: parsedMetadata,
      createdByUserId: json['created_by_user_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lead_id': leadId,
        if (brokerId != null) 'broker_id': brokerId,
        'activity_type': activityType,
        'title': title,
        if (description != null) 'description': description,
        'metadata': metadata,
        if (createdByUserId != null) 'created_by_user_id': createdByUserId,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  LeadActivityModel copyWith({
    String? id,
    String? leadId,
    String? brokerId,
    String? activityType,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
    String? createdByUserId,
    DateTime? createdAt,
  }) {
    return LeadActivityModel(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      brokerId: brokerId ?? this.brokerId,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        leadId,
        brokerId,
        activityType,
        title,
        description,
        createdAt,
      ];
}
