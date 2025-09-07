/*
  # [Allow Profile Updates]
  This migration adds a new Row Level Security (RLS) policy to the `profiles` table.
  This policy is essential for allowing users to modify their own profile information,
  such as their name, mobile number, or subjects taught.

  ## Query Description:
  - This operation is safe and does not affect existing data.
  - It adds a security rule that enables the "Edit Profile" functionality in the application.
  - Without this policy, all attempts by users to update their profile will be denied by the database.

  ## Metadata:
  - Schema-Category: "Structural"
  - Impact-Level: "Low"
  - Requires-Backup: false
  - Reversible: true

  ## Structure Details:
  - Table: `public.profiles`
  - Operation: `CREATE POLICY`
  - Policy Name: "Allow users to update their own profile"

  ## Security Implications:
  - RLS Status: Enabled
  - Policy Changes: Yes (Adds a new UPDATE policy)
  - Auth Requirements: This policy applies to all authenticated users, but only allows them to affect their own row (`auth.uid() = id`).

  ## Performance Impact:
  - Indexes: None
  - Triggers: None
  - Estimated Impact: Negligible. The policy check is very efficient.
*/

CREATE POLICY "Allow users to update their own profile"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
