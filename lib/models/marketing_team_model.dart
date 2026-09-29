import 'user_model.dart';

class MarketingTeamModel {
  static const String tableName = 'marketing_teams';

  final String id;
  final String name;
  final String? territory;
  final String? description;
  final bool isActive;
  final String? createdBy;
  final int membersCount;
  final int brokersCount;
  final UserModel? leadUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketingTeamModel({
    required this.id,
    required this.name,
    this.territory,
    this.description,
    this.isActive = true,
    this.createdBy,
    this.membersCount = 0,
    this.brokersCount = 0,
    this.leadUser,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketingTeamModel.fromJson(Map<String, dynamic> json) {
    return MarketingTeamModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      territory: json['territory'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      membersCount: int.tryParse(json['members_count']?.toString() ?? '0') ?? 0,
      brokersCount: int.tryParse(json['brokers_count']?.toString() ?? '0') ?? 0,
      leadUser: json['lead_user'] != null
          ? UserModel.fromJson(Map<String, dynamic>.from(json['lead_user'] as Map))
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (territory != null) 'territory': territory,
      if (description != null) 'description': description,
      'is_active': isActive,
      if (createdBy != null) 'created_by': createdBy,
      'members_count': membersCount,
      'brokers_count': brokersCount,
      if (leadUser != null) 'lead_user': leadUser?.toJson(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  MarketingTeamModel copyWith({
    String? id,
    String? name,
    String? territory,
    String? description,
    bool? isActive,
    String? createdBy,
    int? membersCount,
    int? brokersCount,
    UserModel? leadUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketingTeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      territory: territory ?? this.territory,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      membersCount: membersCount ?? this.membersCount,
      brokersCount: brokersCount ?? this.brokersCount,
      leadUser: leadUser ?? this.leadUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TeamMemberModel {
  static const String tableName = 'marketing_team_members';

  final String id;
  final String teamId;
  final String userId;
  final bool isLead;
  final UserModel? user;
  final DateTime createdAt;

  const TeamMemberModel({
    required this.id,
    required this.teamId,
    required this.userId,
    this.isLead = false,
    this.user,
    required this.createdAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['user'] != null && json['user'] is Map) {
      parsedUser = UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map));
    } else if (json['user_id'] != null && json['user_id'] is Map) {
      parsedUser = UserModel.fromJson(Map<String, dynamic>.from(json['user_id'] as Map));
    }

    final rawUserId = json['user_id'] is Map
        ? (json['user_id']['id'] as String? ?? '')
        : (json['user_id'] as String? ?? '');

    return TeamMemberModel(
      id: json['id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      userId: rawUserId,
      isLead: json['is_lead'] as bool? ?? false,
      user: parsedUser,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'is_lead': isLead,
      if (user != null) 'user': user!.toJson(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  TeamMemberModel copyWith({
    String? id,
    String? teamId,
    String? userId,
    bool? isLead,
    UserModel? user,
    DateTime? createdAt,
  }) {
    return TeamMemberModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      isLead: isLead ?? this.isLead,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

