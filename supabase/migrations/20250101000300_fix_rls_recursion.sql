/*
# [Fix] RLS Infinite Recursion on Profiles

This migration fixes an infinite recursion error in the Row Level Security (RLS) policies for the `profiles` table. The previous policies caused a loop when an admin user tried to access data. This script replaces the faulty policies with a secure, non-recursive implementation.

## Query Description:
This operation will drop and recreate all RLS policies on the `public.profiles` table. It introduces a security-hardened function (`get_user_role`) to safely check a user's role without causing recursion. Existing application functionality for students and faculty will be preserved, and admin access will be restored. There is no risk to existing data.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Medium"
- Requires-Backup: false
- Reversible: true

## Structure Details:
- **Tables Affected**: `public.profiles` (Policies only)
- **Functions Created**: `public.get_user_role(uuid)`
- **Policies Dropped**: All existing policies on `public.profiles` will be removed and replaced.
- **Policies Created**:
  - "Allow users to view their own profile"
  - "Allow users to update their own profile"
  - "Allow admins to view all profiles"
  - "Allow admins to update any user profile"
  - "Allow admins to delete any user"

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes. This change is critical for fixing a security policy bug.
- Auth Requirements: Policies rely on `auth.uid()`.

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Negligible. The function call is lightweight.
*/

-- Step 1: Drop all existing policies on the profiles table to ensure a clean slate.
DROP POLICY IF EXISTS "Allow users to view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins have full access" ON public.profiles;
DROP POLICY IF EXISTS "Admin can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin can delete any user" ON public.profiles;
DROP POLICY IF EXISTS "Allow admins to view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow admins to delete any user" ON public.profiles;
DROP POLICY IF EXISTS "Allow admins to update any user profile" ON public.profiles;


-- Step 2: Create a SECURITY DEFINER function to get the user's role safely.
-- This function runs with the permissions of the user who defined it (the owner),
-- bypassing the RLS policies of the user calling it, thus preventing recursion.
-- The search_path is explicitly set to prevent security vulnerabilities.
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT role FROM public.profiles WHERE id = user_id;
$$;


-- Step 3: Recreate the necessary policies using the new helper function for admin checks.

-- Policy 1: Users can view their own profile.
CREATE POLICY "Allow users to view their own profile"
ON public.profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy 2: Users can update their own profile.
CREATE POLICY "Allow users to update their own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy 3: Admins can view all profiles.
-- This uses the helper function to avoid recursion.
CREATE POLICY "Allow admins to view all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin');

-- Policy 4: Admins can update any user's profile.
CREATE POLICY "Allow admins to update any user profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin');

-- Policy 5: Admins can delete any user (except themselves, for safety).
CREATE POLICY "Allow admins to delete any user"
ON public.profiles FOR DELETE
TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin' AND auth.uid() <> id);
