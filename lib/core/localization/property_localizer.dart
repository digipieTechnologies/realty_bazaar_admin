// File: lib/core/localization/property_localizer.dart
// Purpose: Helper class for localizing property model values to user's preferred language in Admin app.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/property_enums.dart';

class PropertyLocalizer {
  PropertyLocalizer._();

  /// Gets localized display text for Property Type
  static String getLocalizedPropertyType(BuildContext context, dynamic propertyTypeInput) {
    final PropertyType type = propertyTypeInput is PropertyType
        ? propertyTypeInput
        : (propertyTypeInput?.toString()).asPropertyType;

    switch (type) {
      case PropertyType.apartment:
        return 'prop_type_flat'.tr();
      case PropertyType.villa:
        return 'prop_type_villa'.tr();
      case PropertyType.rowHouse:
        return 'prop_type_row_house'.tr();
      case PropertyType.penthouse:
        return 'prop_type_penthouse'.tr();
      case PropertyType.commercial:
        return 'prop_type_commercial'.tr();
      case PropertyType.plot:
        return 'prop_type_plot'.tr();
      case PropertyType.unknown:
        return propertyTypeInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Listing Type
  static String getLocalizedListingType(BuildContext context, dynamic listingTypeInput) {
    final ListingType type = listingTypeInput is ListingType
        ? listingTypeInput
        : (listingTypeInput?.toString()).asListingType;

    switch (type) {
      case ListingType.sale:
        return 'prop_listing_sale'.tr();
      case ListingType.rent:
        return 'prop_listing_rent'.tr();
      case ListingType.lease:
        return 'prop_listing_lease'.tr();
      case ListingType.unknown:
        return listingTypeInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Construction Status
  static String getLocalizedConstructionStatus(BuildContext context, dynamic statusInput) {
    final ConstructionStatus status = statusInput is ConstructionStatus
        ? statusInput
        : (statusInput?.toString()).asConstructionStatus;

    switch (status) {
      case ConstructionStatus.readyToMove:
        return 'prop_const_ready'.tr();
      case ConstructionStatus.underConstruction:
        return 'prop_const_under'.tr();
      case ConstructionStatus.newLaunch:
        return 'prop_const_new'.tr();
      case ConstructionStatus.unknown:
        return statusInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Furnishing Status
  static String getLocalizedFurnishingStatus(BuildContext context, dynamic furnishingInput) {
    final FurnishingStatus status = furnishingInput is FurnishingStatus
        ? furnishingInput
        : (furnishingInput?.toString()).asFurnishingStatus;

    switch (status) {
      case FurnishingStatus.fullyFurnished:
        return 'prop_furn_fully'.tr();
      case FurnishingStatus.semiFurnished:
        return 'prop_furn_semi'.tr();
      case FurnishingStatus.unfurnished:
        return 'prop_furn_unfurnished'.tr();
      case FurnishingStatus.unknown:
        return furnishingInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Facing Direction
  static String getLocalizedFacing(BuildContext context, dynamic facingInput) {
    final FacingDirection facing = facingInput is FacingDirection
        ? facingInput
        : (facingInput?.toString()).asFacingDirection;

    switch (facing) {
      case FacingDirection.east:
        return 'prop_facing_east'.tr();
      case FacingDirection.west:
        return 'prop_facing_west'.tr();
      case FacingDirection.north:
        return 'prop_facing_north'.tr();
      case FacingDirection.south:
        return 'prop_facing_south'.tr();
      case FacingDirection.northEast:
        return 'prop_facing_ne'.tr();
      case FacingDirection.northWest:
        return 'prop_facing_nw'.tr();
      case FacingDirection.southEast:
        return 'prop_facing_se'.tr();
      case FacingDirection.southWest:
        return 'prop_facing_sw'.tr();
      case FacingDirection.unknown:
        return facingInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Amenities
  static String getLocalizedAmenity(BuildContext context, String englishAmenity) {
    if (englishAmenity.isEmpty) return '';
    final lower = englishAmenity.trim().toLowerCase();
    if (lower.contains('pool')) return 'amenity_pool'.tr();
    if (lower.contains('gym') || lower.contains('fitness')) return 'amenity_gym'.tr();
    if (lower.contains('security') && !lower.contains('cctv')) return 'amenity_security'.tr();
    if (lower.contains('garden')) return 'amenity_garden'.tr();
    if (lower.contains('power') || lower.contains('backup')) return 'amenity_power_backup'.tr();
    if (lower.contains('club')) return 'amenity_clubhouse'.tr();
    if (lower.contains('elevator') || lower.contains('lift')) return 'amenity_elevator'.tr();
    if (lower.contains('parking')) return 'amenity_parking'.tr();
    if (lower.contains('cctv')) return 'amenity_cctv'.tr();
    if (lower.contains('children') || lower.contains('play') || lower.contains('kids'))
      return 'amenity_play_area'.tr();
    return englishAmenity;
  }

  /// Gets localized display text for Property Status
  static String getLocalizedPropertyStatus(BuildContext context, dynamic statusInput) {
    final PropertyStatus status = statusInput is PropertyStatus
        ? statusInput
        : (statusInput?.toString()).asPropertyStatus;

    switch (status) {
      case PropertyStatus.available:
        return 'prop_status_available'.tr();
      case PropertyStatus.sold:
        return 'prop_status_sold'.tr();
      case PropertyStatus.rented:
        return 'prop_status_rented'.tr();
      case PropertyStatus.underOffer:
        return 'prop_status_available'.tr();
      case PropertyStatus.unknown:
        return statusInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Area Unit
  static String getLocalizedAreaUnit(BuildContext context, dynamic unitInput) {
    final AreaUnit unit = unitInput is AreaUnit ? unitInput : (unitInput?.toString()).asAreaUnit;

    switch (unit) {
      case AreaUnit.sqft:
        return 'unit_sqft'.tr();
      case AreaUnit.sqyd:
        return 'unit_sqyd'.tr();
      case AreaUnit.sqm:
        return 'unit_sqm'.tr();
      case AreaUnit.acre:
        return 'unit_acre'.tr();
      case AreaUnit.unknown:
        return unitInput?.toString() ?? '';
    }
  }
}
