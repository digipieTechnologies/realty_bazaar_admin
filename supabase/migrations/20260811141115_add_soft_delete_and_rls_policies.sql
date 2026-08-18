-- Migration: Add soft-delete columns (is_deleted, deleted_at) and configure restrictive RLS policies with super_admin bypass
-- Timestamp: 20260811141115

-- 1. Helper function to check if the current user is a super_admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean AS $$
BEGIN
  RETURN COALESCE(
    (SELECT role::text = 'super_admin' FROM public.users WHERE id = auth.uid()),
    false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Add is_deleted and deleted_at columns to tables that do not have them
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.social_accounts ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.social_accounts ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.social_posts ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.social_posts ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.social_leads ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.social_leads ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.video_requests ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.video_requests ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.attachments ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.attachments ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.chat_rooms ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.chat_rooms ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- 3. Enable RLS and add policies for tables with no previous RLS

-- public.users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access permissive" ON public.users;
CREATE POLICY "Allow all access permissive" ON public.users FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.users;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.users AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.brokers
ALTER TABLE public.brokers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access permissive" ON public.brokers;
CREATE POLICY "Allow all access permissive" ON public.brokers FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.brokers;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.brokers AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.addresses
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access permissive" ON public.addresses;
CREATE POLICY "Allow all access permissive" ON public.addresses FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.addresses;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.addresses AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.social_leads
ALTER TABLE public.social_leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access permissive" ON public.social_leads;
CREATE POLICY "Allow all access permissive" ON public.social_leads FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.social_leads;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.social_leads AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.properties
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access permissive" ON public.properties;
CREATE POLICY "Allow all access permissive" ON public.properties FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.properties;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.properties AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.chat_rooms
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access permissive" ON public.chat_rooms;
CREATE POLICY "Allow all access permissive" ON public.chat_rooms FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.chat_rooms;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.chat_rooms AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.chat_messages
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access permissive" ON public.chat_messages;
CREATE POLICY "Allow all access permissive" ON public.chat_messages FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.chat_messages;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.chat_messages AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access permissive" ON public.notifications;
CREATE POLICY "Allow all access permissive" ON public.notifications FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.notifications;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.notifications AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- 4. Add restrictive SELECT policies for tables with existing RLS

-- public.social_accounts
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.social_accounts;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.social_accounts AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.social_posts
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.social_posts;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.social_posts AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.video_requests
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.video_requests;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.video_requests AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- public.attachments
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.attachments;
CREATE POLICY "Enforce non-deleted on SELECT" ON public.attachments AS RESTRICTIVE FOR SELECT USING (public.is_super_admin() OR is_deleted IS NOT TRUE);

-- 5. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
