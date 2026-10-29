-- Migration: 20261029150000_grant_execute_marketing_and_admin_rpcs.sql
-- Description: Grant EXECUTE to authenticated and service_role for marketing teams and admin RPCs.

GRANT EXECUTE ON FUNCTION public.fetch_admin_marketing_teams(integer, integer, text, boolean, text, boolean, text, boolean) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.add_or_transfer_team_member(uuid, uuid, boolean) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.delete_marketing_team(uuid, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.assign_broker_to_team(uuid, uuid, uuid, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.fetch_marketing_brokers(integer, integer, text, text, boolean, text, boolean, uuid, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_marketing_dashboard_summary(boolean) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.execute_user_deletion(uuid, uuid, text, text) TO authenticated, service_role;
