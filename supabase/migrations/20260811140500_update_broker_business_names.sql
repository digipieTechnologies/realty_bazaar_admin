-- Migration: Update broker business names based on associated user name with suffix "Broker"
-- Timestamp: 20260811140500

UPDATE public.brokers b
SET business_name = COALESCE(
  (
    SELECT u.name || ' Broker'
    FROM public.users u
    WHERE u.broker_id = b.id AND u.role::text = 'broker'
    LIMIT 1
  ),
  (
    SELECT u.name || ' Broker'
    FROM public.users u
    WHERE u.broker_id = b.id
    LIMIT 1
  )
)
WHERE EXISTS (
  SELECT 1 FROM public.users u WHERE u.broker_id = b.id
);

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
