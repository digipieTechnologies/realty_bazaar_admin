-- Migration: Create PostgreSQL native ENUM types for properties table and update property columns
-- Date: 2026-07-24

--------------------------------------------------------------------------------
-- 1. CREATE ENUM TYPES
--------------------------------------------------------------------------------
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'property_type_enum') THEN
    CREATE TYPE property_type_enum AS ENUM ('apartment', 'villa', 'row_house', 'penthouse', 'commercial', 'plot', 'unknown');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'listing_type_enum') THEN
    CREATE TYPE listing_type_enum AS ENUM ('sale', 'rent', 'lease', 'unknown');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'construction_status_enum') THEN
    CREATE TYPE construction_status_enum AS ENUM ('ready_to_move', 'under_construction', 'new_launch', 'unknown');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'furnishing_status_enum') THEN
    CREATE TYPE furnishing_status_enum AS ENUM ('unfurnished', 'semi_furnished', 'fully_furnished', 'unknown');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'property_status_enum') THEN
    CREATE TYPE property_status_enum AS ENUM ('available', 'sold', 'rented', 'under_offer', 'unknown');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'facing_direction_enum') THEN
    CREATE TYPE facing_direction_enum AS ENUM ('east', 'west', 'north', 'south', 'north_east', 'north_west', 'south_east', 'south_west', 'unknown');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'area_unit_enum') THEN
    CREATE TYPE area_unit_enum AS ENUM ('sqft', 'sqyd', 'sqm', 'acre', 'unknown');
  END IF;
END $$;

--------------------------------------------------------------------------------
-- 2. UPDATE PROPERTIES TABLE COLUMNS TO USE ENUMS
--------------------------------------------------------------------------------

-- Drop default values before changing types
ALTER TABLE properties 
  ALTER COLUMN property_type DROP DEFAULT,
  ALTER COLUMN listing_type DROP DEFAULT,
  ALTER COLUMN construction_status DROP DEFAULT,
  ALTER COLUMN furnishing_status DROP DEFAULT,
  ALTER COLUMN property_status DROP DEFAULT,
  ALTER COLUMN facing DROP DEFAULT,
  ALTER COLUMN area_unit DROP DEFAULT;

ALTER TABLE properties 
  ALTER COLUMN property_type TYPE property_type_enum 
  USING (
    CASE lower(trim(coalesce(property_type::text, 'apartment')))
      WHEN 'apartment' THEN 'apartment'::property_type_enum
      WHEN 'flat' THEN 'apartment'::property_type_enum
      WHEN 'villa' THEN 'villa'::property_type_enum
      WHEN 'bungalow' THEN 'villa'::property_type_enum
      WHEN 'row_house' THEN 'row_house'::property_type_enum
      WHEN 'row house' THEN 'row_house'::property_type_enum
      WHEN 'penthouse' THEN 'penthouse'::property_type_enum
      WHEN 'commercial' THEN 'commercial'::property_type_enum
      WHEN 'office' THEN 'commercial'::property_type_enum
      WHEN 'plot' THEN 'plot'::property_type_enum
      WHEN 'land' THEN 'plot'::property_type_enum
      ELSE 'unknown'::property_type_enum
    END
  );

ALTER TABLE properties 
  ALTER COLUMN listing_type TYPE listing_type_enum 
  USING (
    CASE lower(trim(coalesce(listing_type::text, 'sale')))
      WHEN 'sale' THEN 'sale'::listing_type_enum
      WHEN 'rent' THEN 'rent'::listing_type_enum
      WHEN 'lease' THEN 'lease'::listing_type_enum
      ELSE 'unknown'::listing_type_enum
    END
  );

ALTER TABLE properties 
  ALTER COLUMN construction_status TYPE construction_status_enum 
  USING (
    CASE lower(trim(coalesce(construction_status::text, 'ready_to_move')))
      WHEN 'ready_to_move' THEN 'ready_to_move'::construction_status_enum
      WHEN 'ready to move' THEN 'ready_to_move'::construction_status_enum
      WHEN 'under_construction' THEN 'under_construction'::construction_status_enum
      WHEN 'under construction' THEN 'under_construction'::construction_status_enum
      WHEN 'new_launch' THEN 'new_launch'::construction_status_enum
      WHEN 'new launch' THEN 'new_launch'::construction_status_enum
      ELSE 'unknown'::construction_status_enum
    END
  );

