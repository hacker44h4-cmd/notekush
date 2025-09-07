/*
# Initial Note Nest Database Schema
Creates the foundational database structure for the Note Nest academic notes sharing platform.

## Query Description:
This migration creates the core tables and relationships for managing user profiles, academic notes, and role-based access control. It establishes secure data storage for student and faculty interactions with academic content. The structure supports department-based organization and subject-specific note categorization. Backup recommended before applying as this creates the primary data structure.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Medium"
- Requires-Backup: true
- Reversible: true

## Structure Details:
- profiles table: User profiles linked to auth.users
- notes table: Academic notes with file storage references
- Foreign key relationships between users and their notes
- RLS policies for role-based access control

## Security Implications:
- RLS Status: Enabled on all public tables
- Policy Changes: Yes - creates comprehensive access policies
- Auth Requirements: Integration with Supabase Auth required

## Performance Impact:
- Indexes: Added on frequently queried columns (department, subject, faculty_id)
- Triggers: Profile creation trigger on auth.users
- Estimated Impact: Minimal - optimized for read-heavy operations
*/

-- Enable RLS on auth schema tables (if needed)
-- Note: We don't modify auth.users directly as it's system-managed

-- Create profiles table linked to auth.users
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  mobile TEXT,
  department TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'faculty', 'admin')),
  subjects TEXT[], -- Array of subjects for faculty
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notes table
CREATE TABLE public.notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  department TEXT NOT NULL,
  subject TEXT NOT NULL,
  faculty_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_profiles_department ON public.profiles(department);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_notes_department ON public.notes(department);
CREATE INDEX idx_notes_subject ON public.notes(subject);
CREATE INDEX idx_notes_faculty_id ON public.notes(faculty_id);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles table
-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Admin can view all profiles
CREATE POLICY "Admin can view all profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin can update all profiles
CREATE POLICY "Admin can update all profiles" ON public.profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin can delete profiles
CREATE POLICY "Admin can delete profiles" ON public.profiles
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for notes table
-- Faculty can insert notes
CREATE POLICY "Faculty can insert notes" ON public.notes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'faculty'
    ) AND faculty_id = auth.uid()
  );

-- Faculty can view their own notes
CREATE POLICY "Faculty can view own notes" ON public.notes
  FOR SELECT USING (faculty_id = auth.uid());

-- Faculty can update their own notes
CREATE POLICY "Faculty can update own notes" ON public.notes
  FOR UPDATE USING (faculty_id = auth.uid());

-- Faculty can delete their own notes
CREATE POLICY "Faculty can delete own notes" ON public.notes
  FOR DELETE USING (faculty_id = auth.uid());

-- Students can view notes from their department
CREATE POLICY "Students can view department notes" ON public.notes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
      AND role = 'student' 
      AND department = notes.department
    )
  );

-- Admin can view all notes
CREATE POLICY "Admin can view all notes" ON public.notes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin can update all notes
CREATE POLICY "Admin can update all notes" ON public.notes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin can delete all notes
CREATE POLICY "Admin can delete all notes" ON public.notes
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Function to handle profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create profile after email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    INSERT INTO public.profiles (id, name, email, department, role)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'name', ''),
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'department', ''),
      COALESCE(NEW.raw_user_meta_data->>'role', 'student')
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic profile creation
CREATE TRIGGER on_auth_user_created
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Insert pre-configured admin user (will be created when they sign up)
-- Note: The actual user will be created through the signup process
-- This just ensures the admin role is available

-- Create storage bucket for notes (if not exists)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('notes', 'notes', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for notes bucket
CREATE POLICY "Faculty can upload notes" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'notes' AND
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('faculty', 'admin')
    )
  );

CREATE POLICY "Users can view notes" ON storage.objects
  FOR SELECT USING (bucket_id = 'notes');

CREATE POLICY "Faculty can update own notes" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'notes' AND
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('faculty', 'admin')
    )
  );

CREATE POLICY "Faculty can delete own notes" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'notes' AND
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('faculty', 'admin')
    )
  );
