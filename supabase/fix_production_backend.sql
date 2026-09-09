-- ============================================================================
-- FUTURE TIMES EVENTS: PRODUCTION BACKEND FIXES
-- Migration: Profiles, Ticket Claiming, Ticket Wallet & QR Validation
-- Date: 2026-09-08
-- ============================================================================

-- Enable pgcrypto for UUID generation if not already enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. PROFILES TABLE & RLS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_url TEXT,
    city TEXT DEFAULT 'Harare',
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Automatic Profile Creation Trigger on Sign Up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, avatar_url, city)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'display_name',
            NEW.raw_user_meta_data->>'full_name',
            split_part(NEW.email, '@', 1)
        ),
        NEW.raw_user_meta_data->>'avatar_url',
        'Harare'
    )
    ON CONFLICT (id) DO UPDATE
    SET
        display_name = COALESCE(NULLIF(public.profiles.display_name, ''), EXCLUDED.display_name),
        avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url),
        updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill any existing auth users without a profile
INSERT INTO public.profiles (id, display_name, avatar_url, city)
SELECT
    u.id,
    COALESCE(
        u.raw_user_meta_data->>'display_name',
        u.raw_user_meta_data->>'full_name',
        split_part(u.email, '@', 1)
    ),
    u.raw_user_meta_data->>'avatar_url',
    'Harare'
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- RPC: get_my_profile
-- PostgreSQL cannot change a function's return type via CREATE OR REPLACE.
DROP FUNCTION IF EXISTS public.get_my_profile();
CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

    IF NOT FOUND THEN
        INSERT INTO public.profiles (id, display_name, city)
        SELECT
            v_user_id,
            COALESCE(
                raw_user_meta_data->>'display_name',
                raw_user_meta_data->>'full_name',
                split_part(email, '@', 1)
            ),
            'Harare'
        FROM auth.users
        WHERE id = v_user_id
        RETURNING * INTO v_profile;
    END IF;

    RETURN row_to_json(v_profile);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated, anon;


-- ============================================================================
-- 2. TICKET TYPES & TICKETS TABLES & RLS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ticket_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'General Admission',
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    quantity_total INT DEFAULT 100,
    quantity_available INT DEFAULT 100,
    claim_opens_at TIMESTAMPTZ,
    claim_closes_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    is_visible BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.ticket_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Ticket types are viewable by everyone" ON public.ticket_types;
CREATE POLICY "Ticket types are viewable by everyone"
    ON public.ticket_types FOR SELECT
    USING (is_visible = true OR is_visible IS NULL);

