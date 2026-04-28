-- Create PostgreSQL Enums for Gestion-Cobros

-- Traffic Light Status
CREATE TYPE traffic_light AS ENUM ('GREEN', 'YELLOW', 'RED');

-- Loan Status
CREATE TYPE loan_status AS ENUM ('ACTIVE', 'COMPLETED', 'RENEWED', 'DEFAULTED', 'CANCELLED');

-- Installment Status
CREATE TYPE installment_status AS ENUM ('PENDING', 'PAID', 'OVERDUE', 'PARTIAL');

-- Payment Frequency
CREATE TYPE payment_frequency AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY');

-- Shift Status
CREATE TYPE shift_status AS ENUM ('OPEN', 'CLOSED', 'AUTO_CLOSED');

-- Notification Type
CREATE TYPE notification_type AS ENUM ('INFO', 'WARNING', 'ALERT', 'OVERDUE', 'INACTIVITY');

-- Fund Movement Type
CREATE TYPE fund_movement_type AS ENUM ('INVESTMENT', 'WITHDRAWAL', 'LOAN_DISBURSEMENT', 'PAYMENT_INFLOW');
