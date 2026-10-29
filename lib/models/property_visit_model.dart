import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'property_model.dart';

class PropertyVisitModel extends Equatable {
  static const String tableName = 'property_visits';

  final String id;
  final String brokerId;
  final String propertyId;
  final String clientName;
  final String clientPhone;
  final String phoneCountryCode;
  final String phoneCountryIso;
  final DateTime visitDate;
  final String timeSlot;
  final String status;
  final String? notes;
  final int rescheduleCount;
  final String? rescheduleReason;
  final String? cancelledReason;
  final String? leadId;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final BrokerModel? broker;
  final PropertyModel? property;

  const PropertyVisitModel({
    required this.id,
    required this.brokerId,
    required this.propertyId,
    required this.clientName,
    required this.clientPhone,
    this.phoneCountryCode = '91',
    this.phoneCountryIso = 'IN',
    required this.visitDate,
    required this.timeSlot,
    this.status = 'pending',
    this.notes,
    this.rescheduleCount = 0,
    this.rescheduleReason,
    this.cancelledReason,
    this.leadId,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.broker,
    this.property,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  static PropertyVisitModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return PropertyVisitModel(
        id: json?.toString() ?? '',
        brokerId: '',
        propertyId: '',
        clientName: '',
        clientPhone: '',
        visitDate: DateTime.now(),
        timeSlot: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return PropertyVisitModel(
      id: json['id']?.toString() ?? '',
      brokerId: json['broker_id'] is Map
          ? json['broker_id']['id']?.toString() ?? ''
          : json['broker_id']?.toString() ?? '',
      propertyId: json['property_id'] is Map
          ? json['property_id']['id']?.toString() ?? ''
          : json['property_id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      clientPhone: json['client_phone']?.toString() ?? '',
      phoneCountryCode: json['phone_country_code']?.toString() ?? '91',
      phoneCountryIso: json['phone_country_iso']?.toString() ?? 'IN',
      visitDate:
          DateTime.tryParse(json['visit_date']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      timeSlot: json['time_slot']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      rescheduleCount:
          int.tryParse(json['reschedule_count']?.toString() ?? '0') ?? 0,
      rescheduleReason: json['reschedule_reason']?.toString(),
      cancelledReason: json['cancelled_reason']?.toString(),
      leadId: json['lead_id']?.toString(),
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal()
          : null,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      broker: json['broker_id'] is Map<String, dynamic>
          ? BrokerModel.fromJson(json['broker_id'])
          : null,
      property: json['property_id'] is Map<String, dynamic>
          ? PropertyModel.fromJson(json['property_id'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'broker_id': brokerId,
        'property_id': propertyId,
        'client_name': clientName,
        'client_phone': clientPhone,
        'phone_country_code': phoneCountryCode,
        'phone_country_iso': phoneCountryIso,
        'visit_date': visitDate.toUtc().toIso8601String(),
        'time_slot': timeSlot,
        'status': status,
        if (notes != null) 'notes': notes,
        'reschedule_count': rescheduleCount,
        if (rescheduleReason != null) 'reschedule_reason': rescheduleReason,
        if (cancelledReason != null) 'cancelled_reason': cancelledReason,
        if (leadId != null) 'lead_id': leadId,
        'is_deleted': isDeleted,
        if (deletedAt != null)
          'deleted_at': deletedAt!.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  PropertyVisitModel copyWith({
    String? id,
    String? brokerId,
    String? propertyId,
    String? clientName,
    String? clientPhone,
    String? phoneCountryCode,
    String? phoneCountryIso,
    DateTime? visitDate,
    String? timeSlot,
    String? status,
    String? notes,
    int? rescheduleCount,
    String? rescheduleReason,
    String? cancelledReason,
    String? leadId,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    BrokerModel? broker,
    PropertyModel? property,
  }) {
    return PropertyVisitModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      propertyId: propertyId ?? this.propertyId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneCountryIso: phoneCountryIso ?? this.phoneCountryIso,
      visitDate: visitDate ?? this.visitDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      leadId: leadId ?? this.leadId,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      broker: broker ?? this.broker,
      property: property ?? this.property,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brokerId,
        propertyId,
        clientName,
        clientPhone,
        visitDate,
        timeSlot,
        status,
        rescheduleCount,
        isDeleted,
        createdAt,
        updatedAt,
      ];
}
