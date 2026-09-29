-- Migration: 20260928131500_fix_broker_assignment_and_notes.sql
-- Description: Improve assign_broker_to_team function with notes auditing and add brokers_admin_all RLS policy

CREATE OR REPLACE FUNCTION public.assign_broker_to_team(
    p_broker_id uuid,
    p_team_id uuid DEFAULT NULL,
    p_primary_user_id uuid DEFAULT NULL,
    p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_old_team_id uuid;
    v_old_primary_user_id uuid;
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

    -- Update broker
    UPDATE public.brokers
    SET 
        marketing_team_id = p_team_id,
        primary_marketing_user_id = CASE WHEN p_team_id IS NULL THEN NULL ELSE p_primary_user_id END,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_broker_id;

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
        'message', 'Broker assignment successfully updated.',
        'broker_id', p_broker_id,
        'team_id', p_team_id,
        'primary_user_id', CASE WHEN p_team_id IS NULL THEN NULL ELSE p_primary_user_id END
    );
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'brokers' AND policyname = 'brokers_admin_all'
    ) THEN
        CREATE POLICY brokers_admin_all ON public.brokers
        FOR ALL TO authenticated
        USING (public.is_admin())
        WITH CHECK (public.is_admin());
    END IF;
END $$;
