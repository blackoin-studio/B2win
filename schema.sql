-- ============================================================================
-- B2WIN SUPABASE / POSTGRESQL SCHEMA SPECIFICATION
-- Run this script in the Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. PROFILES / USERS TABLE (Linked with Supabase Auth auth.users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) DEFAULT 'SUPABASE_AUTH' NOT NULL,
    is_admin BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);

-- ============================================================================
-- 2. SUPABASE AUTH -> PROFILES AUTOMATIC SYNC TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    default_username TEXT;
    admin_flag BOOLEAN;
BEGIN
    default_username := COALESCE(
        NEW.raw_user_meta_data->>'username',
        SPLIT_PART(NEW.email, '@', 1) || '_' || SUBSTR(NEW.id::TEXT, 1, 6)
    );
    admin_flag := COALESCE((NEW.raw_app_meta_data->>'is_admin')::BOOLEAN, FALSE);

    INSERT INTO public.profiles (id, email, username, password_hash, is_admin)
    VALUES (NEW.id, LOWER(NEW.email), default_username, 'SUPABASE_AUTH', admin_flag)
    ON CONFLICT (email) DO UPDATE
    SET is_admin = EXCLUDED.is_admin,
        updated_at = NOW();

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_auth_user();

-- ============================================================================
-- 3. BLOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.blogs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    photo VARCHAR(500) DEFAULT 'no-league-photo.jpg',
    date TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_blogs_date ON public.blogs(date DESC);

-- ============================================================================
-- 4. PREDICTIONS TABLE
-- ============================================================================
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'prediction_status') THEN
        CREATE TYPE prediction_status AS ENUM ('pending', 'won', 'lost', 'postponed', 'cancelled');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    time VARCHAR(50) NOT NULL,
    league VARCHAR(150) NOT NULL,
    home_team VARCHAR(150) NOT NULL,
    away_team VARCHAR(150) NOT NULL,
    league_logo VARCHAR(500) DEFAULT 'no-league-photo.jpg',
    home_logo VARCHAR(500) DEFAULT 'no-home-photo.jpg',
    away_logo VARCHAR(500) DEFAULT 'no-away-photo.jpg',
    score VARCHAR(50) DEFAULT '-',
    odds VARCHAR(50) NOT NULL,
    status prediction_status DEFAULT 'pending' NOT NULL,
    tip VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_predictions_date ON public.predictions(date DESC);
CREATE INDEX IF NOT EXISTS idx_predictions_status ON public.predictions(status);
CREATE INDEX IF NOT EXISTS idx_predictions_league ON public.predictions(league);
CREATE INDEX IF NOT EXISTS idx_predictions_feed ON public.predictions(date DESC, status);

-- ============================================================================
-- 5. AUTO-UPDATED TIMESTAMPS TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

DROP TRIGGER IF EXISTS update_blogs_updated_at ON public.blogs;
CREATE TRIGGER update_blogs_updated_at BEFORE UPDATE ON public.blogs FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

DROP TRIGGER IF EXISTS update_predictions_updated_at ON public.predictions;
CREATE TRIGGER update_predictions_updated_at BEFORE UPDATE ON public.predictions FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- ============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile; admins can read all profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (
        auth.uid() = id
        OR LOWER(auth.jwt()->>'email') = LOWER(email)
        OR COALESCE((auth.jwt()->'app_metadata'->>'is_admin')::BOOLEAN, FALSE) = TRUE
    );

-- Public read access to blogs and predictions
DROP POLICY IF EXISTS "Public read blogs" ON public.blogs;
CREATE POLICY "Public read blogs" ON public.blogs FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read predictions" ON public.predictions;
CREATE POLICY "Public read predictions" ON public.predictions FOR SELECT USING (true);

-- Admins can insert/update/delete blogs and predictions via Supabase Auth JWT
DROP POLICY IF EXISTS "Admin manage blogs" ON public.blogs;
CREATE POLICY "Admin manage blogs" ON public.blogs
    FOR ALL USING (COALESCE((auth.jwt()->'app_metadata'->>'is_admin')::BOOLEAN, FALSE) = TRUE);

DROP POLICY IF EXISTS "Admin manage predictions" ON public.predictions;
CREATE POLICY "Admin manage predictions" ON public.predictions
    FOR ALL USING (COALESCE((auth.jwt()->'app_metadata'->>'is_admin')::BOOLEAN, FALSE) = TRUE);
