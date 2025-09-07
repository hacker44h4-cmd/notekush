/*
# [Migration: Fix RLS Recursion on Profiles]
This migration resolves an infinite recursion error in the Row Level Security (RLS) policies for the `profiles` table. The previous admin policy was causing a loop by querying the `profiles` table to determine the user's role.

This fix introduces a `SECURITY DEFINER` function to safely check the user's role and replaces the old, broad admin policy with specific, non-recursive policies for read and delete operations.

## Query Description:
- **Safety**: This operation is safe and does not risk data loss. It modifies security policies only.
- **Impact**: Resolves application errors related to fetching user profiles, especially for admin users. The application should become functional again after applying this migration.
- **Recommendation**: Apply this migration to fix the critical authentication and data access bug.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "High"
- Requires-Backup: false
- Reversible: true (by reverting to old policies)

## Structure Details:
- Drops all existing policies on `public.profiles`.
- Creates a new function `public.get_user_role(uuid)`.
- Creates new, non-recursive RLS policies for `SELECT`, `UPDATE`, and `DELETE` on `public.profiles`.

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes. Policies are now more specific and secure, preventing recursion.
- Auth Requirements: Relies on `auth.uid()` and the `role` column in `profiles`.
*/

-- Step 1: Drop all existing policies on the profiles table to ensure a clean state.
DO $$
DECLARE
    policy_name text;
BEGIN
    FOR policy_name IN (SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_name || '" ON public.profiles;';
    END LOOP;
END;
$$;


-- Step 2: Create a helper function to safely get the user's role.
-- This function runs with the permissions of the owner, bypassing the caller's RLS
-- and thus preventing recursion.
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  role_name text;
BEGIN
  -- Bypasses RLS because it's a SECURITY DEFINER
  SELECT role INTO role_name FROM public.profiles WHERE id = user_id;
  RETURN role_name;
END;
$$;


-- Step 3: Create the new, non-recursive policies for the profiles table.

-- Users can view their own profile, and admins can view all profiles.
CREATE POLICY "Allow profile read access" ON public.profiles
FOR SELECT
USING (
  auth.uid() = id OR
  public.get_user_role(auth.uid()) = 'admin'
);

-- Users can update their own profile.
CREATE POLICY "Allow profile update access" ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Admins can delete any profile (except their own, for safety).
CREATE POLICY "Allow admin delete access" ON public.profiles
FOR DELETE
USING (
  public.get_user_role(auth.uid()) = 'admin' AND
  auth.uid() <> id -- Admins cannot delete themselves
);
