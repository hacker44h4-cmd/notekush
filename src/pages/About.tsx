import React from 'react'
import { BookOpen, Target, Users, Zap } from 'lucide-react'

export function About() {
  return (
    <div className="min-h-screen bg-white py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center mb-16">
          <BookOpen className="mx-auto h-16 w-16 text-blue-600 mb-6" />
          <h1 className="text-4xl font-bold text-gray-900 mb-6">About Note Nest</h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Bridging the gap between educators and students through secure, organized, and accessible academic resource sharing.
          </p>
        </div>

        {/* Mission */}
        <div className="bg-blue-50 rounded-2xl p-8 mb-16">
          <div className="text-center">
            <Target className="mx-auto h-12 w-12 text-blue-600 mb-4" />
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Our Mission</h2>
            <p className="text-lg text-gray-700 max-w-4xl mx-auto">
              To create a seamless, secure, and scalable platform that empowers educational institutions 
              to share knowledge effectively. We believe that access to quality educational resources 
              should be organized, secure, and available to all students and faculty members.
            </p>
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid lg:grid-cols-2 gap-12 mb-16">
          <div>
            <h2 className="text-3xl font-bold text-gray-900 mb-6">Platform Capabilities</h2>
            <div className="space-y-6">
              <div className="flex items-start space-x-4">
                <Users className="h-8 w-8 text-blue-600 flex-shrink-0 mt-1" />
                <div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">Role-Based Access Control</h3>
                  <p className="text-gray-600">
                    Secure authentication system with distinct roles for students, faculty, and administrators, 
                    ensuring appropriate access levels for each user type.
                  </p>
                </div>
              </div>
              
              <div className="flex items-start space-x-4">
                <BookOpen className="h-8 w-8 text-blue-600 flex-shrink-0 mt-1" />
                <div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">Department Organization</h3>
                  <p className="text-gray-600">
                    Notes are systematically organized by department and subject, making it easy for 
                    students to find relevant materials for their coursework.
                  </p>
                </div>
              </div>
              
              <div className="flex items-start space-x-4">
                <Zap className="h-8 w-8 text-blue-600 flex-shrink-0 mt-1" />
                <div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">Advanced Search & Filtering</h3>
                  <p className="text-gray-600">
                    Powerful search capabilities allowing users to find notes by faculty name, upload date, 
                    department, or subject with instant results.
                  </p>
                </div>
              </div>
            </div>
          </div>
          
          <div>
            <h2 className="text-3xl font-bold text-gray-900 mb-6">For Students</h2>
            <div className="bg-green-50 rounded-xl p-6 mb-6">
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Access & Download</h3>
              <ul className="space-y-2 text-gray-700">
                <li>• Browse notes from your department</li>
                <li>• Search by faculty or subject</li>
                <li>• Download materials for offline study</li>
                <li>• View upload dates and organize by recency</li>
              </ul>
            </div>
            
            <h2 className="text-3xl font-bold text-gray-900 mb-6">For Faculty</h2>
            <div className="bg-purple-50 rounded-xl p-6">
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Upload & Manage</h3>
              <ul className="space-y-2 text-gray-700">
                <li>• Upload notes linked to your subjects</li>
                <li>• Manage your uploaded content</li>
                <li>• Update or remove materials as needed</li>
                <li>• Track engagement with your resources</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Technology Stack */}
        <div className="bg-gray-50 rounded-2xl p-8">
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Built with Modern Technology</h2>
            <p className="text-lg text-gray-600">
              Note Nest leverages cutting-edge technologies to ensure security, performance, and scalability.
            </p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center">
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Frontend</h3>
              <p className="text-gray-600">React with TypeScript for a robust, type-safe user interface</p>
            </div>
            
            <div className="text-center">
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Backend</h3>
              <p className="text-gray-600">Supabase for authentication, database, and secure file storage</p>
            </div>
            
            <div className="text-center">
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Security</h3>
              <p className="text-gray-600">Row-level security, encrypted storage, and secure file handling</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
