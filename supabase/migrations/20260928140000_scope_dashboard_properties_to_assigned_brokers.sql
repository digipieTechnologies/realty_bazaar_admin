-- Migration: 20260928140000_scope_dashboard_properties_to_assigned_brokers.sql
-- Description: Updates get_marketing_dashboard_summary with p_only_primary_rep parameter and team prioritization; tightens properties_authenticated_select RLS.

CREATE OR REPLACE FUNCTION public.get_marketing_dashboard_summary(
    p_only_primary_rep boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
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
    v_user_id uuid;
BEGIN
    v_is_admin := public.is_admin();
    v_is_marketing := public.is_marketing_user();
    v_user_id := auth.uid();

    -- 1. Broker metrics
    SELECT 
        COALESCE(COUNT(*), 0),
        COALESCE(COUNT(*) FILTER (WHERE b.is_active = true), 0)
    INTO v_total_brokers, v_active_brokers
    FROM public.brokers b
    WHERE b.is_deleted = false
      AND (
        v_is_admin
        OR (
          v_is_marketing AND (
            (p_only_primary_rep AND b.primary_marketing_user_id = v_user_id)
            OR
            (NOT p_only_primary_rep AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
          )
        )
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
        OR (
          v_is_marketing AND (
            (p_only_primary_rep AND b.primary_marketing_user_id = v_user_id)
            OR
            (NOT p_only_primary_rep AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
          )
        )
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
        OR (
          v_is_marketing AND (
            (p_only_primary_rep AND b.primary_marketing_user_id = v_user_id)
            OR
            (NOT p_only_primary_rep AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
          )
        )
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
        OR (
          v_is_marketing AND (
            (p_only_primary_rep AND b.primary_marketing_user_id = v_user_id)
            OR
            (NOT p_only_primary_rep AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
          )
        )
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
            OR (
              v_is_marketing AND (
                (p_only_primary_rep AND b.primary_marketing_user_id = v_user_id)
                OR
                (NOT p_only_primary_rep AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
              )
            )
          )
        ORDER BY 
            CASE WHEN b.primary_marketing_user_id = v_user_id THEN 0 ELSE 1 END,
            vr.created_at DESC
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
                'business_name', b.business_name,
                'marketing_team_id', b.marketing_team_id,
                'primary_marketing_user_id', b.primary_marketing_user_id
            ) AS broker_id
        FROM public.properties p
        JOIN public.brokers b ON b.id = p.broker_id
        WHERE p.is_deleted = false
          AND (
            v_is_admin
            OR (
              v_is_marketing AND (
                (p_only_primary_rep AND b.primary_marketing_user_id = v_user_id)
                OR
                (NOT p_only_primary_rep AND b.marketing_team_id IS NOT NULL AND b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids()))
              )
            )
          )
        ORDER BY 
            CASE WHEN b.primary_marketing_user_id = v_user_id THEN 0 ELSE 1 END,
            p.created_at DESC
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

DROP POLICY IF EXISTS properties_authenticated_select ON public.properties;

CREATE POLICY properties_authenticated_select ON public.properties
FOR SELECT TO authenticated
USING (
    (is_deleted = false) AND (
        public.is_admin()
        OR (broker_id = public.get_auth_broker_id())
        OR (
            public.is_marketing_user() AND broker_id IN (
                SELECT id FROM public.brokers 
                WHERE marketing_team_id IS NOT NULL 
                  AND marketing_team_id IN (SELECT public.get_auth_marketing_team_ids())
            )
        )
    )
);
