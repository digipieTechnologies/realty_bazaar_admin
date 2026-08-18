-- Migration: Full-Text Search tsvector columns, GIN indexes, and automatic triggers across all Supabase tables
-- Date: 2026-07-24

--------------------------------------------------------------------------------
-- 1. USERS TABLE
--------------------------------------------------------------------------------
ALTER TABLE users ADD COLUMN IF NOT EXISTS search_text text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fts tsvector;

CREATE OR REPLACE FUNCTION generate_users_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.name, '') || ' ' ||
    coalesce(NEW.email, '') || ' ' ||
    coalesce(NEW.phone, '') || ' ' ||
    coalesce(NEW.phone_country_code, '') || ' ' ||
    coalesce(NEW.phone_country_iso, '') || ' ' ||
    coalesce(NEW.role, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_search_text ON users;
CREATE TRIGGER trg_users_search_text
BEFORE INSERT OR UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION generate_users_search_text();

UPDATE users SET 
  search_text = lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(name, '') || ' ' ||
    coalesce(email, '') || ' ' ||
    coalesce(phone, '') || ' ' ||
    coalesce(phone_country_code, '') || ' ' ||
    coalesce(phone_country_iso, '') || ' ' ||
    coalesce(role, '')
  ),
  fts = to_tsvector('simple', lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(name, '') || ' ' ||
    coalesce(email, '') || ' ' ||
    coalesce(phone, '') || ' ' ||
    coalesce(phone_country_code, '') || ' ' ||
    coalesce(phone_country_iso, '') || ' ' ||
    coalesce(role, '')
  ));

CREATE INDEX IF NOT EXISTS idx_users_fts ON users USING gin (fts);

--------------------------------------------------------------------------------
-- 2. BROKERS TABLE
--------------------------------------------------------------------------------
ALTER TABLE brokers ADD COLUMN IF NOT EXISTS search_text text;
ALTER TABLE brokers ADD COLUMN IF NOT EXISTS fts tsvector;

CREATE OR REPLACE FUNCTION generate_brokers_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.business_name, '') || ' ' ||
    coalesce(NEW.plan, '') || ' ' ||
    coalesce(NEW.onboarding_status, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_brokers_search_text ON brokers;
CREATE TRIGGER trg_brokers_search_text
BEFORE INSERT OR UPDATE ON brokers
FOR EACH ROW EXECUTE FUNCTION generate_brokers_search_text();

UPDATE brokers SET 
  search_text = lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(business_name, '') || ' ' ||
    coalesce(plan, '') || ' ' ||
    coalesce(onboarding_status, '')
  ),
  fts = to_tsvector('simple', lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(business_name, '') || ' ' ||
    coalesce(plan, '') || ' ' ||
    coalesce(onboarding_status, '')
  ));

CREATE INDEX IF NOT EXISTS idx_brokers_fts ON brokers USING gin (fts);

--------------------------------------------------------------------------------
-- 3. PROPERTIES TABLE
--------------------------------------------------------------------------------
ALTER TABLE properties ADD COLUMN IF NOT EXISTS search_text text;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS fts tsvector;

CREATE OR REPLACE FUNCTION generate_properties_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.property_title, '') || ' ' ||
    coalesce(NEW.property_description, '') || ' ' ||
    coalesce(NEW.property_type, '') || ' ' ||
    coalesce(NEW.property_status, '') || ' ' ||
    coalesce(NEW.listing_type, '') || ' ' ||
    coalesce(NEW.furnishing_status, '') || ' ' ||
    coalesce(NEW.construction_status, '') || ' ' ||
    coalesce(NEW.facing, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_properties_search_text ON properties;
CREATE TRIGGER trg_properties_search_text
BEFORE INSERT OR UPDATE ON properties
FOR EACH ROW EXECUTE FUNCTION generate_properties_search_text();

UPDATE properties SET 
  search_text = lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(property_title, '') || ' ' ||
    coalesce(property_description, '') || ' ' ||
    coalesce(property_type, '') || ' ' ||
    coalesce(property_status, '') || ' ' ||
    coalesce(listing_type, '') || ' ' ||
    coalesce(furnishing_status, '') || ' ' ||
    coalesce(construction_status, '') || ' ' ||
    coalesce(facing, '')
  ),
  fts = to_tsvector('simple', lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(property_title, '') || ' ' ||
    coalesce(property_description, '') || ' ' ||
    coalesce(property_type, '') || ' ' ||
    coalesce(property_status, '') || ' ' ||
    coalesce(listing_type, '') || ' ' ||
    coalesce(furnishing_status, '') || ' ' ||
    coalesce(construction_status, '') || ' ' ||
    coalesce(facing, '')
  ));

CREATE INDEX IF NOT EXISTS idx_properties_fts ON properties USING gin (fts);

--------------------------------------------------------------------------------
-- 4. ADDRESSES TABLE
--------------------------------------------------------------------------------
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS search_text text;
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS fts tsvector;

