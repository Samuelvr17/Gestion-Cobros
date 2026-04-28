-- Enable Row Level Security (RLS) and create policies for Gestion-Cobros

-- 1. Create helper function to get current user role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
DECLARE
    role_name TEXT;
BEGIN
    SELECT r.name INTO role_name
    FROM user_profiles up
    JOIN roles r ON up.role_id = r.id
    WHERE up.id = auth.uid();
    
    RETURN COALESCE(role_name, '');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Enable RLS on all tables
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_register_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE fund_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE fund_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE mora_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 3. Define Policies

-- Admin: Full access to everything
DO $$
DECLARE
    t TEXT;
    all_tables TEXT[] := ARRAY[
        'roles', 'permissions', 'role_permissions', 'user_profiles', 
        'clients', 'loans', 'installments', 'cash_register_shifts', 
        'payments', 'expenses', 'fund_accounts', 'fund_movements', 
        'mora_configs', 'rate_configs', 'notifications', 'audit_logs'
    ];
BEGIN
    FOREACH t IN ARRAY all_tables LOOP
        EXECUTE format('CREATE POLICY "Admin full access on %I" ON %I FOR ALL TO authenticated USING (get_user_role() = ''admin'') WITH CHECK (get_user_role() = ''admin'')', t, t);
    END LOOP;
END $$;

-- Auxiliar: SELECT only on most tables
DO $$
DECLARE
    t TEXT;
    aux_tables TEXT[] := ARRAY[
        'roles', 'permissions', 'role_permissions', 'user_profiles', 
        'clients', 'loans', 'installments', 'cash_register_shifts', 
        'payments', 'expenses', 'mora_configs', 'rate_configs', 
        'notifications', 'audit_logs'
    ];
BEGIN
    FOREACH t IN ARRAY aux_tables LOOP
        EXECUTE format('CREATE POLICY "Auxiliar read-only on %I" ON %I FOR SELECT TO authenticated USING (get_user_role() = ''auxiliar'')', t, t);
    END LOOP;
END $$;

-- Cobrador Specific Policies

-- Clients: Own only
CREATE POLICY "Cobrador clients access" ON clients
FOR ALL TO authenticated
USING (get_user_role() = 'cobrador' AND created_by_id = auth.uid())
WITH CHECK (get_user_role() = 'cobrador' AND created_by_id = auth.uid());

-- Loans: Own only
CREATE POLICY "Cobrador loans access" ON loans
FOR ALL TO authenticated
USING (get_user_role() = 'cobrador' AND collector_id = auth.uid())
WITH CHECK (get_user_role() = 'cobrador' AND collector_id = auth.uid());

-- Installments: Only those belonging to their loans
CREATE POLICY "Cobrador installments access" ON installments
FOR SELECT TO authenticated
USING (
    get_user_role() = 'cobrador' AND 
    EXISTS (SELECT 1 FROM loans WHERE loans.id = installments.loan_id AND loans.collector_id = auth.uid())
);

-- Payments: Own only
CREATE POLICY "Cobrador payments access" ON payments
FOR ALL TO authenticated
USING (get_user_role() = 'cobrador' AND collector_id = auth.uid())
WITH CHECK (get_user_role() = 'cobrador' AND collector_id = auth.uid());

-- Expenses: Own only
CREATE POLICY "Cobrador expenses access" ON expenses
FOR ALL TO authenticated
USING (get_user_role() = 'cobrador' AND user_id = auth.uid())
WITH CHECK (get_user_role() = 'cobrador' AND user_id = auth.uid());

-- Cash Register Shifts: Own only
CREATE POLICY "Cobrador shifts access" ON cash_register_shifts
FOR ALL TO authenticated
USING (get_user_role() = 'cobrador' AND user_id = auth.uid())
WITH CHECK (get_user_role() = 'cobrador' AND user_id = auth.uid());

-- Notifications: Own only
CREATE POLICY "Cobrador notifications access" ON notifications
FOR SELECT TO authenticated
USING (get_user_role() = 'cobrador' AND user_id = auth.uid());

-- Dashboard: Cobradors need access to read parts of user_profiles to identify themselves
CREATE POLICY "Cobrador self profile read" ON user_profiles
FOR SELECT TO authenticated
USING (get_user_role() = 'cobrador' AND id = auth.uid());

-- Also grant select on roles to cobradors so they can identify their role name
CREATE POLICY "Cobrador roles read" ON roles
FOR SELECT TO authenticated
USING (get_user_role() = 'cobrador');
