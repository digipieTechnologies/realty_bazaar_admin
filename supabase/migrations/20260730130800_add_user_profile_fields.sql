-- Migration: Add gender, date_of_birth, and notes to users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'male',
ADD COLUMN IF NOT EXISTS date_of_birth DATE,
ADD COLUMN IF NOT EXISTS notes TEXT;

NOTIFY pgrst, 'reload schema';

