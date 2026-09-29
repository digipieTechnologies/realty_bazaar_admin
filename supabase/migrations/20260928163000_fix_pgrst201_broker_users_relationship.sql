-- Migration: 20260928163000_fix_pgrst201_broker_users_relationship.sql
-- Description: Drop brokers_primary_marketing_user_id_fkey constraint to resolve PostgREST PGRST201 ambiguity when embedding brokers.users on public queries.

ALTER TABLE public.brokers DROP CONSTRAINT IF EXISTS brokers_primary_marketing_user_id_fkey;

NOTIFY pgrst, 'reload schema';
