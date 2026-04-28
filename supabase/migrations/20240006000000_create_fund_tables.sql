-- Create Fund Accounts and Movements tables for Gestion-Cobros

-- Fund Accounts table
CREATE TABLE IF NOT EXISTS fund_accounts (
    id TEXT PRIMARY KEY DEFAULT 'main',
    available_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_invested NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_withdrawn NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_disbursed NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_recovered NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fund Movements table
CREATE TABLE IF NOT EXISTS fund_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fund_account_id TEXT REFERENCES fund_accounts(id) NOT NULL DEFAULT 'main',
    type fund_movement_type NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    note TEXT,
    created_by_id UUID REFERENCES user_profiles(id),
    loan_id UUID REFERENCES loans(id),
    payment_id UUID REFERENCES payments(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add updated_at trigger for fund_accounts
CREATE TRIGGER update_fund_accounts_updated_at
    BEFORE UPDATE ON fund_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Initialize the main fund account
INSERT INTO fund_accounts (id) VALUES ('main') ON CONFLICT DO NOTHING;
