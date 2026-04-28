-- Create Loans and Installments tables for Gestion-Cobros

-- Loans table
CREATE TABLE IF NOT EXISTS loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_number TEXT UNIQUE NOT NULL,
    client_id UUID REFERENCES clients(id) NOT NULL,
    collector_id UUID REFERENCES user_profiles(id) NOT NULL,
    renewed_from_loan_id UUID REFERENCES loans(id),
    principal_amount NUMERIC(12,2) NOT NULL,
    interest_rate NUMERIC(5,2) NOT NULL DEFAULT 20.00,
    total_amount NUMERIC(12,2) NOT NULL,
    installment_amount NUMERIC(12,2) NOT NULL,
    payment_frequency payment_frequency NOT NULL DEFAULT 'DAILY',
    total_installments INTEGER NOT NULL DEFAULT 24,
    paid_installments INTEGER NOT NULL DEFAULT 0,
    paid_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    remaining_amount NUMERIC(12,2) NOT NULL,
    overdue_days INTEGER NOT NULL DEFAULT 0,
    mora_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    status loan_status NOT NULL DEFAULT 'ACTIVE',
    disbursed_at TIMESTAMPTZ DEFAULT NOW(),
    expected_end_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Installments table
CREATE TABLE IF NOT EXISTS installments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
    number INTEGER NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    status installment_status NOT NULL DEFAULT 'PENDING',
    paid_at TIMESTAMPTZ,
    paid_amount NUMERIC(12,2) DEFAULT 0,
    UNIQUE(loan_id, number)
);

-- Add updated_at trigger for loans
CREATE TRIGGER update_loans_updated_at
    BEFORE UPDATE ON loans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
