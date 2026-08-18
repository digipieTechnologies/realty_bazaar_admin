import 'package:equatable/equatable.dart';

class ActivityLogModel extends Equatable {
  static String tableName = "activity_logs";

  final String? id;
  final String? actorName;
  final String? actorRole;
  final String? action;
  final String? targetEntity;
  final String? details;
  final DateTime? createdAt;

  const ActivityLogModel({
    this.id,
    this.actorName,
    this.actorRole,
    this.action,
    this.targetEntity,
    this.details,
    this.createdAt,
  });

  static ActivityLogModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return ActivityLogModel(id: json?.toString());
    }
    return ActivityLogModel(
      id: json['id']?.toString(),
      actorName: json['actor_name']?.toString() ?? 'System',
      actorRole: json['actor_role']?.toString() ?? 'super_admin',
      action: json['action']?.toString() ?? '',
      targetEntity: json['target_entity']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    data['actor_name'] = actorName;
    data['actor_role'] = actorRole;
    data['action'] = action;
    data['target_entity'] = targetEntity;
    data['details'] = details;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    return data;
  }

  @override
  List<Object?> get props => [id, actorName, actorRole, action, targetEntity, details, createdAt];
}
