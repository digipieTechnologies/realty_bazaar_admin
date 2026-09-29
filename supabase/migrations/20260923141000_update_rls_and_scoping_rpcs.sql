-- Migration: 20260923141000_update_rls_and_scoping_rpcs.sql
-- Description: Helper functions, team scoping for video requests, dashboard summary, fetch_marketing_brokers RPC, and admin assignment RPC.

-- 1. Helper function: Get team IDs for current authenticated user
CREATE OR REPLACE FUNCTION public.get_auth_marketing_team_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT team_id 
  FROM public.marketing_team_members 
  WHERE user_id = auth.uid();
$$;

-- 2. Helper function: Check if current user has marketing role
CREATE OR REPLACE FUNCTION public.is_marketing_user()
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM public.users 
    WHERE id = auth.uid() 
      AND role = 'marketing'
      AND is_active = true 
      AND is_deleted = false
  );
$$;

-- 3. RLS for marketing_teams and marketing_team_members
ALTER TABLE public.marketing_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketing_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broker_assignment_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "marketing_teams_admin_all" ON public.marketing_teams;
CREATE POLICY "marketing_teams_admin_all" ON public.marketing_teams
FOR ALL TO authenticated 
USING (public.is_admin()) 
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "marketing_teams_authenticated_select" ON public.marketing_teams;
CREATE POLICY "marketing_teams_authenticated_select" ON public.marketing_teams
FOR SELECT TO authenticated 
USING (is_active = true);

DROP POLICY IF EXISTS "marketing_team_members_admin_all" ON public.marketing_team_members;
CREATE POLICY "marketing_team_members_admin_all" ON public.marketing_team_members
FOR ALL TO authenticated 
USING (public.is_admin()) 
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "marketing_team_members_authenticated_select" ON public.marketing_team_members;
CREATE POLICY "marketing_team_members_authenticated_select" ON public.marketing_team_members
FOR SELECT TO authenticated 
USING (true);

DROP POLICY IF EXISTS "broker_assignment_history_select" ON public.broker_assignment_history;
CREATE POLICY "broker_assignment_history_select" ON public.broker_assignment_history
FOR SELECT TO authenticated 
USING (
  public.is_admin() OR 
  broker_id IN (
    SELECT id FROM public.brokers 
    WHERE marketing_team_id IN (SELECT public.get_auth_marketing_team_ids())
  )
);

