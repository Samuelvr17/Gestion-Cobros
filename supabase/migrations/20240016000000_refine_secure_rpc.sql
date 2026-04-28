-- Refine secure RPC with explicit schema, search_path and updated_at
CREATE OR REPLACE FUNCTION public.complete_password_change()
RETURNS void AS $$
BEGIN
    UPDATE public.user_profiles
    SET must_change_password = false,
        updated_at = NOW()
    WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
