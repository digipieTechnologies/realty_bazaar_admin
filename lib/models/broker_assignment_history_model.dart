import 'package:equatable/equatable.dart';

class BrokerAssignmentHistoryModel extends Equatable {
  static const String tableName = 'broker_assignment_history';

  final String id;
  final String brokerId;
  final String? previousTeamId;
  final String? newTeamId;
  final String? previousUserId;
  final String? newUserId;
  final String? changedBy;
  final String? notes;
  final DateTime createdAt;

  const BrokerAssignmentHistoryModel({
    required this.id,
    required this.brokerId,
    this.previousTeamId,
    this.newTeamId,
    this.previousUserId,
    this.newUserId,
    this.changedBy,
    this.notes,
    required this.createdAt,
  });

  static BrokerAssignmentHistoryModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return BrokerAssignmentHistoryModel(
        id: json?.toString() ?? '',
        brokerId: '',
        createdAt: DateTime.now(),
      );
    }

    return BrokerAssignmentHistoryModel(
      id: json['id']?.toString() ?? '',
      brokerId: json['broker_id']?.toString() ?? '',
      previousTeamId: json['previous_team_id']?.toString(),
      newTeamId: json['new_team_id']?.toString(),
      previousUserId: json['previous_user_id']?.toString(),
      newUserId: json['new_user_id']?.toString(),
      changedBy: json['changed_by']?.toString(),
      notes: json['notes']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'broker_id': brokerId,
        if (previousTeamId != null) 'previous_team_id': previousTeamId,
        if (newTeamId != null) 'new_team_id': newTeamId,
        if (previousUserId != null) 'previous_user_id': previousUserId,
        if (newUserId != null) 'new_user_id': newUserId,
        if (changedBy != null) 'changed_by': changedBy,
        if (notes != null) 'notes': notes,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  BrokerAssignmentHistoryModel copyWith({
    String? id,
    String? brokerId,
    String? previousTeamId,
    String? newTeamId,
    String? previousUserId,
    String? newUserId,
    String? changedBy,
    String? notes,
    DateTime? createdAt,
  }) {
    return BrokerAssignmentHistoryModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      previousTeamId: previousTeamId ?? this.previousTeamId,
      newTeamId: newTeamId ?? this.newTeamId,
      previousUserId: previousUserId ?? this.previousUserId,
      newUserId: newUserId ?? this.newUserId,
      changedBy: changedBy ?? this.changedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brokerId,
        previousTeamId,
        newTeamId,
        previousUserId,
        newUserId,
        changedBy,
        createdAt,
      ];
}
