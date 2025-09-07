/*
# [Policy] Allow Individual Profile Updates
This migration adds a new Row Level Security (RLS) policy to the `profiles` table. This policy is essential for allowing users to update their own profile information, such as their name, mobile number, or subjects taught.

## Query Description:
This operation is safe and non-destructive. It adds a security rule to the database that enables profile update functionality. It does not alter or delete any existing data.

## Metadata:
- Schema-Category: "Security"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true (The policy can be dropped)

## Structure Details:
- Table: `public.profiles`
- Operation: `CREATE POLICY`

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes. Adds a new `UPDATE` policy.
- Auth Requirements: This policy relies on `auth.uid()` to identify the currently logged-in user.

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Negligible. This is a standard RLS policy check.
*/

-- Drop the existing update policy if it exists, to avoid conflicts
DROP POLICY IF EXISTS "Allow individual profile updates" ON public.profiles;

-- Create the policy that allows users to update their own profile
CREATE POLICY "Allow individual profile updates"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
