-- Migration: 20260923154000_update_chat_rls_for_marketing_teams.sql
-- Description: Update RLS policies for chat_rooms, chat_messages, and chat_room_participants to allow assigned marketing team staff to view, send, and edit messages.

-- 1. Helper function: can_access_chat_room
CREATE OR REPLACE FUNCTION public.can_access_chat_room(p_room_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.chat_rooms cr
    WHERE cr.id = p_room_id
      AND (
        -- Super Admin
        public.is_admin()
        -- Broker or broker staff belonging to the room's broker
        OR cr.broker_id = public.get_auth_broker_id()
        -- Explicit participant in room
        OR EXISTS (
          SELECT 1 FROM public.chat_room_participants crp
          WHERE crp.room_id = cr.id AND crp.user_id = auth.uid()
        )
        -- Marketing staff whose team is assigned to the broker or who is primary rep
        OR (
          public.is_marketing_user() AND EXISTS (
            SELECT 1 FROM public.brokers b
            WHERE b.id = cr.broker_id
              AND (
                b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids())
                OR b.primary_marketing_user_id = auth.uid()
              )
          )
        )
      )
  );
$$;

-- 2. Update chat_rooms policies
DROP POLICY IF EXISTS "chat_rooms_participant_select" ON public.chat_rooms;
CREATE POLICY "chat_rooms_participant_select"
ON public.chat_rooms
FOR SELECT
TO authenticated
USING (
  public.is_admin()
  OR broker_id = public.get_auth_broker_id()
  OR EXISTS (
    SELECT 1 FROM public.chat_room_participants crp 
    WHERE crp.room_id = chat_rooms.id AND crp.user_id = auth.uid()
  )
  OR (
    public.is_marketing_user() AND EXISTS (
      SELECT 1 FROM public.brokers b
      WHERE b.id = chat_rooms.broker_id
        AND (
          b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids())
          OR b.primary_marketing_user_id = auth.uid()
        )
    )
  )
);

DROP POLICY IF EXISTS "chat_rooms_participant_insert" ON public.chat_rooms;
CREATE POLICY "chat_rooms_participant_insert"
ON public.chat_rooms
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR broker_id = public.get_auth_broker_id()
  OR (
    public.is_marketing_user() AND EXISTS (
      SELECT 1 FROM public.brokers b
      WHERE b.id = chat_rooms.broker_id
        AND (
          b.marketing_team_id IN (SELECT public.get_auth_marketing_team_ids())
          OR b.primary_marketing_user_id = auth.uid()
        )
    )
  )
);

-- 3. Update chat_messages policies
DROP POLICY IF EXISTS "chat_messages_participant_select" ON public.chat_messages;
CREATE POLICY "chat_messages_participant_select"
ON public.chat_messages
FOR SELECT
TO authenticated
USING (
  public.can_access_chat_room(room_id)
  OR sender_id = auth.uid()
);

DROP POLICY IF EXISTS "chat_messages_participant_insert" ON public.chat_messages;
CREATE POLICY "chat_messages_participant_insert"
ON public.chat_messages
FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND public.can_access_chat_room(room_id)
);

DROP POLICY IF EXISTS "chat_messages_participant_update" ON public.chat_messages;
CREATE POLICY "chat_messages_participant_update"
ON public.chat_messages
FOR UPDATE
TO authenticated
USING (
  (sender_id = auth.uid() OR public.is_admin())
  AND public.can_access_chat_room(room_id)
)
WITH CHECK (
  (sender_id = auth.uid() OR public.is_admin())
  AND public.can_access_chat_room(room_id)
);

-- 4. Update chat_room_participants select policy
DROP POLICY IF EXISTS "chat_room_participants_select" ON public.chat_room_participants;
CREATE POLICY "chat_room_participants_select"
ON public.chat_room_participants
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR public.is_admin()
  OR public.can_access_chat_room(room_id)
);

-- 5. Update get_total_unread_chat_count
CREATE OR REPLACE FUNCTION public.get_total_unread_chat_count()
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
    SELECT COALESCE(COUNT(*)::int, 0)
    FROM public.chat_messages cm
    JOIN public.chat_rooms cr ON cr.id = cm.room_id
    LEFT JOIN public.chat_room_participants crp 
      ON crp.room_id = cm.room_id AND crp.user_id = auth.uid()
    WHERE cm.sender_id != auth.uid()
      AND cm.is_deleted = false
      AND public.can_access_chat_room(cr.id)
      AND cm.created_at > COALESCE(crp.last_read_at, '1970-01-01'::timestamptz);
$function$;
