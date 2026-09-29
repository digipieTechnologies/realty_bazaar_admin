-- Migration: 20260929170000_add_user_id_to_brokers.sql
-- Description: Add user_id to brokers table, establish FK to public.users(id), backfill existing data from users.broker_id, and update code generator and helper functions.

-- 1. Add user_id column to brokers
ALTER TABLE public.brokers
ADD COLUMN IF NOT EXISTS user_id UUID;

-- 2. Add Foreign Key Constraint with ON DELETE SET NULL
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'brokers_user_id_fkey'
  ) THEN
    ALTER TABLE public.brokers
    ADD CONSTRAINT brokers_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id)
    ON DELETE SET NULL;
  END IF;
END $$;

-- 3. Create Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_brokers_user_id ON public.brokers(user_id);

-- 4. Backfill existing records from public.users where users.broker_id = brokers.id
UPDATE public.brokers b
SET user_id = u.id,
    updated_at = NOW()
FROM public.users u
WHERE u.broker_id = b.id
  AND b.user_id IS NULL;

-- 5. Update broker code generator trigger to support NEW.user_id
CREATE OR REPLACE FUNCTION public.trg_broker_code_generator()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_user_name TEXT;
BEGIN
  -- If explicitly updating broker_code, preserve it
  IF TG_OP = 'UPDATE' THEN
    IF NEW.broker_code IS NOT NULL AND TRIM(NEW.broker_code) != '' AND NEW.broker_code IS DISTINCT FROM OLD.broker_code THEN
      NEW.broker_code := UPPER(TRIM(NEW.broker_code));
      RETURN NEW;
    END IF;
    IF OLD.broker_code IS NOT NULL AND TRIM(OLD.broker_code) != '' THEN
      NEW.broker_code := OLD.broker_code;
      RETURN NEW;
    END IF;
  END IF;

  -- Generate broker_code on INSERT or if empty
  IF NEW.broker_code IS NULL OR TRIM(NEW.broker_code) = '' THEN
    IF NEW.user_id IS NOT NULL THEN
      SELECT name INTO v_user_name
      FROM public.users
      WHERE id = NEW.user_id
      LIMIT 1;
    ELSE
      SELECT name INTO v_user_name
      FROM public.users
      WHERE broker_id = NEW.id
      LIMIT 1;
    END IF;

    NEW.broker_code := public.generate_unique_broker_code(NEW.business_name, v_user_name);
  ELSE
    NEW.broker_code := UPPER(TRIM(NEW.broker_code));
  END IF;

  RETURN NEW;
END;
$function$;

-- 6. Update helper function get_auth_broker_id()
CREATE OR REPLACE FUNCTION public.get_auth_broker_id()
RETURNS uuid
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT COALESCE(
    (SELECT id FROM public.brokers WHERE user_id = auth.uid() AND is_active = true AND is_deleted = false LIMIT 1),
    (SELECT broker_id FROM public.users WHERE id = auth.uid() AND is_active = true AND is_deleted = false LIMIT 1)
  );
$function$;

-- 7. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
