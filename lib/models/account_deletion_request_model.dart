import 'package:equatable/equatable.dart';

class AccountDeletionRequestModel extends Equatable {
  static const String tableName = 'account_deletion_requests';

  final String id;
  final String? userId;
  final String? brokerId;
  final String? email;
  final String? phone;
  final String status; // pending | approved | rejected
  final String deletionType; // soft | hard
  final String? reason;
  final String? requestedIp;
  final DateTime requestedAt;
  final DateTime updatedAt;
  final DateTime? processedAt;
  final String? processedByAdminId;

  const AccountDeletionRequestModel({
    required this.id,
    this.userId,
    this.brokerId,
    this.email,
    this.phone,
    this.status = 'pending',
    this.deletionType = 'soft',
    this.reason,
    this.requestedIp,
    required this.requestedAt,
    required this.updatedAt,
    this.processedAt,
    this.processedByAdminId,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isHardDelete => deletionType == 'hard';

  static AccountDeletionRequestModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return AccountDeletionRequestModel(
        id: json?.toString() ?? '',
        requestedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return AccountDeletionRequestModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      brokerId: json['broker_id']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      deletionType: json['deletion_type']?.toString() ?? 'soft',
      reason: json['reason']?.toString(),
      requestedIp: json['requested_ip']?.toString(),
      requestedAt:
          DateTime.tryParse(json['requested_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'].toString())?.toLocal()
          : null,
      processedByAdminId: json['processed_by_admin_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        if (brokerId != null) 'broker_id': brokerId,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'status': status,
        'deletion_type': deletionType,
        if (reason != null) 'reason': reason,
        if (requestedIp != null) 'requested_ip': requestedIp,
        'requested_at': requestedAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        if (processedAt != null)
          'processed_at': processedAt!.toUtc().toIso8601String(),
        if (processedByAdminId != null)
          'processed_by_admin_id': processedByAdminId,
      };

  AccountDeletionRequestModel copyWith({
    String? id,
    String? userId,
    String? brokerId,
    String? email,
    String? phone,
    String? status,
    String? deletionType,
    String? reason,
    String? requestedIp,
    DateTime? requestedAt,
    DateTime? updatedAt,
    DateTime? processedAt,
    String? processedByAdminId,
  }) {
    return AccountDeletionRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brokerId: brokerId ?? this.brokerId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      deletionType: deletionType ?? this.deletionType,
      reason: reason ?? this.reason,
      requestedIp: requestedIp ?? this.requestedIp,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedAt: processedAt ?? this.processedAt,
      processedByAdminId: processedByAdminId ?? this.processedByAdminId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        brokerId,
        email,
        status,
        deletionType,
        requestedAt,
        processedAt,
      ];
}
