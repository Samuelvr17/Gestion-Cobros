-- Create Database Triggers for Automating Business Logic

-- 1. Automate User Profile creation from auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_role_id UUID;
    meta_role_id UUID;
BEGIN
    -- Extract role_id from metadata or find 'cobrador' role
    BEGIN
        meta_role_id := (NEW.raw_user_meta_data->>'role_id')::UUID;
    EXCEPTION WHEN OTHERS THEN
        meta_role_id := NULL;
    END;

    IF meta_role_id IS NULL THEN
        SELECT id INTO default_role_id FROM public.roles WHERE name = 'cobrador';
    ELSE
        default_role_id := meta_role_id;
    END IF;

    INSERT INTO public.user_profiles (
        id, 
        full_name, 
        phone, 
        cedula, 
        role_id
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Nuevo Usuario'),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        NEW.raw_user_meta_data->>'cedula',
        default_role_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2 & 3. Update Client last_contact_at on payment or loan activity
CREATE OR REPLACE FUNCTION public.update_client_last_contact()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.clients
    SET last_contact_at = NOW()
    WHERE id = NEW.client_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.update_client_last_contact_from_payment()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.clients
    SET last_contact_at = NOW()
    WHERE id = (SELECT client_id FROM public.loans WHERE id = NEW.loan_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for Loans
CREATE OR REPLACE TRIGGER on_loan_activity
    AFTER INSERT OR UPDATE ON public.loans
    FOR EACH ROW EXECUTE FUNCTION public.update_client_last_contact();

-- Trigger for Payments
CREATE OR REPLACE TRIGGER on_payment_activity
    AFTER INSERT ON public.payments
    FOR EACH ROW EXECUTE FUNCTION public.update_client_last_contact_from_payment();

-- 4. Ensure user_profiles has updated_at trigger (already exists in 20240002000000 but re-adding for safety)
-- The update_updated_at_column() function is already defined in migration 0002.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_profiles_updated_at') THEN
        CREATE TRIGGER update_user_profiles_updated_at
            BEFORE UPDATE ON public.user_profiles
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END $$;