ALTER TABLE properties 
  ALTER COLUMN furnishing_status TYPE furnishing_status_enum 
  USING (
    CASE lower(trim(coalesce(furnishing_status::text, 'unfurnished')))
      WHEN 'unfurnished' THEN 'unfurnished'::furnishing_status_enum
      WHEN 'semi_furnished' THEN 'semi_furnished'::furnishing_status_enum
      WHEN 'semi-furnished' THEN 'semi_furnished'::furnishing_status_enum
      WHEN 'fully_furnished' THEN 'fully_furnished'::furnishing_status_enum
      WHEN 'fully-furnished' THEN 'fully_furnished'::furnishing_status_enum
      ELSE 'unknown'::furnishing_status_enum
    END
  );

ALTER TABLE properties 
  ALTER COLUMN property_status TYPE property_status_enum 
  USING (
    CASE lower(trim(coalesce(property_status::text, 'available')))
      WHEN 'available' THEN 'available'::property_status_enum
      WHEN 'sold' THEN 'sold'::property_status_enum
      WHEN 'rented' THEN 'rented'::property_status_enum
      WHEN 'under_offer' THEN 'under_offer'::property_status_enum
      WHEN 'under offer' THEN 'under_offer'::property_status_enum
      ELSE 'unknown'::property_status_enum
    END
  );

ALTER TABLE properties 
  ALTER COLUMN facing TYPE facing_direction_enum 
  USING (
    CASE lower(trim(coalesce(facing::text, 'east')))
      WHEN 'east' THEN 'east'::facing_direction_enum
      WHEN 'west' THEN 'west'::facing_direction_enum
      WHEN 'north' THEN 'north'::facing_direction_enum
      WHEN 'south' THEN 'south'::facing_direction_enum
      WHEN 'north_east' THEN 'north_east'::facing_direction_enum
      WHEN 'north-east' THEN 'north_east'::facing_direction_enum
      WHEN 'north_west' THEN 'north_west'::facing_direction_enum
      WHEN 'north-west' THEN 'north_west'::facing_direction_enum
      WHEN 'south_east' THEN 'south_east'::facing_direction_enum
      WHEN 'south-east' THEN 'south_east'::facing_direction_enum
      WHEN 'south_west' THEN 'south_west'::facing_direction_enum
      WHEN 'south-west' THEN 'south_west'::facing_direction_enum
      ELSE 'unknown'::facing_direction_enum
    END
  );

ALTER TABLE properties 
  ALTER COLUMN area_unit TYPE area_unit_enum 
  USING (
    CASE lower(trim(coalesce(area_unit::text, 'sqft')))
      WHEN 'sqft' THEN 'sqft'::area_unit_enum
      WHEN 'sqyd' THEN 'sqyd'::area_unit_enum
      WHEN 'sqm' THEN 'sqm'::area_unit_enum
      WHEN 'acre' THEN 'acre'::area_unit_enum
      ELSE 'unknown'::area_unit_enum
    END
  );

ALTER TABLE properties ALTER COLUMN property_type SET DEFAULT 'apartment'::property_type_enum;
ALTER TABLE properties ALTER COLUMN listing_type SET DEFAULT 'sale'::listing_type_enum;
ALTER TABLE properties ALTER COLUMN construction_status SET DEFAULT 'ready_to_move'::construction_status_enum;
ALTER TABLE properties ALTER COLUMN furnishing_status SET DEFAULT 'unfurnished'::furnishing_status_enum;
ALTER TABLE properties ALTER COLUMN property_status SET DEFAULT 'available'::property_status_enum;
ALTER TABLE properties ALTER COLUMN facing SET DEFAULT 'east'::facing_direction_enum;
ALTER TABLE properties ALTER COLUMN area_unit SET DEFAULT 'sqft'::area_unit_enum;
