/*
# [Fix] Correct RLS Policy for Reading Profiles
This migration corrects the Row Level Security (RLS) policies on the `profiles` table to allow note queries to correctly retrieve the name of the faculty member who uploaded the note.

## Query Description:
The previous `SELECT` policies on the `profiles` table were too restrictive. They only allowed users to read their own profile, or allowed admins to read all profiles. This prevented a student from seeing the name of a faculty member in a joined query, resulting in "Unknown" being displayed.

This script replaces the restrictive policies with a single policy that allows any authenticated user to read any profile. This is safe because the `profiles` table contains information (like name, department, role) that is intended to be visible within the application, and sensitive operations like `UPDATE` and `DELETE` are still protected by their own restrictive policies.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true

## Structure Details:
- Modifies RLS policies on `public.profiles`.

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes. Broadens read access on the `profiles` table for authenticated users, which is necessary for application functionality. Write/delete access remains restricted.
- Auth Requirements: Authenticated

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Negligible.
*/

-- Step 1: Drop the old, restrictive SELECT policies on the profiles table.
-- We use "IF EXISTS" to prevent errors if the policies have different names or don't exist.
DROP POLICY IF EXISTS "Allow individual profile read" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin read access to profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to read basic profile info" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin read access to profiles" ON public.profiles;


-- Step 2: Create a new, single SELECT policy that allows any authenticated user to read profiles.
-- This is necessary for relationships (like fetching a note's author) to work correctly for all users.
CREATE POLICY "Allow authenticated users to read profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);