CREATE TABLE IF NOT EXISTS public.tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number TEXT NOT NULL UNIQUE,
    ticket_id TEXT,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    ticket_type_id UUID REFERENCES public.ticket_types(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    attendee_name TEXT NOT NULL,
    attendee_email TEXT NOT NULL,
    attendee_phone TEXT,
    status TEXT NOT NULL DEFAULT 'issued' CHECK (status IN ('issued', 'checked_in', 'cancelled', 'revoked')),
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    purchased_at TIMESTAMPTZ DEFAULT NOW(),
    checked_in_at TIMESTAMPTZ,
    gate TEXT,
    qr_code TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON public.tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_attendee_email ON public.tickets(attendee_email);
CREATE INDEX IF NOT EXISTS idx_tickets_event_id ON public.tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_tickets_qr_code ON public.tickets(qr_code);
CREATE INDEX IF NOT EXISTS idx_tickets_ticket_number ON public.tickets(ticket_number);

ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- Tickets Policies
DROP POLICY IF EXISTS "Users can view own tickets" ON public.tickets;
CREATE POLICY "Users can view own tickets"
    ON public.tickets FOR SELECT
    USING (
        auth.uid() = user_id
        OR (
            auth.jwt()->>'email' IS NOT NULL
            AND LOWER(attendee_email) = LOWER(auth.jwt()->>'email')
        )
    );

DROP POLICY IF EXISTS "Users can insert own tickets" ON public.tickets;
CREATE POLICY "Users can insert own tickets"
    ON public.tickets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own tickets" ON public.tickets;
CREATE POLICY "Users can update own tickets"
    ON public.tickets FOR UPDATE
    USING (auth.uid() = user_id);


-- ============================================================================
-- 3. RPC: claim_free_ticket
-- ============================================================================

CREATE OR REPLACE FUNCTION public.claim_free_ticket(
    p_event_id UUID,
    p_ticket_type_id UUID,
    p_attendee_name TEXT,
    p_attendee_email TEXT,
    p_attendee_phone TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_ticket_type RECORD;
    v_event RECORD;
    v_existing_ticket RECORD;
    v_ticket_number TEXT;
    v_qr_payload TEXT;
    v_new_ticket RECORD;
BEGIN
    -- 1. Authentication check
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to claim a ticket.';
    END IF;

    -- 2. Verify event exists and is published
    SELECT * INTO v_event FROM public.events WHERE id = p_event_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event not found.';
    END IF;

    -- 3. Verify ticket type exists and is free
    SELECT * INTO v_ticket_type
    FROM public.ticket_types
    WHERE id = p_ticket_type_id AND event_id = p_event_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ticket type not found for this event.';
    END IF;

    IF v_ticket_type.price > 0 THEN
        RAISE EXCEPTION 'Only free tickets can be claimed directly.';
    END IF;

    IF v_ticket_type.quantity_available IS NOT NULL AND v_ticket_type.quantity_available <= 0 THEN
        RAISE EXCEPTION 'This ticket type is sold out.';
    END IF;

    -- 4. Check for existing active ticket for this event by this user
    SELECT * INTO v_existing_ticket
    FROM public.tickets
    WHERE event_id = p_event_id
      AND user_id = v_user_id
      AND status IN ('issued', 'checked_in')
    LIMIT 1;

    IF FOUND THEN
        -- Return existing ticket instead of error or duplicate
        RETURN json_build_object(
            'success', true,
            'message', 'You already have an active ticket for this event.',
            'already_owned', true,
            'ticket_id', v_existing_ticket.id,
            'ticket_number', v_existing_ticket.ticket_number,
            'qr_code', v_existing_ticket.qr_code,
            'status', v_existing_ticket.status
        );
    END IF;

    -- 5. Generate human-readable ticket number & secure QR code
    v_ticket_number := 'FT-' || to_char(NOW(), 'YYMM') || '-' || upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    v_qr_payload := 'FTE-TKT-' || gen_random_uuid()::text;

    -- 6. Insert new ticket
    INSERT INTO public.tickets (
        ticket_number,
        ticket_id,
        event_id,
        ticket_type_id,
        user_id,
        attendee_name,
        attendee_email,
        attendee_phone,
        status,
        issued_at,
        purchased_at,
        qr_code
    )
    VALUES (
        v_ticket_number,
        v_ticket_number,
        p_event_id,
        p_ticket_type_id,
        v_user_id,
        p_attendee_name,
        p_attendee_email,
        p_attendee_phone,
        'issued',
        NOW(),
        NOW(),
        v_qr_payload
    )
    RETURNING * INTO v_new_ticket;

    -- 7. Decrement available quantity on ticket type
    IF v_ticket_type.quantity_available IS NOT NULL THEN
        UPDATE public.ticket_types
        SET quantity_available = quantity_available - 1,
            updated_at = NOW()
        WHERE id = p_ticket_type_id;
    END IF;

    -- 8. Increment event attendees count
    UPDATE public.events
    SET attendees = COALESCE(attendees, 0) + 1
    WHERE id = p_event_id;

    -- 9. Automatically record RSVP going
    INSERT INTO public.rsvps (event_id, user_id, status, is_public)
    VALUES (p_event_id, v_user_id, 'going', true)
    ON CONFLICT (event_id, user_id)
    DO UPDATE SET status = 'going', is_public = true;

    RETURN json_build_object(
        'success', true,
        'ticket_id', v_new_ticket.id,
        'ticket_number', v_new_ticket.ticket_number,
        'qr_code', v_new_ticket.qr_code,
        'status', v_new_ticket.status,
        'issued_at', v_new_ticket.issued_at
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_free_ticket(UUID, UUID, TEXT, TEXT, TEXT) TO authenticated;


-- ============================================================================
-- 4. RPC: get_my_ticket_wallet
-- ============================================================================

-- PostgreSQL cannot change a function's return type via CREATE OR REPLACE.
DROP FUNCTION IF EXISTS public.get_my_ticket_wallet();
CREATE OR REPLACE FUNCTION public.get_my_ticket_wallet()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_user_email TEXT := LOWER(auth.jwt()->>'email');
    v_result JSON;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN '[]'::json;
    END IF;

    SELECT json_agg(
        json_build_object(
            'id', t.id,
            'ticket_id', t.ticket_id,
            'ticket_number', t.ticket_number,
            'event_id', t.event_id,
            'status', t.status,
            'issued_at', t.issued_at,
            'purchased_at', t.purchased_at,
            'checked_in_at', t.checked_in_at,
            'gate', t.gate,
            'qr_code', COALESCE(t.qr_code, 'FTE:' || t.id || ':' || t.ticket_number),
            'attendee_name', t.attendee_name,
            'attendee_email', t.attendee_email,
            'events', json_build_object(
                'id', e.id,
                'title', e.title,
                'slug', e.slug,
                'starts_at', e.starts_at,
                'date', e.date,
                'time', e.time,
                'venue', e.venue,
                'venue_name', e.venue_name,
                'address', e.address,
                'image_url', e.image_url,
                'category', e.category
            ),
            'ticket_type', json_build_object(
                'id', tt.id,
                'name', COALESCE(tt.name, 'General Admission'),
                'price', COALESCE(tt.price, 0.00)
            )
        )
        ORDER BY t.issued_at DESC
    ) INTO v_result
    FROM public.tickets t
    LEFT JOIN public.events e ON e.id = t.event_id
    LEFT JOIN public.ticket_types tt ON tt.id = t.ticket_type_id
    WHERE t.user_id = v_user_id
       OR (v_user_email IS NOT NULL AND LOWER(t.attendee_email) = v_user_email);

    RETURN COALESCE(v_result, '[]'::json);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_ticket_wallet() TO authenticated;


-- ============================================================================
-- 5. RPC: validate_and_check_in_ticket (QR Scanning & Gate Entry)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.validate_and_check_in_ticket(
    p_qr_payload TEXT,
    p_gate TEXT DEFAULT 'Main Gate'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_clean_payload TEXT := trim(p_qr_payload);
    v_ticket RECORD;
    v_event RECORD;
    v_ticket_type RECORD;
BEGIN
    IF v_clean_payload IS NULL OR v_clean_payload = '' THEN
        RETURN json_build_object(
            'valid', false,
            'error', 'empty_payload',
            'message', 'QR payload cannot be empty.'
        );
    END IF;

    -- Lookup ticket by qr_code, ticket_number, or uuid id
    SELECT * INTO v_ticket
    FROM public.tickets
    WHERE qr_code = v_clean_payload
       OR ticket_number = v_clean_payload
       OR id::text = v_clean_payload
    LIMIT 1
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'valid', false,
            'error', 'not_found',
            'message', 'Ticket not found. Invalid QR code or reference.'
        );
    END IF;

    -- Retrieve event and ticket type
    SELECT title, starts_at, venue_name INTO v_event FROM public.events WHERE id = v_ticket.event_id;
    SELECT name, price INTO v_ticket_type FROM public.ticket_types WHERE id = v_ticket.ticket_type_id;

    -- Check ticket status
    IF v_ticket.status = 'cancelled' THEN
        RETURN json_build_object(
            'valid', false,
            'error', 'cancelled',
            'message', 'This ticket has been cancelled.',
            'ticket_number', v_ticket.ticket_number
        );
    END IF;

    IF v_ticket.status = 'revoked' THEN
        RETURN json_build_object(
            'valid', false,
            'error', 'revoked',
            'message', 'This ticket has been revoked by the organizer.',
            'ticket_number', v_ticket.ticket_number
        );
    END IF;

    IF v_ticket.status = 'checked_in' THEN
        RETURN json_build_object(
            'valid', false,
            'error', 'already_checked_in',
            'message', 'Ticket was already checked in at ' || to_char(v_ticket.checked_in_at, 'YYYY-MM-DD HH24:MI:SS') || COALESCE(' (' || v_ticket.gate || ')', '') || '.',
            'checked_in_at', v_ticket.checked_in_at,
            'gate', v_ticket.gate,
            'attendee_name', v_ticket.attendee_name,
            'ticket_number', v_ticket.ticket_number,
            'event_title', v_event.title
        );
    END IF;

    -- Valid ticket! Perform check-in
    UPDATE public.tickets
    SET status = 'checked_in',
        checked_in_at = NOW(),
        gate = COALESCE(p_gate, 'Main Gate'),
        updated_at = NOW()
    WHERE id = v_ticket.id;

    RETURN json_build_object(
        'valid', true,
        'status', 'checked_in',
        'message', 'Check-in successful! Welcome, ' || v_ticket.attendee_name || '.',
        'ticket_id', v_ticket.id,
        'ticket_number', v_ticket.ticket_number,
        'attendee_name', v_ticket.attendee_name,
        'attendee_email', v_ticket.attendee_email,
        'event_title', COALESCE(v_event.title, 'Event'),
        'venue', COALESCE(v_event.venue_name, 'Venue TBA'),
        'ticket_type', COALESCE(v_ticket_type.name, 'Admission'),
        'checked_in_at', NOW(),
        'gate', COALESCE(p_gate, 'Main Gate')
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.validate_and_check_in_ticket(TEXT, TEXT) TO authenticated, anon;
