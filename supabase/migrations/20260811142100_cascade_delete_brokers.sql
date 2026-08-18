-- Migration: Cascade delete constraints for brokers table references and set null for users
-- Timestamp: 20260811142100

-- 1. public.users (Unlink users instead of deleting them)
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_broker_id_fkey,
ADD CONSTRAINT users_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE SET NULL;

-- 2. public.social_accounts (Cascade delete)
ALTER TABLE public.social_accounts 
DROP CONSTRAINT IF EXISTS social_accounts_broker_id_fkey,
ADD CONSTRAINT social_accounts_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE CASCADE;

-- 3. public.social_posts (Cascade delete)
ALTER TABLE public.social_posts 
DROP CONSTRAINT IF EXISTS social_posts_broker_id_fkey,
ADD CONSTRAINT social_posts_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE CASCADE;

-- 4. public.social_leads (Cascade delete)
ALTER TABLE public.social_leads 
DROP CONSTRAINT IF EXISTS social_leads_broker_id_fkey,
ADD CONSTRAINT social_leads_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE CASCADE;

-- 5. public.properties (Cascade delete)
ALTER TABLE public.properties 
DROP CONSTRAINT IF EXISTS properties_broker_id_fkey,
ADD CONSTRAINT properties_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE CASCADE;

-- 6. public.video_requests (Cascade delete)
ALTER TABLE public.video_requests 
DROP CONSTRAINT IF EXISTS video_requests_broker_id_fkey,
ADD CONSTRAINT video_requests_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE CASCADE;

-- 7. public.chat_rooms (Cascade delete)
ALTER TABLE public.chat_rooms 
DROP CONSTRAINT IF EXISTS chat_rooms_broker_id_fkey,
ADD CONSTRAINT chat_rooms_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE CASCADE;

-- 8. public.chat_messages (Cascade delete room messages when room is deleted)
ALTER TABLE public.chat_messages
DROP CONSTRAINT IF EXISTS chat_messages_room_id_fkey,
ADD CONSTRAINT chat_messages_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_rooms(id) ON DELETE CASCADE;

-- 9. public.notifications (Cascade delete notifications when video request is deleted)
ALTER TABLE public.notifications
DROP CONSTRAINT IF EXISTS notifications_video_request_id_fkey,
ADD CONSTRAINT notifications_video_request_id_fkey FOREIGN KEY (video_request_id) REFERENCES public.video_requests(id) ON DELETE CASCADE;

-- 10. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
