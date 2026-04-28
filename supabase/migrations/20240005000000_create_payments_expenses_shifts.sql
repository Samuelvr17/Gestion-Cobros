-- Create Cash Register Shifts, Payments and Expenses tables for Gestion-Cobros

-- Cash Register Shifts table
CREATE TABLE IF NOT EXISTS cash_register_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id) NOT NULL,
    opened_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    initial_amount NUMERIC(12,2) DEFAULT 0,
    total_collected NUMERIC(12,2) DEFAULT 0,
    total_expenses NUMERIC(12,2) DEFAULT 0,
    final_amount NUMERIC(12,2),
    status shift_status NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID REFERENCES loans(id) NOT NULL,
    installment_id UUID REFERENCES installments(id) NOT NULL,
    collector_id UUID REFERENCES user_profiles(id) NOT NULL,
    shift_id UUID REFERENCES cash_register_shifts(id),
    amount NUMERIC(12,2) NOT NULL,
    mora_amount NUMERIC(12,2) DEFAULT 0,
    is_late BOOLEAN DEFAULT FALSE,
    payment_timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Expenses table
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id) NOT NULL,
    shift_id UUID REFERENCES cash_register_shifts(id),
    category TEXT NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add updated_at trigger for cash_register_shifts
CREATE TRIGGER update_cash_register_shifts_updated_at
    BEFORE UPDATE ON cash_register_shifts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
