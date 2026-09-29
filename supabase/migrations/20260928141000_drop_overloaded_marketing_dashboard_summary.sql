-- Migration: 20260928141000_drop_overloaded_marketing_dashboard_summary.sql
-- Description: Drop 0-arg overload of get_marketing_dashboard_summary to prevent PostgREST PGRST203 ambiguity.

DROP FUNCTION IF EXISTS public.get_marketing_dashboard_summary();
