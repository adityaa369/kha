-- KHATHA APP SUPABASE SCHEMA (CLEAN START)
-- Run this in the Supabase SQL Editor to reset/create all tables

-- Drop existing tables to ensure a clean start
DROP TABLE IF EXISTS public.repayments CASCADE;
DROP TABLE IF EXISTS public.credit_scores CASCADE;
DROP TABLE IF EXISTS public.loans CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- 1. USERS TABLE
CREATE TABLE public.users (
    id TEXT PRIMARY KEY, -- Supports Firebase UIDs and Demo IDs
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE,
    pan TEXT,
    aadhar TEXT,
    dob TEXT,
    gender TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Using simpler policies for Demo/External Auth
CREATE POLICY "Allow select for all" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow insert for all" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update for all" ON public.users FOR UPDATE USING (true);

-- 2. LOANS TABLE
CREATE TABLE public.loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lender_id TEXT REFERENCES public.users(id) ON DELETE SET NULL,
    borrower_id TEXT REFERENCES public.users(id) ON DELETE SET NULL,
    borrower_name TEXT NOT NULL,
    borrower_phone TEXT NOT NULL,
    borrower_aadhar TEXT,
    borrower_address TEXT, -- Added this
    amount DECIMAL NOT NULL,
    interest_rate DECIMAL DEFAULT 0,
    duration_months INTEGER,
    status TEXT NOT NULL DEFAULT 'pending_otp',
    progress DECIMAL DEFAULT 0,
    start_date TIMESTAMPTZ DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    activated_at TIMESTAMPTZ,
    type TEXT DEFAULT 'personal',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on loans
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow select for all loans" ON public.loans FOR SELECT USING (true);
CREATE POLICY "Allow insert for all loans" ON public.loans FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update for all loans" ON public.loans FOR UPDATE USING (true);

-- 3. CREDIT SCORES TABLE
CREATE TABLE public.credit_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.users(id) ON DELETE CASCADE,
    cibil_score INTEGER DEFAULT 0,
    experian_score INTEGER DEFAULT 0,
    status TEXT DEFAULT 'Processing',
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on credit_scores
ALTER TABLE public.credit_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow select for all scores" ON public.credit_scores FOR SELECT USING (true);
CREATE POLICY "Allow insert for all scores" ON public.credit_scores FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update for all scores" ON public.credit_scores FOR UPDATE USING (true);

-- 4. REPAYMENTS TABLE (Optional for now)
CREATE TABLE public.repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID REFERENCES public.loans(id) ON DELETE CASCADE,
    amount DECIMAL NOT NULL,
    payment_date TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'success'
);

ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow select for all repayments" ON public.repayments FOR SELECT USING (true);
CREATE POLICY "Allow insert for all repayments" ON public.repayments FOR INSERT WITH CHECK (true);

-- AUTOMATIC UPDATED_AT TRIGGER
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON public.loans FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
