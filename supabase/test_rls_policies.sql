-- =====================================================
-- RLS Policy Verification Tests for aatodo
-- Issue: aatodo-1vp.1
-- =====================================================
--
-- This script verifies that Row Level Security (RLS) policies
-- are correctly configured on the todos table in Supabase.
--
-- INSTRUCTIONS:
-- 1. Open Supabase Dashboard: https://supabase.com/dashboard/project/rwhjjiizrwkmmxwqdrrj
-- 2. Navigate to SQL Editor
-- 3. Run each test section sequentially
-- 4. Verify the results match the expected output
--
-- EXPECTED BEHAVIOR:
-- - Users can only see their own todos
-- - Users cannot modify other users' todos
-- - Anonymous users cannot access any data
-- =====================================================

-- =====================================================
-- TEST 1: Verify RLS is Enabled
-- =====================================================

-- Check if RLS is enabled on the todos table
SELECT
    relname AS table_name,
    relrowsecurity AS rls_enabled
FROM pg_class
WHERE relname = 'todos';

-- Expected output: rls_enabled = true


-- =====================================================
-- TEST 2: List All RLS Policies
-- =====================================================

-- View all RLS policies on the todos table
SELECT
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'todos';

-- Expected output: 4 policies (Users can select/insert/update/delete own todos)


-- =====================================================
-- TEST 3: Create Test Data
-- =====================================================

-- Insert test todos for two different users
-- (These should only work if RLS allows inserting with correct user_id)

-- Insert test todos for user_1
INSERT INTO todos (id, title, is_completed, created_at, updated_at, user_id)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'User 1 Todo 1', false, NOW(), NOW(), '00000000-0000-0000-0000-000000000001'),
    ('00000000-0000-0000-0000-000000000002', 'User 1 Todo 2', true, NOW(), NOW(), '00000000-0000-0000-0000-000000000001');

-- Insert test todos for user_2
INSERT INTO todos (id, title, is_completed, created_at, updated_at, user_id)
VALUES
    ('00000000-0000-0000-0000-000000000003', 'User 2 Todo 1', false, NOW(), NOW(), '00000000-0000-0000-0000-000000000002'),
    ('00000000-0000-0000-0000-000000000004', 'User 2 Todo 2', true, NOW(), NOW(), '00000000-0000-0000-0000-000000000002');

-- Expected output: 4 rows inserted


-- =====================================================
-- TEST 4: User-Specific SELECT Access
-- =====================================================

-- Simulate user_1 context and verify they only see their own todos
SET LOCAL jwt.claims.sub = '00000000-0000-0000-0000-000000000001';

SELECT * FROM todos;

-- Expected output: Only 2 rows (user_1's todos)
-- Should NOT see user_2's todos (IDs: 00000000-0000-0000-0000-000000000003, 00000000-0000-0000-0000-000000000004)


-- =====================================================
-- TEST 5: Cross-User UPDATE Restriction
-- =====================================================

-- Try to update user_2's todo while in user_1's context
SET LOCAL jwt.claims.sub = '00000000-0000-0000-0000-000000000001';

UPDATE todos
SET title = 'Hacked by user_1'
WHERE id = '00000000-0000-0000-0000-000000000003';

-- Verify no rows were affected
SELECT title, user_id FROM todos WHERE id = '00000000-0000-0000-0000-000000000003';

-- Expected output:
-- - UPDATE should affect 0 rows
-- - Title should still be 'User 2 Todo 1' (unchanged)
-- - This proves user_1 cannot modify user_2's data


-- =====================================================
-- TEST 6: Cross-User DELETE Restriction
-- =====================================================

-- Try to delete user_2's todo while in user_1's context
SET LOCAL jwt.claims.sub = '00000000-0000-0000-0000-000000000001';

DELETE FROM todos WHERE id = '00000000-0000-0000-0000-000000000004';

-- Verify the todo still exists
SELECT * FROM todos WHERE id = '00000000-0000-0000-0000-000000000004';

-- Expected output:
-- - DELETE should affect 0 rows
-- - Todo should still exist
-- - This proves user_1 cannot delete user_2's data


-- =====================================================
-- TEST 7: Anonymous Access Restriction
-- =====================================================

-- Reset to anonymous context (no JWT claims)
RESET LOCAL jwt.claims;

-- Try to select todos
SELECT * FROM todos;

-- Expected output: 0 rows (anonymous users cannot access any data)


-- Try to insert as anonymous user (should fail)
INSERT INTO todos (id, title, is_completed, created_at, updated_at, user_id)
VALUES ('00000000-0000-0000-0000-000000000005', 'Anonymous Todo', false, NOW(), NOW(), '00000000-0000-0000-0000-000000000005');

-- Expected output: ERROR - new row violates row-level security policy


-- =====================================================
-- TEST 8: Verify User Can Modify Own Data
-- =====================================================

-- Set user_1 context
SET LOCAL jwt.claims.sub = '00000000-0000-0000-0000-000000000001';

-- Update user_1's own todo (should work)
UPDATE todos
SET title = 'Updated by owner', is_completed = true
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Verify the update worked
SELECT title, is_completed FROM todos WHERE id = '00000000-0000-0000-0000-000000000001';

-- Expected output:
-- - UPDATE should affect 1 row
-- - Title should be 'Updated by owner'
-- - is_completed should be true


-- Delete user_1's own todo (should work)
DELETE FROM todos WHERE id = '00000000-0000-0000-0000-000000000001';

-- Verify deletion worked
SELECT * FROM todos WHERE id = '00000000-0000-0000-0000-000000000001';

-- Expected output:
-- - DELETE should affect 1 row
-- - Todo should be deleted (0 rows returned)


-- =====================================================
-- CLEANUP: Remove Test Data
-- =====================================================

-- Clean up test data
DELETE FROM todos WHERE user_id IN (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002'
);

-- Verify cleanup
SELECT * FROM todos;

-- Expected output: 0 rows (or only your actual data, not test data)


-- =====================================================
-- SUMMARY
-- =====================================================
--
-- If all tests pass as expected, RLS is correctly configured:
-- ✅ RLS enabled on todos table
-- ✅ Users can only SELECT their own todos
-- ✅ Users can only INSERT their own todos (user_id match)
-- ✅ Users can only UPDATE their own todos
-- ✅ Users can only DELETE their own todos
-- ✅ Cross-user operations are blocked
-- ✅ Anonymous access is blocked
--
-- If any test fails, review the RLS policies in supabase/schema.sql
-- =====================================================
