-- Migration: 20260923143000_marketing_teams_admin_rpc.sql
-- Description: Admin RPCs for Marketing Teams CRUD, member transfer, safe deletion with broker reassignment, and paginated listing with KPIs.

-- 1. RPC: fetch_admin_marketing_teams
-- Returns paginated marketing teams, each enriched with members_count, brokers_count, lead_user, and high-level KPIs.
CREATE OR REPLACE FUNCTION public.fetch_admin_marketing_teams(
  p_page integer DEFAULT 1,
  p_limit integer DEFAULT 10,
  p_search text DEFAULT ''::text,
  p_is_active boolean DEFAULT NULL::boolean,
  p_territory text DEFAULT NULL::text,
  p_has_brokers boolean DEFAULT NULL::boolean,
  p_sort_by text DEFAULT 'created_at'::text,
  p_ascending boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_teams_json JSONB;
  -- Global KPI counters
  v_kpi_total_teams INT := 0;
  v_kpi_active_teams INT := 0;
  v_kpi_total_members INT := 0;
  v_kpi_assigned_brokers INT := 0;
  v_kpi_unassigned_brokers INT := 0;
BEGIN
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('success', false, 'message', 'Unauthorized: Only Super Admins can access marketing teams management.');
  END IF;

  v_offset := (p_page - 1) * p_limit;

  -- 1. Compute Global KPIs
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE is_active = true)
  INTO v_kpi_total_teams, v_kpi_active_teams
  FROM public.marketing_teams;

  SELECT COUNT(DISTINCT user_id)
  INTO v_kpi_total_members
  FROM public.marketing_team_members;

  SELECT 
    COUNT(*) FILTER (WHERE marketing_team_id IS NOT NULL),
    COUNT(*) FILTER (WHERE marketing_team_id IS NULL)
  INTO v_kpi_assigned_brokers, v_kpi_unassigned_brokers
  FROM public.brokers
  WHERE is_deleted = false;

  -- 2. Count filtered items
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.marketing_teams mt
  WHERE (p_is_active IS NULL OR mt.is_active = p_is_active)
    AND (p_territory IS NULL OR p_territory = '' OR mt.territory ILIKE '%' || p_territory || '%')
    AND (
      p_has_brokers IS NULL OR
      (p_has_brokers IS TRUE AND EXISTS (SELECT 1 FROM public.brokers b WHERE b.marketing_team_id = mt.id AND b.is_deleted = false)) OR
      (p_has_brokers IS FALSE AND NOT EXISTS (SELECT 1 FROM public.brokers b WHERE b.marketing_team_id = mt.id AND b.is_deleted = false))
    )
    AND (
      p_search = '' OR
      mt.name ILIKE '%' || p_search || '%' OR
      mt.territory ILIKE '%' || p_search || '%' OR
      mt.description ILIKE '%' || p_search || '%'
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 3. Fetch paginated enriched teams
  SELECT COALESCE(jsonb_agg(
    to_jsonb(t_data) ||
    jsonb_build_object(
      'members_count', COALESCE(m_counts.cnt, 0),
      'brokers_count', COALESCE(b_counts.cnt, 0),
      'lead_user', CASE WHEN l_user.id IS NOT NULL THEN to_jsonb(l_user) ELSE NULL END
    )
    ORDER BY
      CASE WHEN p_ascending AND p_sort_by = 'name' THEN t_data.name END ASC,
      CASE WHEN NOT p_ascending AND p_sort_by = 'name' THEN t_data.name END DESC,
      CASE WHEN p_ascending AND p_sort_by = 'territory' THEN t_data.territory END ASC,
      CASE WHEN NOT p_ascending AND p_sort_by = 'territory' THEN t_data.territory END DESC,
      CASE WHEN p_ascending AND p_sort_by = 'created_at' THEN t_data.created_at END ASC,
      CASE WHEN NOT p_ascending AND (p_sort_by IS NULL OR p_sort_by = 'created_at') THEN t_data.created_at END DESC,
      t_data.id DESC
  ), '[]'::jsonb)
  INTO v_teams_json
  FROM (
    SELECT mt.*
    FROM public.marketing_teams mt
    WHERE (p_is_active IS NULL OR mt.is_active = p_is_active)
      AND (p_territory IS NULL OR p_territory = '' OR mt.territory ILIKE '%' || p_territory || '%')
      AND (
        p_has_brokers IS NULL OR
        (p_has_brokers IS TRUE AND EXISTS (SELECT 1 FROM public.brokers b WHERE b.marketing_team_id = mt.id AND b.is_deleted = false)) OR
        (p_has_brokers IS FALSE AND NOT EXISTS (SELECT 1 FROM public.brokers b WHERE b.marketing_team_id = mt.id AND b.is_deleted = false))
      )
      AND (
        p_search = '' OR
        mt.name ILIKE '%' || p_search || '%' OR
        mt.territory ILIKE '%' || p_search || '%' OR
        mt.description ILIKE '%' || p_search || '%'
      )
    ORDER BY
      CASE WHEN p_ascending AND p_sort_by = 'name' THEN mt.name END ASC,
      CASE WHEN NOT p_ascending AND p_sort_by = 'name' THEN mt.name END DESC,
      CASE WHEN p_ascending AND p_sort_by = 'territory' THEN mt.territory END ASC,
      CASE WHEN NOT p_ascending AND p_sort_by = 'territory' THEN mt.territory END DESC,
      CASE WHEN p_ascending AND p_sort_by = 'created_at' THEN mt.created_at END ASC,
      CASE WHEN NOT p_ascending AND (p_sort_by IS NULL OR p_sort_by = 'created_at') THEN mt.created_at END DESC,
      mt.id DESC
    LIMIT p_limit OFFSET v_offset
  ) t_data
  LEFT JOIN LATERAL (
    SELECT COUNT(*)::INT AS cnt FROM public.marketing_team_members WHERE team_id = t_data.id
  ) m_counts ON true
  LEFT JOIN LATERAL (
    SELECT COUNT(*)::INT AS cnt FROM public.brokers WHERE marketing_team_id = t_data.id AND is_deleted = false
  ) b_counts ON true
  LEFT JOIN LATERAL (
    SELECT u.*
    FROM public.marketing_team_members mtm
    JOIN public.users u ON mtm.user_id = u.id
    WHERE mtm.team_id = t_data.id AND mtm.is_lead = true
    LIMIT 1
  ) l_user ON true;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_teams_json,
    'kpis', jsonb_build_object(
      'total_teams', v_kpi_total_teams,
      'active_teams', v_kpi_active_teams,
      'total_members', v_kpi_total_members,
      'assigned_brokers', v_kpi_assigned_brokers,
      'unassigned_brokers', v_kpi_unassigned_brokers
    ),
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$function$;

-- 2. RPC: add_or_transfer_team_member
-- Enforces single-team membership by automatically removing user from any previous team.
CREATE OR REPLACE FUNCTION public.add_or_transfer_team_member(
  p_team_id UUID,
  p_user_id UUID,
  p_is_lead BOOLEAN DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_team_name TEXT;
BEGIN
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('success', false, 'message', 'Unauthorized: Only Super Admins can manage team members.');
  END IF;

  -- Check if user is in another team
  SELECT mt.name INTO v_old_team_name
  FROM public.marketing_team_members mtm
  JOIN public.marketing_teams mt ON mtm.team_id = mt.id
  WHERE mtm.user_id = p_user_id AND mtm.team_id != p_team_id
  LIMIT 1;

  IF v_old_team_name IS NOT NULL THEN
    -- Remove from existing team
    DELETE FROM public.marketing_team_members WHERE user_id = p_user_id;
  END IF;

  -- If setting as lead, unset existing lead in this team
  IF p_is_lead IS TRUE THEN
    UPDATE public.marketing_team_members SET is_lead = false WHERE team_id = p_team_id;
  END IF;

  -- Insert or update in target team
  INSERT INTO public.marketing_team_members (team_id, user_id, is_lead)
  VALUES (p_team_id, p_user_id, p_is_lead)
  ON CONFLICT (team_id, user_id) DO UPDATE SET is_lead = EXCLUDED.is_lead;

  RETURN jsonb_build_object(
    'success', true,
    'transferred_from', v_old_team_name,
    'message', CASE 
      WHEN v_old_team_name IS NOT NULL THEN 'Member transferred from ' || v_old_team_name || ' to this team.'
      ELSE 'Member added to team.'
    END
  );
END;
$$;

-- 3. RPC: delete_marketing_team
-- Safely deletes a marketing team, reassigning attached brokers to p_reassign_team_id (or NULL).
CREATE OR REPLACE FUNCTION public.delete_marketing_team(
  p_team_id UUID,
  p_reassign_team_id UUID DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_affected_brokers INT := 0;
BEGIN
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('success', false, 'message', 'Unauthorized: Only Super Admins can delete marketing teams.');
  END IF;

  IF p_reassign_team_id IS NOT NULL AND p_reassign_team_id = p_team_id THEN
    RETURN jsonb_build_object('success', false, 'message', 'Cannot reassign brokers to the team being deleted.');
  END IF;

  -- 1. Reassign or unassign brokers
  UPDATE public.brokers
  SET 
    marketing_team_id = p_reassign_team_id,
    primary_marketing_user_id = CASE WHEN p_reassign_team_id IS NULL THEN NULL ELSE primary_marketing_user_id END,
    updated_at = timezone('utc'::text, now())
  WHERE marketing_team_id = p_team_id;

  GET DIAGNOSTICS v_affected_brokers = ROW_COUNT;

  -- 2. Delete team members (cascades via foreign key, but delete explicitly for safety)
  DELETE FROM public.marketing_team_members WHERE team_id = p_team_id;

  -- 3. Delete the team
  DELETE FROM public.marketing_teams WHERE id = p_team_id;

  RETURN jsonb_build_object(
    'success', true,
    'affected_brokers', v_affected_brokers,
    'message', 'Team deleted successfully. ' || v_affected_brokers || ' brokers updated.'
  );
END;
$$;
