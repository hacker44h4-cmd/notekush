/*
          # [Operation Name]
          Fix Notes Table Schema and RLS Policies

          ## Query Description: [This migration corrects the 'notes' table schema by ensuring the 'uploaded_by' column exists and is properly linked to the 'profiles' table. It then drops all old security policies on the 'notes' table and re-creates them in the correct order to resolve dependency and recursion errors. This is a critical fix to make the notes feature functional for all user roles.]
          
          ## Metadata:
          - Schema-Category: ["Structural", "Safe"]
          - Impact-Level: ["High"]
          - Requires-Backup: true
          - Reversible: false
          
          ## Structure Details:
          - Tables affected: 'notes'
          - Columns affected: 'uploaded_by' (created if not exists, constraint added)
          - Policies affected: All RLS policies on 'notes' table are dropped and recreated.
          
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [Yes]
          - Auth Requirements: [Relies on the 'get_user_role' function and auth.uid()]
          
          ## Performance Impact:
          - Indexes: [Adds a foreign key index on 'uploaded_by']
          - Triggers: [None]
          - Estimated Impact: [Low. This is a structural change that will improve query performance for note lookups.]
          */

-- Step 1: Drop all existing policies on 'notes' to remove dependencies.
DROP POLICY IF EXISTS "Allow read access to own department" ON public.notes;
DROP POLICY IF EXISTS "Allow faculty to insert notes" ON public.notes;
DROP POLICY IF EXISTS "Allow faculty to update their own notes" ON public.notes;
DROP POLICY IF EXISTS "Allow faculty to delete their own notes" ON public.notes;
DROP POLICY IF EXISTS "Allow admin full access to notes" ON public.notes;

-- Step 2: Add the 'uploaded_by' column if it doesn't exist. This is the core fix.
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS uploaded_by UUID;

-- Step 3: Ensure the foreign key constraint is correctly set.
ALTER TABLE public.notes DROP CONSTRAINT IF EXISTS notes_uploaded_by_fkey;
ALTER TABLE public.notes ADD CONSTRAINT notes_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Step 4: Re-create the RLS policies for the 'notes' table correctly.

-- 4.1. Students can read notes from their own department.
CREATE POLICY "Allow read access to own department"
ON public.notes
FOR SELECT
USING (
  department = (
    SELECT department FROM public.profiles WHERE id = auth.uid()
  )
);

-- 4.2. Faculty can insert notes for their own department.
CREATE POLICY "Allow faculty to insert notes"
ON public.notes
FOR INSERT
WITH CHECK (
  get_user_role(auth.uid()) = 'faculty' AND
  uploaded_by = auth.uid() AND
  department = (
    SELECT department FROM public.profiles WHERE id = auth.uid()
  )
);

-- 4.3. Faculty can update their own notes.
CREATE POLICY "Allow faculty to update their own notes"
ON public.notes
FOR UPDATE
USING (
  get_user_role(auth.uid()) = 'faculty' AND
  uploaded_by = auth.uid()
)
WITH CHECK (
  get_user_role(auth.uid()) = 'faculty' AND
  uploaded_by = auth.uid()
);

-- 4.4. Faculty can delete their own notes.
CREATE POLICY "Allow faculty to delete their own notes"
ON public.notes
FOR DELETE
USING (
  get_user_role(auth.uid()) = 'faculty' AND
  uploaded_by = auth.uid()
);

-- 4.5. Admin can manage all notes.
CREATE POLICY "Allow admin full access to notes"
ON public.notes
FOR ALL
USING (get_user_role(auth.uid()) = 'admin');
