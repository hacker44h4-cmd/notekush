/*
# [Fix] Correct RLS Infinite Recursion on Profiles

This migration fixes a critical "infinite recursion" error in the Row Level Security (RLS) policies for the `profiles` table. The error occurs when an admin policy tries to check the user's role by querying the `profiles` table, which triggers the same policy again, leading to a loop.

## Query Description:
This script corrects the issue by creating a `SECURITY DEFINER` helper function, `get_user_role`, which can safely check a user's role without re-triggering RLS. It then replaces the faulty admin policies with new ones that use this function. This is a safe, standard, and permanent fix for this common RLS issue. There is no risk to existing data.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true

## Structure Details:
- **Drops Policies**: `Allow admin full access`, `Allow admin read access`, `Allow admin delete access` on `public.profiles`.
- **Creates Function**: `public.get_user_role(uuid)` with `SECURITY DEFINER`.
- **Creates Policies**: New `Allow admin read access` and `Allow admin delete access` policies that use the new function.

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes. Replaces faulty policies with secure, non-recursive ones.
- Auth Requirements: Policies continue to rely on `auth.uid()`.

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Negligible. The function call is highly efficient.
*/

-- Step 1: Drop all potentially faulty admin policies on the profiles table.
DROP POLICY IF EXISTS "Allow admin full access" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin read access" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin delete access" ON public.profiles;

-- Step 2: Create a helper function to get a user's role securely.
-- The `SECURITY DEFINER` clause is crucial; it makes the function execute with the
-- permissions of the function owner, bypassing the RLS policy of the calling user
-- and thus preventing the infinite recursion.
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
-- Set a secure search_path to prevent hijacking.
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = user_id;
$$;

-- Step 3: Re-create the admin policies using the secure helper function.
-- These policies now correctly grant access without causing recursion.

-- Admins can read all user profiles.
CREATE POLICY "Allow admin read access" ON public.profiles
FOR SELECT
TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin');

-- Admins can delete any user (except themselves, as a safety measure).
CREATE POLICY "Allow admin delete access" ON public.profiles
FOR DELETE
TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin' AND id <> auth.uid());

-- Step 4: Ensure individual user policies are still in place and correct.
-- This ensures users can still manage their own profiles.
DROP POLICY IF EXISTS "Allow individual read access" ON public.profiles;
CREATE POLICY "Allow individual read access" ON public.profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Allow individual update access" ON public.profiles;
CREATE POLICY "Allow individual update access" ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
