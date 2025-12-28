# RLS Policy Verification Results

**Project**: aatodo
**Database**: Supabase (Singapore)
**Table**: `todos`
**Issue**: aatodo-1vp.1
**Date**: [Fill in after running tests]

---

## Test Summary

| Test | Status | Result |
|------|--------|--------|
| RLS Enabled | ⏳ Pending | |
| User-Specific SELECT | ⏳ Pending | |
| Cross-User UPDATE | ⏳ Pending | |
| Cross-User DELETE | ⏳ Pending | |
| Anonymous Access | ⏳ Pending | |
| Own Data Operations | ⏳ Pending | |

---

## Detailed Results

### Test 1: Verify RLS Enabled

**Query**:
```sql
SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'todos';
```

**Expected**: `rls_enabled = true`
**Actual**: [Fill in after running tests]

**Status**: ⏳ Pending

---

### Test 2: List All RLS Policies

**Query**:
```sql
SELECT * FROM pg_policies WHERE tablename = 'todos';
```

**Expected**: 4 policies (SELECT, INSERT, UPDATE, DELETE)
**Actual**: [Fill in after running tests]

**Status**: ⏳ Pending

---

### Test 3: Cross-User SELECT Test

**Setup**: User 1 context
**Query**:
```sql
SET LOCAL jwt.claims.sub = '00000000-0000-0000-0000-000000000001';
SELECT * FROM todos;
```

**Expected**: Only user 1's todos (2 rows)
**Actual**: [Fill in after running tests]

**Status**: ⏳ Pending

---

### Test 4: Cross-User UPDATE Test

**Setup**: User 1 context, try to update User 2's todo
**Query**:
```sql
SET LOCAL jwt.claims.sub = '00000000-0000-0000-0000-000000000001';
UPDATE todos SET title = 'Hacked' WHERE id = '00000000-0000-0000-0000-000000000003';
```

**Expected**: 0 rows affected
**Actual**: [Fill in after running tests]

**Status**: ⏳ Pending

---

### Test 5: Cross-User DELETE Test

**Setup**: User 1 context, try to delete User 2's todo
**Query**:
```sql
SET LOCAL jwt.claims.sub = '00000000-0000-0000-0000-000000000001';
DELETE FROM todos WHERE id = '00000000-0000-0000-0000-000000000004';
```

**Expected**: 0 rows affected
**Actual**: [Fill in after running tests]

**Status**: ⏳ Pending

---

### Test 6: Anonymous Access Test

**Setup**: No JWT context
**Query**:
```sql
RESET LOCAL jwt.claims;
SELECT * FROM todos;
```

**Expected**: 0 rows
**Actual**: [Fill in after running tests]

**Status**: ⏳ Pending

---

### Test 7: Own Data Modification Test

**Setup**: User 1 context, modify own todo
**Query**:
```sql
SET LOCAL jwt.claims.sub = '00000000-0000-0000-0000-000000000001';
UPDATE todos SET title = 'Updated' WHERE id = '00000000-0000-0000-0000-000000000001';
```

**Expected**: 1 row affected
**Actual**: [Fill in after running tests]

**Status**: ⏳ Pending

---

## How to Run Tests

1. **Open Supabase Dashboard**:
   - Go to: https://supabase.com/dashboard/project/rwhjjiizrwkmmxwqdrrj

2. **Open SQL Editor**:
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Run Test Script**:
   - Copy contents from `supabase/test_rls_policies.sql`
   - Paste into SQL Editor
   - Run each test section sequentially
   - Verify results match expected output

4. **Update This Document**:
   - Fill in "Actual" results for each test
   - Update status: ✅ Pass / ❌ Fail
   - Note any discrepancies or issues

---

## Expected RLS Policies

From `supabase/schema.sql`, these are the configured policies:

```sql
-- SELECT: Users can select own todos
CREATE POLICY "Users can select own todos"
ON public.todos FOR SELECT
USING (auth.uid() = user_id);

-- INSERT: Users can insert own todos
CREATE POLICY "Users can insert own todos"
ON public.todos FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can update own todos
CREATE POLICY "Users can update own todos"
ON public.todos FOR UPDATE
USING (auth.uid() = user_id);

-- DELETE: Users can delete own todos
CREATE POLICY "Users can delete own todos"
ON public.todos FOR DELETE
USING (auth.uid() = user_id);
```

---

## Troubleshooting

### If Tests Fail:

1. **Check RLS is enabled**:
   ```sql
   ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
   ```

2. **Verify policies exist**:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'todos';
   ```

3. **Re-create policies** (if missing):
   - Run the full schema from `supabase/schema.sql`
   - This will re-create all RLS policies

4. **Check JWT claims**:
   ```sql
   SELECT current_setting('jwt.claims', true);
   ```

---

## Security Verification Checklist

- [ ] RLS enabled on `todos` table
- [ ] 4 policies present (SELECT, INSERT, UPDATE, DELETE)
- [ ] All policies use `auth.uid() = user_id` check
- [ ] Users see only their own data
- [ ] Cross-user SELECT returns only user's own data
- [ ] Cross-user UPDATE affects 0 rows
- [ ] Cross-user DELETE affects 0 rows
- [ ] Anonymous access returns 0 rows
- [ ] Anonymous INSERT is rejected
- [ ] Users can modify their own data successfully
