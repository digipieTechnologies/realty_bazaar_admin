-- Migration: 20260923153500_drop_overloaded_fetch_video_requests.sql
-- Description: Drop obsolete overloads to resolve PostgREST PGRST203 ambiguity.

-- 1. Drop old 7-parameter overload of fetch_video_requests (superseded by 9-param scoped version)
DROP FUNCTION IF EXISTS public.fetch_video_requests(
  uuid,
  integer,
  integer,
  text,
  public.video_request_approval_status,
  public.video_request_status,
  text[]
);

-- 2. Drop old 3-parameter overload of execute_user_deletion (superseded by 4-param version with p_reason)
DROP FUNCTION IF EXISTS public.execute_user_deletion(
  uuid,
  uuid,
  text
);
