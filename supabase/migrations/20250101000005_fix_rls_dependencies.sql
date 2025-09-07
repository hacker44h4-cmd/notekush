/*
# [Fix RLS Policies and Function Dependencies]
This migration script resolves a critical dependency issue by correctly dropping and recreating RLS policies and the associated helper function. It addresses the "infinite recursion" and "cannot drop function" errors by ensuring operations are performed in the correct order.

## Query Description:
This operation will first remove all existing RLS policies from the `profiles` and `notes` tables. It then drops the `get_user_role` helper function. Finally, it recreates the function and all RLS policies from scratch with the correct, non-recursive logic. This is a safe operation as it only restructures security rules without altering user data.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Medium"
- Requires-Backup: false
- Reversible: false

## Structure Details:
- Drops all policies on `public.profiles` and `public.notes`.
- Drops the function `public.get_user_role(uuid)`.
- Recreates the function `public.get_user_role(uuid)`.
- Recreates all RLS policies for `profiles` and `notes` tables.

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes
- Auth Requirements: This script defines the core authentication and authorization logic for the application.

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Low. This is a metadata change and will not impact query performance.
*/

-- Step 1: Drop all existing policies on the profiles table to remove dependencies.
DROP POLICY IF EXISTS "Allow profile read access" ON public.profiles;
DROP POLICY IF EXISTS "Allow individual profile update" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin read access" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin delete access" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.profiles;

-- Step 2: Drop all existing policies on the notes table to remove dependencies.
DROP POLICY IF EXISTS "Allow read access based on department" ON public.notes;
DROP POLICY IF EXISTS "Allow faculty to insert their own notes" ON public.notes;
DROP POLICY IF EXISTS "Allow faculty to update their own notes" ON public.notes;
DROP POLICY IF EXISTS "Allow faculty to delete their own notes" ON public.notes;
DROP POLICY IF EXISTS "Allow admin full access to notes" ON public.notes;

-- Step 3: Now that no policies depend on it, drop the function.
DROP FUNCTION IF EXISTS public.get_user_role(user_id uuid);

-- Step 4: Recreate the helper function with SECURITY DEFINER.
-- This function safely retrieves a user's role, avoiding recursive RLS checks.
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role FROM profiles WHERE id = user_id;
  RETURN user_role;
END;
$$;

-- Step 5: Recreate RLS policies for the 'profiles' table using the helper function.

-- Policy 1: Users can read their own profile.
CREATE POLICY "Allow profile read access"
ON public.profiles
FOR SELECT USING (
  auth.uid() = id
);

-- Policy 2: Users can update their own profile.
CREATE POLICY "Allow individual profile update"
ON public.profiles
FOR UPDATE USING (
  auth.uid() = id
);

-- Policy 3: Admins can read all profiles.
CREATE POLICY "Allow admin read access"
ON public.profiles
FOR SELECT USING (
  public.get_user_role(auth.uid()) = 'admin'
);

-- Policy 4: Admins can delete any profile.
CREATE POLICY "Allow admin delete access"
ON public.profiles
FOR DELETE USING (
  public.get_user_role(auth.uid()) = 'admin'
);

-- Step 6: Recreate RLS policies for the 'notes' table using the helper function.

-- Policy 1: Users can read notes from their own department.
CREATE POLICY "Allow read access based on department"
ON public.notes
FOR SELECT USING (
  department = (SELECT department FROM public.profiles WHERE id = auth.uid())
);

-- Policy 2: Faculty can insert notes for their own department.
CREATE POLICY "Allow faculty to insert their own notes"
ON public.notes
FOR INSERT WITH CHECK (
  auth.uid() = uploaded_by AND
  public.get_user_role(auth.uid()) = 'faculty'
);

-- Policy 3: Faculty can update their own notes.
CREATE POLICY "Allow faculty to update their own notes"
ON public.notes
FOR UPDATE USING (
  auth.uid() = uploaded_by AND
  public.get_user_role(auth.uid()) = 'faculty'
);

-- Policy 4: Faculty can delete their own notes.
CREATE POLICY "Allow faculty to delete their own notes"
ON public.notes
FOR DELETE USING (
  auth.uid() = uploaded_by AND
  public.get_user_role(auth.uid()) = 'faculty'
);

-- Policy 5: Admins have full access to all notes.
CREATE POLICY "Allow admin full access to notes"
ON public.notes
FOR ALL USING (
  public.get_user_role(auth.uid()) = 'admin'
);