CREATE OR REPLACE FUNCTION generate_addresses_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.full_address, '') || ' ' ||
    coalesce(NEW.landmark, '') || ' ' ||
    coalesce(NEW.city, '') || ' ' ||
    coalesce(NEW.state, '') || ' ' ||
    coalesce(NEW.country, '') || ' ' ||
    coalesce(NEW.pincode, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_addresses_search_text ON addresses;
CREATE TRIGGER trg_addresses_search_text
BEFORE INSERT OR UPDATE ON addresses
FOR EACH ROW EXECUTE FUNCTION generate_addresses_search_text();

UPDATE addresses SET 
  search_text = lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(full_address, '') || ' ' ||
    coalesce(landmark, '') || ' ' ||
    coalesce(city, '') || ' ' ||
    coalesce(state, '') || ' ' ||
    coalesce(country, '') || ' ' ||
    coalesce(pincode, '')
  ),
  fts = to_tsvector('simple', lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(full_address, '') || ' ' ||
    coalesce(landmark, '') || ' ' ||
    coalesce(city, '') || ' ' ||
    coalesce(state, '') || ' ' ||
    coalesce(country, '') || ' ' ||
    coalesce(pincode, '')
  ));

CREATE INDEX IF NOT EXISTS idx_addresses_fts ON addresses USING gin (fts);

--------------------------------------------------------------------------------
-- 5. SOCIAL_LEADS TABLE
--------------------------------------------------------------------------------
ALTER TABLE social_leads ADD COLUMN IF NOT EXISTS search_text text;
ALTER TABLE social_leads ADD COLUMN IF NOT EXISTS fts tsvector;

CREATE OR REPLACE FUNCTION generate_social_leads_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.user_name, '') || ' ' ||
    coalesce(NEW.contact_number, '') || ' ' ||
    coalesce(NEW.whatsapp_number, '') || ' ' ||
    coalesce(NEW.notes, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_social_leads_search_text ON social_leads;
CREATE TRIGGER trg_social_leads_search_text
BEFORE INSERT OR UPDATE ON social_leads
FOR EACH ROW EXECUTE FUNCTION generate_social_leads_search_text();

UPDATE social_leads SET 
  search_text = lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(user_name, '') || ' ' ||
    coalesce(contact_number, '') || ' ' ||
    coalesce(whatsapp_number, '') || ' ' ||
    coalesce(notes, '')
  ),
  fts = to_tsvector('simple', lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(user_name, '') || ' ' ||
    coalesce(contact_number, '') || ' ' ||
    coalesce(whatsapp_number, '') || ' ' ||
    coalesce(notes, '')
  ));

CREATE INDEX IF NOT EXISTS idx_social_leads_fts ON social_leads USING gin (fts);

--------------------------------------------------------------------------------
-- 6. SOCIAL_ACCOUNTS TABLE
--------------------------------------------------------------------------------
ALTER TABLE social_accounts ADD COLUMN IF NOT EXISTS search_text text;
ALTER TABLE social_accounts ADD COLUMN IF NOT EXISTS fts tsvector;

CREATE OR REPLACE FUNCTION generate_social_accounts_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.page_name, '') || ' ' ||
    coalesce(NEW.platform, '') || ' ' ||
    coalesce(NEW.page_id, '') || ' ' ||
    coalesce(NEW.instagram_username, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_social_accounts_search_text ON social_accounts;
CREATE TRIGGER trg_social_accounts_search_text
BEFORE INSERT OR UPDATE ON social_accounts
FOR EACH ROW EXECUTE FUNCTION generate_social_accounts_search_text();

UPDATE social_accounts SET 
  search_text = lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(page_name, '') || ' ' ||
    coalesce(platform, '') || ' ' ||
    coalesce(page_id, '') || ' ' ||
    coalesce(instagram_username, '')
  ),
  fts = to_tsvector('simple', lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(page_name, '') || ' ' ||
    coalesce(platform, '') || ' ' ||
    coalesce(page_id, '') || ' ' ||
    coalesce(instagram_username, '')
  ));

CREATE INDEX IF NOT EXISTS idx_social_accounts_fts ON social_accounts USING gin (fts);

--------------------------------------------------------------------------------
-- 7. SOCIAL_POSTS TABLE
--------------------------------------------------------------------------------
ALTER TABLE social_posts ADD COLUMN IF NOT EXISTS search_text text;
ALTER TABLE social_posts ADD COLUMN IF NOT EXISTS fts tsvector;

CREATE OR REPLACE FUNCTION generate_social_posts_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.caption, '') || ' ' ||
    coalesce(NEW.platform, '') || ' ' ||
    coalesce(NEW.post_id, '') || ' ' ||
    coalesce(NEW.page_id, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_social_posts_search_text ON social_posts;
CREATE TRIGGER trg_social_posts_search_text
BEFORE INSERT OR UPDATE ON social_posts
FOR EACH ROW EXECUTE FUNCTION generate_social_posts_search_text();

UPDATE social_posts SET 
  search_text = lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(caption, '') || ' ' ||
    coalesce(platform, '') || ' ' ||
    coalesce(post_id, '') || ' ' ||
    coalesce(page_id, '')
  ),
  fts = to_tsvector('simple', lower(
    coalesce(id::text, '') || ' ' ||
    coalesce(caption, '') || ' ' ||
    coalesce(platform, '') || ' ' ||
    coalesce(post_id, '') || ' ' ||
    coalesce(page_id, '')
  ));

CREATE INDEX IF NOT EXISTS idx_social_posts_fts ON social_posts USING gin (fts);
