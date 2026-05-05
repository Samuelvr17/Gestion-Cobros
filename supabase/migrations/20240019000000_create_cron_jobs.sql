-- Enable pg_cron (must be enabled in Supabase dashboard first)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- JOB 1: Update overdue_days daily at 6 AM Colombia time (UTC-5 = 11 AM UTC)
-- For each ACTIVE loan, calculate days since last payment or disbursement
SELECT cron.schedule(
  'update-overdue-days',
  '0 11 * * *',
  $$
  UPDATE public.loans
  SET overdue_days = GREATEST(0, 
    EXTRACT(DAY FROM (NOW() - disbursed_at))::INTEGER - paid_installments
  )
  WHERE status = 'ACTIVE';
  $$
);

-- JOB 2: Update traffic_light on clients based on their loan overdue_days
-- GREEN = 0 days, YELLOW = 1-15, RED = 16+
SELECT cron.schedule(
  'update-traffic-lights',
  '5 11 * * *',
  $$
  UPDATE public.clients c
  SET traffic_light = CASE
    WHEN EXISTS (
      SELECT 1 FROM loans l 
      WHERE l.client_id = c.id AND l.status = 'ACTIVE' AND l.overdue_days >= 16
    ) THEN 'RED'::traffic_light
    WHEN EXISTS (
      SELECT 1 FROM loans l 
      WHERE l.client_id = c.id AND l.status = 'ACTIVE' AND l.overdue_days BETWEEN 1 AND 15
    ) THEN 'YELLOW'::traffic_light
    ELSE 'GREEN'::traffic_light
  END
  WHERE c.is_active = true;
  $$
);

-- JOB 3: Punish clients with 45+ overdue days
SELECT cron.schedule(
  'punish-defaulted-clients',
  '10 11 * * *',
  $$
  -- Mark loans as DEFAULTED
  UPDATE public.loans
  SET status = 'DEFAULTED'
  WHERE status = 'ACTIVE' AND overdue_days >= 45;
  
  -- Mark clients as punished
  UPDATE public.clients c
  SET is_punished = true
  WHERE is_active = true
  AND EXISTS (
    SELECT 1 FROM loans l
    WHERE l.client_id = c.id AND l.status = 'DEFAULTED'
  );
  $$
);

-- JOB 4: Detect cobrador inactivity (3h without activity since 8 AM)
-- Runs every hour from 11 AM to 6 PM UTC (6 AM - 1 PM Colombia)
SELECT cron.schedule(
  'check-cobrador-inactivity',
  '0 11-18 * * *',
  $$
  INSERT INTO public.notifications (user_id, title, message, type)
  SELECT 
    up.id,
    'Inactividad detectada',
    'No se ha registrado actividad en las últimas 3 horas.',
    'INACTIVITY'::notification_type
  FROM public.user_profiles up
  JOIN public.roles r ON up.role_id = r.id
  WHERE r.name = 'cobrador'
    AND up.is_active = true
    AND NOT EXISTS (
      SELECT 1 FROM public.payments p
      WHERE p.collector_id = up.id
      AND p.payment_timestamp > NOW() - INTERVAL '3 hours'
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.user_id = up.id
      AND e.created_at > NOW() - INTERVAL '3 hours'
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.notifications n
      WHERE n.user_id = up.id
      AND n.type = 'INACTIVITY'
      AND n.created_at > NOW() - INTERVAL '3 hours'
    );
  $$
);
