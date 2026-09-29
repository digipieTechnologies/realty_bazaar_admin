-- Migration: 20260923140000_create_marketing_teams_and_assignments.sql
-- Description: Create marketing_teams, marketing_team_members, update brokers table, and create broker_assignment_history audit table.

-- 1. Create marketing_teams table
CREATE TABLE IF NOT EXISTS public.marketing_teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    territory TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index for active teams query
CREATE INDEX IF NOT EXISTS idx_marketing_teams_is_active ON public.marketing_teams(is_active);

-- 2. Create marketing_team_members junction table
CREATE TABLE IF NOT EXISTS public.marketing_team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.marketing_teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    is_lead BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_marketing_team_member UNIQUE (team_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_marketing_team_members_user_id ON public.marketing_team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_marketing_team_members_team_id ON public.marketing_team_members(team_id);

-- 3. Add marketing assignment columns to brokers table
ALTER TABLE public.brokers
ADD COLUMN IF NOT EXISTS marketing_team_id UUID REFERENCES public.marketing_teams(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS primary_marketing_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_brokers_marketing_team_id ON public.brokers(marketing_team_id);
CREATE INDEX IF NOT EXISTS idx_brokers_primary_marketing_user_id ON public.brokers(primary_marketing_user_id);

-- 4. Create broker_assignment_history audit table
CREATE TABLE IF NOT EXISTS public.broker_assignment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    broker_id UUID NOT NULL REFERENCES public.brokers(id) ON DELETE CASCADE,
    previous_team_id UUID REFERENCES public.marketing_teams(id) ON DELETE SET NULL,
    new_team_id UUID REFERENCES public.marketing_teams(id) ON DELETE SET NULL,
    previous_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    new_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    changed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_broker_assignment_history_broker_id ON public.broker_assignment_history(broker_id);
CREATE INDEX IF NOT EXISTS idx_broker_assignment_history_created_at ON public.broker_assignment_history(created_at DESC);

-- 5. Trigger to automatically record changes in broker assignments
CREATE OR REPLACE FUNCTION public.handle_broker_assignment_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF (OLD.marketing_team_id IS DISTINCT FROM NEW.marketing_team_id) OR
       (OLD.primary_marketing_user_id IS DISTINCT FROM NEW.primary_marketing_user_id) THEN
        INSERT INTO public.broker_assignment_history (
            broker_id,
            previous_team_id,
            new_team_id,
            previous_user_id,
            new_user_id,
            changed_by,
            created_at
        ) VALUES (
            NEW.id,
            OLD.marketing_team_id,
            NEW.marketing_team_id,
            OLD.primary_marketing_user_id,
            NEW.primary_marketing_user_id,
            auth.uid(),
            timezone('utc'::text, now())
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_broker_assignment_audit ON public.brokers;
CREATE TRIGGER trg_broker_assignment_audit
AFTER UPDATE OF marketing_team_id, primary_marketing_user_id ON public.brokers
FOR EACH ROW
EXECUTE FUNCTION public.handle_broker_assignment_audit();