-- 4. RPC: fetch_marketing_brokers
-- Returns paginated brokers strictly scoped by caller role:
-- Super Admin sees all (with optional team filter), Marketing user sees only their assigned team's brokers.
CREATE OR REPLACE FUNCTION public.fetch_marketing_brokers(
  p_page integer DEFAULT 1,
  p_limit integer DEFAULT 10,
  p_search text DEFAULT ''::text,
  p_sort_by text DEFAULT 'created_at'::text,
  p_ascending boolean DEFAULT false,
  p_onboarding_status text DEFAULT NULL::text,
  p_is_active boolean DEFAULT NULL::boolean,
  p_marketing_team_id uuid DEFAULT NULL::uuid,
  p_primary_marketing_user_id uuid DEFAULT NULL::uuid
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
  v_brokers_json JSONB;
  v_is_admin BOOLEAN;
  v_is_marketing BOOLEAN;
BEGIN
  v_offset := (p_page - 1) * p_limit;
  v_is_admin := public.is_admin();
  v_is_marketing := public.is_marketing_user();

  -- 1. Calculate total items with strict team scoping
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.brokers b
  LEFT JOIN public.addresses a ON b.address_id = a.id
  WHERE (b.is_deleted IS FALSE OR b.is_deleted IS NULL)
    AND (p_is_active IS NULL OR b.is_active = p_is_active)
    AND (p_onboarding_status IS NULL OR b.onboarding_status = p_onboarding_status)
    AND (
      -- Super Admin: can see all or filter by team
      (v_is_admin AND (p_marketing_team_id IS NULL OR b.marketing_team_id = p_marketing_team_id))
      OR
      -- Marketing User: MUST be assigned to their team(s)
      (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
    )
    AND (p_primary_marketing_user_id IS NULL OR b.primary_marketing_user_id = p_primary_marketing_user_id)
    AND (
      p_search = '' OR
      b.business_name ILIKE '%' || p_search || '%' OR
      b.broker_code ILIKE '%' || p_search || '%' OR
      (a.id IS NOT NULL AND (
        a.city ILIKE '%' || p_search || '%' OR
        a.state ILIKE '%' || p_search || '%' OR
        a.full_address ILIKE '%' || p_search || '%'
      ))
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch brokers with joined address, marketing_team, and primary_marketing_user
  SELECT COALESCE(jsonb_agg(
    to_jsonb(b_row) ||
    jsonb_build_object(
      'address', CASE WHEN a_row.id IS NOT NULL THEN to_jsonb(a_row) ELSE NULL END,
      'address_id', CASE WHEN a_row.id IS NOT NULL THEN to_jsonb(a_row) ELSE NULL END,
      'marketing_team', CASE WHEN mt_row.id IS NOT NULL THEN to_jsonb(mt_row) ELSE NULL END,
      'primary_marketing_user', CASE WHEN pu_row.id IS NOT NULL THEN to_jsonb(pu_row) ELSE NULL END
    )
    ORDER BY
      CASE WHEN p_ascending AND p_sort_by = 'business_name' THEN b_row.business_name END ASC,
      CASE WHEN NOT p_ascending AND p_sort_by = 'business_name' THEN b_row.business_name END DESC,
      CASE WHEN p_ascending AND p_sort_by = 'created_at' THEN b_row.created_at END ASC,
      CASE WHEN NOT p_ascending AND (p_sort_by IS NULL OR p_sort_by = 'created_at') THEN b_row.created_at END DESC,
      b_row.id DESC
  ), '[]'::jsonb)
  INTO v_brokers_json
  FROM (
    SELECT b.*
    FROM public.brokers b
    LEFT JOIN public.addresses a ON b.address_id = a.id
    WHERE (b.is_deleted IS FALSE OR b.is_deleted IS NULL)
      AND (p_is_active IS NULL OR b.is_active = p_is_active)
      AND (p_onboarding_status IS NULL OR b.onboarding_status = p_onboarding_status)
      AND (
        (v_is_admin AND (p_marketing_team_id IS NULL OR b.marketing_team_id = p_marketing_team_id))
        OR
        (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      )
      AND (p_primary_marketing_user_id IS NULL OR b.primary_marketing_user_id = p_primary_marketing_user_id)
      AND (
        p_search = '' OR
        b.business_name ILIKE '%' || p_search || '%' OR
        b.broker_code ILIKE '%' || p_search || '%' OR
        (a.id IS NOT NULL AND (
          a.city ILIKE '%' || p_search || '%' OR
          a.state ILIKE '%' || p_search || '%' OR
          a.full_address ILIKE '%' || p_search || '%'
        ))
      )
    ORDER BY
      CASE WHEN p_ascending AND p_sort_by = 'business_name' THEN b.business_name END ASC,
      CASE WHEN NOT p_ascending AND p_sort_by = 'business_name' THEN b.business_name END DESC,
      CASE WHEN p_ascending AND p_sort_by = 'created_at' THEN b.created_at END ASC,
      CASE WHEN NOT p_ascending AND (p_sort_by IS NULL OR p_sort_by = 'created_at') THEN b.created_at END DESC,
      b.id DESC
    LIMIT p_limit OFFSET v_offset
  ) b_row
  LEFT JOIN public.addresses a_row ON b_row.address_id = a_row.id
  LEFT JOIN public.marketing_teams mt_row ON b_row.marketing_team_id = mt_row.id
  LEFT JOIN public.users pu_row ON b_row.primary_marketing_user_id = pu_row.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_brokers_json,
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

-- 5. Updated RPC: fetch_video_requests with team scoping
CREATE OR REPLACE FUNCTION public.fetch_video_requests(
  p_broker_id uuid DEFAULT NULL::uuid,
  p_page integer DEFAULT 1,
  p_limit integer DEFAULT 10,
  p_search_query text DEFAULT ''::text,
  p_admin_approved_status video_request_approval_status DEFAULT NULL::video_request_approval_status,
  p_status video_request_status DEFAULT NULL::video_request_status,
  p_statuses text[] DEFAULT NULL::text[],
  p_marketing_team_id uuid DEFAULT NULL::uuid,
  p_primary_marketing_user_id uuid DEFAULT NULL::uuid
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
  v_requests_json JSONB;
  v_is_admin BOOLEAN;
  v_is_marketing BOOLEAN;
BEGIN
  v_offset := (p_page - 1) * p_limit;
  v_is_admin := public.is_admin();
  v_is_marketing := public.is_marketing_user();

  -- 1. Calculate total items
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
    AND (
      -- If Super Admin: can see all, or filter by specific team if requested
      (v_is_admin AND (p_marketing_team_id IS NULL OR b.marketing_team_id = p_marketing_team_id))
      OR
      -- If Marketing User: MUST be assigned to the broker's team
      (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      OR
      -- If Broker: can only see their own broker requests
      (vr.broker_id = public.get_auth_broker_id())
    )
    AND (p_primary_marketing_user_id IS NULL OR b.primary_marketing_user_id = p_primary_marketing_user_id)
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch video requests with nested property, broker, address, team, and handler
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END,
        'marketing_team',
        CASE
          WHEN mt_data.id IS NOT NULL THEN to_jsonb(mt_data)
          ELSE NULL
        END,
        'primary_marketing_user',
        CASE
          WHEN pu_data.id IS NOT NULL THEN to_jsonb(pu_data)
          ELSE NULL
        END
      ),
      'cancelled_by_user_id',
      CASE
        WHEN u_data.id IS NOT NULL THEN to_jsonb(u_data)
        ELSE NULL
      END
    )
    ORDER BY vr_data.created_at DESC, vr_data.id DESC
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
      AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
      AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
      AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
      AND (p_status IS NULL OR vr.status = p_status)
      AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
      AND (
        (v_is_admin AND (p_marketing_team_id IS NULL OR b.marketing_team_id = p_marketing_team_id))
        OR
        (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
        OR
        (vr.broker_id = public.get_auth_broker_id())
      )
      AND (p_primary_marketing_user_id IS NULL OR b.primary_marketing_user_id = p_primary_marketing_user_id)
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY vr.created_at DESC, vr.id DESC
    LIMIT p_limit OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.users u_data ON vr_data.cancelled_by_user_id = u_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id
  LEFT JOIN public.marketing_teams mt_data ON b_data.marketing_team_id = mt_data.id
  LEFT JOIN public.users pu_data ON b_data.primary_marketing_user_id = pu_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
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

-- 6. Updated RPC: fetch_video_request_counts with team scoping
CREATE OR REPLACE FUNCTION public.fetch_video_request_counts(
  p_broker_id uuid DEFAULT NULL::uuid, 
  p_admin_approved_status video_request_approval_status DEFAULT NULL::video_request_approval_status, 
  p_status video_request_status DEFAULT NULL::video_request_status
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_total INT;
  v_pending INT;
  v_in_progress INT;
  v_completed INT;
  v_cancelled INT;
  v_is_admin BOOLEAN;
  v_is_marketing BOOLEAN;
BEGIN
  v_is_admin := public.is_admin();
  v_is_marketing := public.is_marketing_user();

  -- Total count includes all non-deleted matching requests
  SELECT COUNT(*) INTO v_total
  FROM public.video_requests vr
  JOIN public.brokers b ON vr.broker_id = b.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (
      v_is_admin
      OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      OR (vr.broker_id = public.get_auth_broker_id())
    );

  -- Pending count
  SELECT COUNT(*) INTO v_pending
  FROM public.video_requests vr
  JOIN public.brokers b ON vr.broker_id = b.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND vr.status = 'pending'::public.video_request_status
    AND (
      v_is_admin
      OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      OR (vr.broker_id = public.get_auth_broker_id())
    );

  -- In-progress count
  SELECT COUNT(*) INTO v_in_progress
  FROM public.video_requests vr
  JOIN public.brokers b ON vr.broker_id = b.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND vr.status IN ('assigned'::public.video_request_status, 'in_progress'::public.video_request_status)
    AND (
      v_is_admin
      OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      OR (vr.broker_id = public.get_auth_broker_id())
    );

  -- Completed count
  SELECT COUNT(*) INTO v_completed
  FROM public.video_requests vr
  JOIN public.brokers b ON vr.broker_id = b.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND vr.status = 'completed'::public.video_request_status
    AND (
      v_is_admin
      OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      OR (vr.broker_id = public.get_auth_broker_id())
    );

  -- Cancelled count
  SELECT COUNT(*) INTO v_cancelled
  FROM public.video_requests vr
  JOIN public.brokers b ON vr.broker_id = b.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND vr.status = 'cancelled'::public.video_request_status
    AND (
      v_is_admin
      OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      OR (vr.broker_id = public.get_auth_broker_id())
    );

  RETURN jsonb_build_object(
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed,
    'cancelled', v_cancelled
  );
END;
$function$;

-- 7. Updated RPC: get_marketing_dashboard_summary with team scoping
CREATE OR REPLACE FUNCTION public.get_marketing_dashboard_summary()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result jsonb;
    v_total_brokers integer := 0;
    v_active_brokers integer := 0;
    v_total_properties integer := 0;
    v_properties_with_media integer := 0;
    v_pending_requests integer := 0;
    v_in_progress_requests integer := 0;
    v_completed_requests integer := 0;
    v_pending_approval_requests integer := 0;
    v_total_social_posts integer := 0;
    v_total_views bigint := 0;
    v_total_likes bigint := 0;
    v_recent_requests jsonb := '[]'::jsonb;
    v_recent_properties jsonb := '[]'::jsonb;
    v_is_admin boolean;
    v_is_marketing boolean;
BEGIN
    v_is_admin := public.is_admin();
    v_is_marketing := public.is_marketing_user();

    -- 1. Broker metrics
    SELECT 
        COALESCE(COUNT(*), 0),
        COALESCE(COUNT(*) FILTER (WHERE b.is_active = true), 0)
    INTO v_total_brokers, v_active_brokers
    FROM public.brokers b
    WHERE b.is_deleted = false
      AND (
        v_is_admin
        OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      );

    -- 2. Property metrics & media readiness
    SELECT 
        COALESCE(COUNT(*), 0),
        COALESCE(COUNT(*) FILTER (WHERE p.medias IS NOT NULL AND jsonb_typeof(p.medias) = 'array' AND jsonb_array_length(p.medias) > 0), 0)
    INTO v_total_properties, v_properties_with_media
    FROM public.properties p
    JOIN public.brokers b ON p.broker_id = b.id
    WHERE p.is_deleted = false
      AND (
        v_is_admin
        OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      );

    -- 3. Video request pipeline metrics
    SELECT 
        COALESCE(COUNT(*) FILTER (WHERE vr.status = 'pending'), 0),
        COALESCE(COUNT(*) FILTER (WHERE vr.status = 'in_progress'), 0),
        COALESCE(COUNT(*) FILTER (WHERE vr.status = 'completed'), 0),
        COALESCE(COUNT(*) FILTER (WHERE vr.admin_approval_status = 'pending'), 0)
    INTO v_pending_requests, v_in_progress_requests, v_completed_requests, v_pending_approval_requests
    FROM public.video_requests vr
    JOIN public.brokers b ON vr.broker_id = b.id
    WHERE vr.is_deleted = false
      AND (
        v_is_admin
        OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      );

    -- 4. Social media engagement metrics
    SELECT 
        COALESCE(COUNT(*), 0),
        COALESCE(SUM(sp.views_count), 0),
        COALESCE(SUM(sp.likes_count), 0)
    INTO v_total_social_posts, v_total_views, v_total_likes
    FROM public.social_posts sp
    JOIN public.brokers b ON sp.broker_id = b.id
    WHERE sp.is_deleted = false
      AND (
        v_is_admin
        OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      );

    -- 5. Recent pending video requests (top 5 with joined property, broker, team)
    SELECT COALESCE(jsonb_agg(vr_item), '[]'::jsonb)
    INTO v_recent_requests
    FROM (
        SELECT 
            vr.id,
            vr.status,
            vr.admin_approval_status,
            vr.notes,
            vr.created_at,
            vr.updated_at,
            jsonb_build_object(
                'id', p.id,
                'property_title', p.property_title,
                'price', p.price,
                'bedrooms', p.bedrooms,
                'bathrooms', p.bathrooms,
                'medias', COALESCE(p.medias, '[]'::jsonb)
            ) AS property,
            jsonb_build_object(
                'id', b.id,
                'business_name', b.business_name,
                'marketing_team_id', b.marketing_team_id,
                'primary_marketing_user_id', b.primary_marketing_user_id
            ) AS broker
        FROM public.video_requests vr
        LEFT JOIN public.properties p ON p.id = vr.property_id
        LEFT JOIN public.brokers b ON b.id = vr.broker_id
        WHERE vr.is_deleted = false 
          AND vr.status = 'pending'
          AND (
            v_is_admin
            OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
          )
        ORDER BY vr.created_at DESC
        LIMIT 5
    ) vr_item;

    -- 6. Recent added properties (top 5 with joined broker)
    SELECT COALESCE(jsonb_agg(prop_item), '[]'::jsonb)
    INTO v_recent_properties
    FROM (
        SELECT 
            p.id,
            p.property_title,
            p.price,
            p.listing_type,
            p.property_type,
            p.bedrooms,
            p.bathrooms,
            p.area,
            p.area_unit,
            COALESCE(p.medias, '[]'::jsonb) AS medias,
            p.created_at,
            jsonb_build_object(
                'id', b.id,
                'business_name', b.business_name
            ) AS broker_id
        FROM public.properties p
        LEFT JOIN public.brokers b ON b.id = p.broker_id
        WHERE p.is_deleted = false
          AND (
            v_is_admin
            OR (v_is_marketing AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
          )
        ORDER BY p.created_at DESC
        LIMIT 5
    ) prop_item;

    -- Assemble full response
    result := jsonb_build_object(
        'kpis', jsonb_build_object(
            'total_brokers', v_total_brokers,
            'active_brokers', v_active_brokers,
            'total_properties', v_total_properties,
            'properties_with_media', v_properties_with_media,
            'pending_video_requests', v_pending_requests,
            'in_progress_video_requests', v_in_progress_requests,
            'completed_video_requests', v_completed_requests,
            'pending_approval_requests', v_pending_approval_requests,
            'total_social_posts', v_total_social_posts,
            'total_social_views', v_total_views,
            'total_social_likes', v_total_likes
        ),
        'recent_pending_requests', v_recent_requests,
        'recent_properties', v_recent_properties
    );

    RETURN result;
END;
$$;

-- 8. RPC: assign_broker_to_team (Admin assignment atomic operation)
CREATE OR REPLACE FUNCTION public.assign_broker_to_team(
    p_broker_id UUID,
    p_team_id UUID DEFAULT NULL,
    p_primary_user_id UUID DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RETURN jsonb_build_object('success', false, 'message', 'Unauthorized: Only Super Admins can assign brokers.');
    END IF;

    -- Verify broker exists
    IF NOT EXISTS (SELECT 1 FROM public.brokers WHERE id = p_broker_id AND is_deleted = false) THEN
        RETURN jsonb_build_object('success', false, 'message', 'Broker not found or deleted.');
    END IF;

    -- If p_team_id is provided, verify it exists and is active
    IF p_team_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.marketing_teams WHERE id = p_team_id AND is_active = true) THEN
        RETURN jsonb_build_object('success', false, 'message', 'Invalid or inactive marketing team.');
    END IF;

    -- If p_primary_user_id is provided, verify user is a member of that team
    IF p_primary_user_id IS NOT NULL THEN
        IF p_team_id IS NULL THEN
            RETURN jsonb_build_object('success', false, 'message', 'Cannot assign a primary representative without a team.');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM public.marketing_team_members WHERE team_id = p_team_id AND user_id = p_primary_user_id) THEN
            RETURN jsonb_build_object('success', false, 'message', 'Selected representative is not a member of this marketing team.');
        END IF;
    END IF;

    UPDATE public.brokers
    SET 
        marketing_team_id = p_team_id,
        primary_marketing_user_id = p_primary_user_id,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_broker_id;

    RETURN jsonb_build_object('success', true, 'message', 'Broker assignment successfully updated.');
END;
$$;
