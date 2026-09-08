-- Migration: Create attachments table and user cover image column
CREATE TABLE IF NOT EXISTS public.attachments (
  id BIGSERIAL PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  url TEXT NOT NULL,
  r2_key TEXT,
  file_name TEXT,
  file_type TEXT,
  file_size BIGINT,
  is_cover BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attachments_entity ON public.attachments(entity_type, entity_id);

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS cover_image JSONB;

ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on attachments" ON public.attachments FOR SELECT USING (true);
CREATE POLICY "Allow authenticated insert/update/delete on attachments" ON public.attachments FOR ALL USING (true);
