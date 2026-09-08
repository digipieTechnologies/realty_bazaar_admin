import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  static String tableName = "addresses";

  final String? id;
  final String? fullAddress;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;
  final String? landmark;
  final String? entityType;
  final String? entityId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AddressModel({
    this.id,
    this.fullAddress,
    this.city,
    this.state,
    this.pincode,
    this.country,
    this.landmark,
    this.entityType,
    this.entityId,
    this.createdAt,
    this.updatedAt,
  });

  static AddressModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return AddressModel(id: json?.toString());
    }
    return AddressModel(
      id: json['id']?.toString(),
      fullAddress: json['full_address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id']?.toString(),
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
    data['full_address'] = fullAddress;
    data['city'] = city;
    data['state'] = state;
    data['pincode'] = pincode;
    data['country'] = country;
    data['landmark'] = landmark;
    data['entity_type'] = entityType;
    data['entity_id'] = entityId;
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
    fullAddress,
    city,
    state,
    pincode,
    country,
    landmark,
    entityType,
    entityId,
    createdAt,
    updatedAt,
  ];
}
