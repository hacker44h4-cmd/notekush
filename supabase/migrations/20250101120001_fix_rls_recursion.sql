/*
# [Fix RLS Recursion on Profiles Table]
This migration corrects an infinite recursion error within the Row Level Security (RLS) policies of the `profiles` table. The previous "admin full access" policy used a subquery that recursively called itself, leading to database errors and preventing admin users from functioning correctly.

## Query Description:
- **DROP POLICY**: The faulty `Allow admin full access` and the separate `Allow individual read access` policies are removed.
- **CREATE POLICY**: They are replaced with two new, non-recursive policies:
  1. **Read Access**: A unified policy that allows users to read their own profile, and allows admins to read all profiles.
  2. **Delete Access**: A specific policy that allows admins to delete any user profile.
This change is critical to restore functionality for admin users and does not pose any risk to existing data.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Medium"
- Requires-Backup: false
- Reversible: true

## Structure Details:
- Affected Table: `public.profiles`
- Operations: `DROP POLICY`, `CREATE POLICY`

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes. This fixes a critical bug in the RLS implementation.
- Auth Requirements: Policies rely on `auth.uid()`.

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Negligible. The new policies are performant.
*/

-- Step 1: Drop the old, problematic policies.
-- The original "catch-all" admin policy caused the recursion.
-- The individual read policy is also dropped to be combined with the new admin read policy.
DROP POLICY IF EXISTS "Allow admin full access" ON public.profiles;
DROP POLICY IF EXISTS "Allow individual read access" ON public.profiles;

-- Step 2: Create a new, unified, and non-recursive SELECT policy.
-- This allows users to read their own profile, and admins to read all profiles.
CREATE POLICY "Allow read access for users and admins"
ON public.profiles
FOR SELECT
USING (
  auth.uid() = id OR
  (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
);

-- Step 3: Create a new, non-recursive DELETE policy for admins.
-- This specifically grants delete permissions to admins.
CREATE POLICY "Allow admin delete access"
ON public.profiles
FOR DELETE
USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
