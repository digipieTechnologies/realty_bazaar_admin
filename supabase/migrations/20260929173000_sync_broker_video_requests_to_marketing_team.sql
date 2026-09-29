-- Migration: 20260929173000_sync_broker_video_requests_to_marketing_team.sql
-- Description: Add marketing_team_id and primary_marketing_user_id to video_requests,
--              backfill existing requests, create auto-assignment trigger, and update
--              assign_broker_to_team, fetch_video_requests, and fetch_video_request_counts RPCs.

-- 1. Add team assignment columns to public.video_requests
ALTER TABLE public.video_requests
ADD COLUMN IF NOT EXISTS marketing_team_id UUID REFERENCES public.marketing_teams(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS primary_marketing_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_video_requests_marketing_team_id ON public.video_requests(marketing_team_id);
CREATE INDEX IF NOT EXISTS idx_video_requests_primary_marketing_user_id ON public.video_requests(primary_marketing_user_id);

-- 2. Backfill existing video_requests from the broker's current assignment
UPDATE public.video_requests vr
SET marketing_team_id = b.marketing_team_id,
    primary_marketing_user_id = b.primary_marketing_user_id,
    updated_at = timezone('utc'::text, now())
FROM public.brokers b
WHERE vr.broker_id = b.id
  AND b.marketing_team_id IS NOT NULL
  AND vr.marketing_team_id IS NULL;

-- 3. Trigger to automatically inherit broker's marketing team when a new video request is inserted
CREATE OR REPLACE FUNCTION public.handle_video_request_marketing_team_defaults()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.marketing_team_id IS NULL AND NEW.broker_id IS NOT NULL THEN
        SELECT marketing_team_id, primary_marketing_user_id
        INTO NEW.marketing_team_id, NEW.primary_marketing_user_id
        FROM public.brokers
        WHERE id = NEW.broker_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_video_request_team ON public.video_requests;
CREATE TRIGGER trg_set_video_request_team
BEFORE INSERT ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.handle_video_request_marketing_team_defaults();

-- 4. Update assign_broker_to_team to atomically sync broker's video requests
CREATE OR REPLACE FUNCTION public.assign_broker_to_team(
    p_broker_id uuid,
    p_team_id uuid DEFAULT NULL,
    p_primary_user_id uuid DEFAULT NULL,
    p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_old_team_id uuid;
    v_old_primary_user_id uuid;
    v_target_primary_user_id uuid;
    v_updated_requests_count integer := 0;
BEGIN
    IF NOT public.is_admin() THEN
        RETURN jsonb_build_object('success', false, 'message', 'Unauthorized: Only Super Admins can assign brokers.');
    END IF;

    -- Verify broker exists
    SELECT marketing_team_id, primary_marketing_user_id
    INTO v_old_team_id, v_old_primary_user_id
    FROM public.brokers
    WHERE id = p_broker_id AND (is_deleted IS FALSE OR is_deleted IS NULL);

    IF NOT FOUND THEN
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

    v_target_primary_user_id := CASE WHEN p_team_id IS NULL THEN NULL ELSE p_primary_user_id END;

    -- Update broker
    UPDATE public.brokers
    SET 
        marketing_team_id = p_team_id,
        primary_marketing_user_id = v_target_primary_user_id,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_broker_id;

    -- Atomically assign all video requests of this broker to the new team & representative
    UPDATE public.video_requests
    SET 
        marketing_team_id = p_team_id,
        primary_marketing_user_id = v_target_primary_user_id,
        updated_at = timezone('utc'::text, now())
    WHERE broker_id = p_broker_id;

    GET DIAGNOSTICS v_updated_requests_count = ROW_COUNT;

    -- Update audit log notes if an audit entry was created for this change
    IF p_notes IS NOT NULL AND p_notes <> '' THEN
        UPDATE public.broker_assignment_history
        SET notes = p_notes
        WHERE id = (
            SELECT id FROM public.broker_assignment_history
            WHERE broker_id = p_broker_id
            ORDER BY created_at DESC
            LIMIT 1
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Broker and video requests successfully assigned.',
        'broker_id', p_broker_id,
        'team_id', p_team_id,
        'primary_user_id', v_target_primary_user_id,
        'synced_video_requests', v_updated_requests_count
    );
END;
$$;

-- 5. Updated RPC: fetch_video_requests with team scoping using vr.marketing_team_id
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
      (v_is_admin AND (p_marketing_team_id IS NULL OR COALESCE(vr.marketing_team_id, b.marketing_team_id) = p_marketing_team_id))
      OR
      -- If Marketing User: MUST be assigned to the video request or broker's team
      (v_is_marketing AND (
        (vr.marketing_team_id IS NOT NULL AND vr.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
        OR
        (b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      ))
      OR
      -- If Broker: can only see their own broker requests
      (vr.broker_id = public.get_auth_broker_id())
    )
    AND (p_primary_marketing_user_id IS NULL OR COALESCE(vr.primary_marketing_user_id, b.primary_marketing_user_id) = p_primary_marketing_user_id)
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
      'marketing_team',
      CASE 
        WHEN vr_mt.id IS NOT NULL THEN to_jsonb(vr_mt)
        WHEN mt_data.id IS NOT NULL THEN to_jsonb(mt_data)
        ELSE NULL
      END,
      'primary_marketing_user',
      CASE 
        WHEN vr_pu.id IS NOT NULL THEN to_jsonb(vr_pu)
        WHEN pu_data.id IS NOT NULL THEN to_jsonb(pu_data)
        ELSE NULL
      END,
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
        (v_is_admin AND (p_marketing_team_id IS NULL OR COALESCE(vr.marketing_team_id, b.marketing_team_id) = p_marketing_team_id))
        OR
        (v_is_marketing AND (
          (vr.marketing_team_id IS NOT NULL AND vr.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
          OR
          (b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
        ))
        OR
        (vr.broker_id = public.get_auth_broker_id())
      )
      AND (p_primary_marketing_user_id IS NULL OR COALESCE(vr.primary_marketing_user_id, b.primary_marketing_user_id) = p_primary_marketing_user_id)
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
  LEFT JOIN public.users pu_data ON b_data.primary_marketing_user_id = pu_data.id
  LEFT JOIN public.marketing_teams vr_mt ON vr_data.marketing_team_id = vr_mt.id
  LEFT JOIN public.users vr_pu ON vr_data.primary_marketing_user_id = vr_pu.id;

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
      OR (v_is_marketing AND (
        (vr.marketing_team_id IS NOT NULL AND vr.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
        OR
        (b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      ))
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
      OR (v_is_marketing AND (
        (vr.marketing_team_id IS NOT NULL AND vr.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
        OR
        (b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      ))
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
      OR (v_is_marketing AND (
        (vr.marketing_team_id IS NOT NULL AND vr.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
        OR
        (b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      ))
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
      OR (v_is_marketing AND (
        (vr.marketing_team_id IS NOT NULL AND vr.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
        OR
        (b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      ))
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
      OR (v_is_marketing AND (
        (vr.marketing_team_id IS NOT NULL AND vr.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
        OR
        (b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
      ))
      OR (vr.broker_id = public.get_auth_broker_id())
    );

  RETURN jsonb_build_object(
    'success', true,
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed,
    'cancelled', v_cancelled
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$function$;
