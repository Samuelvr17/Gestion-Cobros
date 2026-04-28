-- Create Clients table for Gestion-Cobros

CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    cedula TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    address TEXT NOT NULL,
    email TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    rating INTEGER DEFAULT 3 CHECK (rating BETWEEN 1 AND 5),
    is_punished BOOLEAN DEFAULT FALSE,
    traffic_light traffic_light DEFAULT 'GREEN',
    last_contact_at TIMESTAMPTZ DEFAULT NOW(),
    created_by_id UUID REFERENCES user_profiles(id) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add updated_at trigger for clients
CREATE TRIGGER update_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
