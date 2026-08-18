-- Migration: Add cover_image to users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS cover_image JSONB;

NOTIFY pgrst, 'reload schema';

