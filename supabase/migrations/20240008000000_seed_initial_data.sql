-- Seed initial data for Gestion-Cobros

-- 1. Insert Roles
WITH inserted_roles AS (
    INSERT INTO roles (name, description)
    VALUES 
        ('admin', 'Acceso total'),
        ('auxiliar', 'Solo lectura y reportes'),
        ('cobrador', 'Operaciones de campo')
    RETURNING id, name
),

-- 2. Insert Permissions
inserted_permissions AS (
    INSERT INTO permissions (name, module, action)
    VALUES 
        ('users.create', 'users', 'create'),
        ('users.read', 'users', 'read'),
        ('users.update', 'users', 'update'),
        ('users.delete', 'users', 'delete'),
        ('clients.create', 'clients', 'create'),
        ('clients.read', 'clients', 'read'),
        ('clients.update', 'clients', 'update'),
        ('clients.delete', 'clients', 'delete'),
        ('loans.create', 'loans', 'create'),
        ('loans.read', 'loans', 'read'),
        ('loans.update', 'loans', 'update'),
        ('loans.cancel', 'loans', 'cancel'),
        ('payments.create', 'payments', 'create'),
        ('payments.read', 'payments', 'read'),
        ('expenses.create', 'expenses', 'create'),
        ('expenses.read', 'expenses', 'read'),
        ('cash_register.open', 'cash_register', 'open'),
        ('cash_register.close', 'cash_register', 'close'),
        ('cash_register.read', 'cash_register', 'read'),
        ('reports.read', 'reports', 'read'),
        ('reports.export', 'reports', 'export'),
        ('dashboard.read', 'dashboard', 'read'),
        ('funds.read', 'funds', 'read'),
        ('funds.manage', 'funds', 'manage'),
        ('audit.read', 'audit', 'read'),
        ('notifications.read', 'notifications', 'read')
    RETURNING id, name
)

-- 3, 4, 5. Assign Permissions to Roles
INSERT INTO role_permissions (role_id, permission_id)
-- Admin role: All permissions
SELECT r.id, p.id 
FROM inserted_roles r, inserted_permissions p
WHERE r.name = 'admin'

UNION ALL

-- Auxiliar role permissions
SELECT r.id, p.id
FROM inserted_roles r, inserted_permissions p
WHERE r.name = 'auxiliar' AND p.name IN (
    'users.read', 'clients.read', 'loans.read', 'payments.read', 
    'expenses.read', 'cash_register.read', 'reports.read', 
    'reports.export', 'dashboard.read', 'notifications.read', 'audit.read'
)

UNION ALL

-- Cobrador role permissions
SELECT r.id, p.id
FROM inserted_roles r, inserted_permissions p
WHERE r.name = 'cobrador' AND p.name IN (
    'clients.create', 'clients.read', 'clients.update', 
    'loans.create', 'loans.read', 'loans.update', 
    'payments.create', 'payments.read', 'expenses.create', 
    'expenses.read', 'cash_register.open', 'cash_register.close', 
    'cash_register.read', 'dashboard.read', 'notifications.read'
);

-- 6. Initialize Fund Account (Ensuring 'main' exists if not already initialized in 20240006000000)
INSERT INTO fund_accounts (id, available_amount, total_invested, total_withdrawn, total_disbursed, total_recovered)
VALUES ('main', 0, 0, 0, 0, 0)
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- 7. Insert Mora Configuration
INSERT INTO mora_configs (name, daily_rate, grace_period_hours, punishment_threshold_days, is_active)
VALUES ('Default', 1.5, 2, 45, true);
