-- ==========================================
-- 20260921000000_fcm_tokens.sql
-- User FCM Tokens table for push notifications
-- ==========================================

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_type TEXT DEFAULT 'flutter',
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT user_fcm_tokens_user_id_fcm_token_key UNIQUE (user_id, fcm_token)
);

-- Enable RLS
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage their own FCM tokens"
    ON public.user_fcm_tokens
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Index for fast token lookups when sending push notifications
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);
