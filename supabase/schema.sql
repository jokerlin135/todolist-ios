-- =====================================================
-- Supabase Schema for aatodo iOS App
-- Region: Singapore
-- Auth: Google OAuth
-- =====================================================

-- =====================================================
-- 1. Create todos table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.todos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- =====================================================
-- 2. Create index for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON public.todos(created_at DESC);

-- =====================================================
-- 3. Enable Row Level Security (RLS)
-- =====================================================
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. Create RLS Policies
-- Users can only access their own todos
-- =====================================================

-- Policy: Users can SELECT their own todos
CREATE POLICY "Users can select own todos"
ON public.todos
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can INSERT their own todos
CREATE POLICY "Users can insert own todos"
ON public.todos
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can UPDATE their own todos
CREATE POLICY "Users can update own todos"
ON public.todos
FOR UPDATE
USING (auth.uid() = user_id);

-- Policy: Users can DELETE their own todos
CREATE POLICY "Users can delete own todos"
ON public.todos
FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- 5. Create updated_at trigger
-- Automatically updates updated_at on row modification
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.todos
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- 6. Verification Queries (run these to test RLS)
-- =====================================================

-- Test: Count all todos (should show total without RLS bypass)
-- SELECT COUNT(*) FROM public.todos;

-- Test: Check RLS status (should return true)
-- SELECT relrowsecurity FROM pg_class WHERE relname = 'todos';

-- Test: List all RLS policies on todos table
-- SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'todos';
