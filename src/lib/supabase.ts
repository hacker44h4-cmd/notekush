import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export type Profile = {
  id: string
  email: string
  name: string
  mobile_number?: string
  department: string
  role: 'student' | 'faculty' | 'admin'
  subjects?: string
  created_at: string
  updated_at: string
}

export type Note = {
  id: string
  title: string
  file_url: string
  file_name: string
  department: string
  subject: string
  faculty_id: string
  created_at: string
  updated_at: string
  profiles?: Profile
}
