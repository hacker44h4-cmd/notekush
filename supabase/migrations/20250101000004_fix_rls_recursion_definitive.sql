/*
# [Fix RLS Recursion Definitive]
This migration fixes the "infinite recursion" error by creating a SECURITY DEFINER function to safely check user roles, preventing circular dependencies in RLS policies. It drops all existing policies on profiles and notes and recreates them correctly.

## Query Description: [This operation overhauls the security policies for users and notes. It is a critical fix for the application's authentication and data access layer. No data will be lost, but access rules will be redefined. This is considered a safe and necessary structural change.]

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Medium"
- Requires-Backup: false
- Reversible: false

## Structure Details:
- Drops all policies on `public.profiles` and `public.notes`.
- Creates a new function `public.get_user_role(uuid)`.
- Re-creates all RLS policies for `public.profiles` and `public.notes` using the new function.

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes
- Auth Requirements: This fixes the core authentication issue.

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Positive. Resolves a blocking error.
*/

-- Drop all existing policies on profiles and notes to ensure a clean slate.
DROP POLICY IF EXISTS "Enable read access for admins" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for users to their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable update for users to their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable delete for admins" ON public.profiles;

DROP POLICY IF EXISTS "Admins can manage all notes" ON public.notes;
DROP POLICY IF EXISTS "Faculty can view notes in their department" ON public.notes;
DROP POLICY IF EXISTS "Students can view notes in their department" ON public.notes;
DROP POLICY IF EXISTS "Faculty can insert notes" ON public.notes;
DROP POLICY IF EXISTS "Faculty can update their own notes" ON public.notes;
DROP POLICY IF EXISTS "Faculty can delete their own notes" ON public.notes;

-- Drop function if it exists to ensure it's created with the correct settings.
DROP FUNCTION IF EXISTS public.get_user_role(user_id uuid);

-- Create a SECURITY DEFINER function to safely get a user's role without recursion.
-- This function runs with the privileges of the owner, bypassing the RLS policy that calls it.
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
-- SET search_path = public is a security best practice for SECURITY DEFINER functions.
SET search_path = public
AS $$
BEGIN
  RETURN (SELECT role FROM public.profiles WHERE id = user_id);
END;
$$;


-- Recreate policies for the 'profiles' table
-- Admins can see all profiles.
CREATE POLICY "Enable read access for admins" ON public.profiles
FOR SELECT TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin');

-- Users can see their own profile.
CREATE POLICY "Enable read access for users to their own profile" ON public.profiles
FOR SELECT TO authenticated
USING (auth.uid() = id);

-- Users can update their own profile.
CREATE POLICY "Enable update for users to their own profile" ON public.profiles
FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Admins can delete any profile.
CREATE POLICY "Enable delete for admins" ON public.profiles
FOR DELETE TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin');


-- Recreate policies for the 'notes' table
-- Admins can do anything with notes.
CREATE POLICY "Admins can manage all notes" ON public.notes
FOR ALL TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin')
WITH CHECK (public.get_user_role(auth.uid()) = 'admin');

-- Students can view notes in their own department.
CREATE POLICY "Students can view notes in their department" ON public.notes
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE public.profiles.id = auth.uid() AND public.profiles.department = notes.department
  )
);

-- Faculty can view notes in their own department.
CREATE POLICY "Faculty can view notes in their department" ON public.notes
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE public.profiles.id = auth.uid() AND public.profiles.department = notes.department
  )
);

-- Faculty can insert notes for their own department.
CREATE POLICY "Faculty can insert notes" ON public.notes
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE public.profiles.id = auth.uid()
      AND public.profiles.role = 'faculty'
      AND public.profiles.department = notes.department
      AND auth.uid() = notes.uploaded_by
  )
);

-- Faculty can update their own notes.
CREATE POLICY "Faculty can update their own notes" ON public.notes
FOR UPDATE TO authenticated
USING (auth.uid() = uploaded_by)
WITH CHECK (auth.uid() = uploaded_by);

-- Faculty can delete their own notes.
CREATE POLICY "Faculty can delete their own notes" ON public.notes
FOR DELETE TO authenticated
USING (auth.uid() = uploaded_by);
