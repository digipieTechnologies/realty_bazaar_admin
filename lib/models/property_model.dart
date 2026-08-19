import 'package:brokerflow_admin/widgets/brand/app_logo.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../app/context_ext.dart';
import '../widgets/common/cached_image.dart';
import 'address_model.dart';
import 'broker_model.dart';
import 'media_model.dart';
import 'property_enums.dart';

class PropertyModel extends Equatable {
  static const String tableName = "properties";

  final String? id;
  final String? brokerId;
  final String? addressId;
  final PropertyType propertyType;
  final ListingType listingType;
  final double price;
  final double area;
  final AreaUnit areaUnit;
  final int bedrooms;
  final int bathrooms;
  final int balconies;
  final int parking;
  final int? floorNumber;
  final int? totalFloors;
  final FurnishingStatus furnishingStatus;
  final PropertyStatus propertyStatus;
  final ConstructionStatus constructionStatus;
  final FacingDirection? facing;
  final List<String> amenities;
  final List<MediaModel> medias;
  final AddressModel? address;
  final BrokerModel? broker;
  final bool isActive;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String propertyTitle;
  final String? propertyDescription;

  const PropertyModel({
    this.id,
    this.brokerId,
    this.addressId,
    required this.propertyTitle,
    this.propertyDescription,
    this.propertyType = PropertyType.apartment,
    this.listingType = ListingType.sale,
    required this.price,
    required this.area,
    this.areaUnit = AreaUnit.sqft,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.balconies = 0,
    this.parking = 0,
    this.floorNumber,
    this.totalFloors,
    this.furnishingStatus = FurnishingStatus.unfurnished,
    this.propertyStatus = PropertyStatus.available,
    this.constructionStatus = ConstructionStatus.readyToMove,
    this.facing,
    this.amenities = const [],
    this.medias = const [],
    this.address,
    this.broker,
    this.isActive = true,
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  static PropertyModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const PropertyModel(
        id: null,
        propertyTitle: '',
        propertyType: PropertyType.apartment,
        listingType: ListingType.sale,
        price: 0,
        area: 0,
      );
    }

    List<String> parsedAmenities = [];
    if (json['amenities'] != null && json['amenities'] is List) {
      parsedAmenities = (json['amenities'] as List).map((e) => e.toString()).toList();
    }

    List<MediaModel> parsedMedias = [];
    if (json['medias'] != null && json['medias'] is List) {
      parsedMedias = (json['medias'] as List).map((e) => MediaModel.fromJson(e)).toList();
    }

    BrokerModel? parsedBroker;
    if (json['broker_id'] != null && json['broker_id'] is Map<String, dynamic>) {
      parsedBroker = BrokerModel.fromJson(json['broker_id']);
    } else if (json['broker'] != null && json['broker'] is Map<String, dynamic>) {
      parsedBroker = BrokerModel.fromJson(json['broker']);
    }

    return PropertyModel(
      id: json['id']?.toString(),
      brokerId: json['broker_id'] is Map<String, dynamic>
          ? json['broker_id']['id']?.toString()
          : json['broker_id']?.toString(),
      addressId: json['address_id'] is Map<String, dynamic>
          ? json['address_id']['id']?.toString()
          : json['address_id']?.toString(),
      propertyTitle: json['property_title']?.toString() ?? '',
      propertyDescription: json['property_description']?.toString(),
      propertyType: (json['property_type']?.toString()).asPropertyType,
      listingType: (json['listing_type']?.toString()).asListingType,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      area: double.tryParse(json['area']?.toString() ?? '0') ?? 0.0,
      areaUnit: (json['area_unit']?.toString()).asAreaUnit,
      bedrooms: int.tryParse(json['bedrooms']?.toString() ?? '0') ?? 0,
      bathrooms: int.tryParse(json['bathrooms']?.toString() ?? '0') ?? 0,
      balconies: int.tryParse(json['balconies']?.toString() ?? '0') ?? 0,
      parking: int.tryParse(json['parking']?.toString() ?? '0') ?? 0,
      floorNumber: int.tryParse(json['floor_number']?.toString() ?? ''),
      totalFloors: int.tryParse(json['total_floors']?.toString() ?? ''),
      furnishingStatus: (json['furnishing_status']?.toString()).asFurnishingStatus,
      propertyStatus: (json['property_status']?.toString()).asPropertyStatus,
      constructionStatus: (json['construction_status']?.toString()).asConstructionStatus,
      facing: json['facing'] != null ? (json['facing']?.toString()).asFacingDirection : null,
      amenities: parsedAmenities,
      medias: parsedMedias,
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : (json['address_id'] is Map<String, dynamic> ? AddressModel.fromJson(json['address_id']) : null),
      broker: parsedBroker,
      isActive: json['is_active'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal()
          : null,
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
    if (brokerId != null) data['broker_id'] = brokerId;
    if (addressId != null) data['address_id'] = addressId;
    data['property_title'] = propertyTitle;
    data['property_description'] = propertyDescription;
    data['property_type'] = propertyType.apiValue;
    data['listing_type'] = listingType.apiValue;
    data['price'] = price;
    data['area'] = area;
    data['area_unit'] = areaUnit.apiValue;
    data['bedrooms'] = bedrooms;
    data['bathrooms'] = bathrooms;
    data['balconies'] = balconies;
    data['parking'] = parking;
    data['floor_number'] = floorNumber;
    data['total_floors'] = totalFloors;
    data['furnishing_status'] = furnishingStatus.apiValue;
    data['property_status'] = propertyStatus.apiValue;
    data['construction_status'] = constructionStatus.apiValue;
    if (facing != null) data['facing'] = facing!.apiValue;
    data['amenities'] = amenities;
    data['medias'] = medias.map((e) => e.toJson()).toList();
    if (address != null) data['address'] = address!.toJson();
    data['is_active'] = isActive;
    data['is_deleted'] = isDeleted;
    if (deletedAt != null) data['deleted_at'] = deletedAt?.toUtc().toIso8601String();
    if (createdAt != null) data['created_at'] = createdAt?.toUtc().toIso8601String();
    if (updatedAt != null) data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    return data;
  }

  PropertyModel copyWith({
    String? id,
    String? brokerId,
    String? addressId,
    String? propertyTitle,
    String? propertyDescription,
    PropertyType? propertyType,
    ListingType? listingType,
    double? price,
    double? area,
    AreaUnit? areaUnit,
    int? bedrooms,
    int? bathrooms,
    int? balconies,
    int? parking,
    int? floorNumber,
    int? totalFloors,
    FurnishingStatus? furnishingStatus,
    PropertyStatus? propertyStatus,
    ConstructionStatus? constructionStatus,
    FacingDirection? facing,
    List<String>? amenities,
    List<MediaModel>? medias,
    AddressModel? address,
    bool? isActive,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      addressId: addressId ?? this.addressId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyDescription: propertyDescription ?? this.propertyDescription,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      balconies: balconies ?? this.balconies,
      parking: parking ?? this.parking,
      floorNumber: floorNumber ?? this.floorNumber,
      totalFloors: totalFloors ?? this.totalFloors,
      furnishingStatus: furnishingStatus ?? this.furnishingStatus,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      constructionStatus: constructionStatus ?? this.constructionStatus,
      facing: facing ?? this.facing,
      amenities: amenities ?? this.amenities,
      medias: medias ?? this.medias,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    brokerId,
    addressId,
    propertyTitle,
    propertyDescription,
    propertyType,
    listingType,
    price,
    area,
    areaUnit,
    bedrooms,
    bathrooms,
    balconies,
    parking,
    floorNumber,
    totalFloors,
    furnishingStatus,
    propertyStatus,
    constructionStatus,
    facing,
    amenities,
    medias,
    address,
    isActive,
    isDeleted,
    deletedAt,
    createdAt,
    updatedAt,
  ];

  Widget propertyImage({
    required BuildContext context,
    double width = 40,
    double height = 40,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);
    final child = CustomAppLogo(
      width: width,
      height: height,
      logoColor: context.infoColor.withOpacity(0.4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: effectiveBorderRadius,
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    );

    return CachedImage(
      imageUrl: medias.firstOrNull?.url ?? '',
      width: width,
      height: height,
      fit: fit,
      borderRadius: effectiveBorderRadius,
      backgroundColor: colorScheme.surface,
      borderColor: colorScheme.outlineVariant.withValues(alpha: 0.6),
      errorWidget: (_) => child,
      placeholderWidget: (_) => child,
    );
  }
}
