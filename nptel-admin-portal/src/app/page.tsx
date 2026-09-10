'use client'

export default function Home() {
  return (
    <main className="flex items-center justify-center min-h-screen bg-gray-50">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-navy mb-4">Welcome to NPTEL Admin Portal</h1>
        <p className="text-gray-600 mb-8">Managing forms and responses for IIT Kharagpur and NPTEL programmes</p>
        <a href="/login" className="inline-block px-6 py-3 bg-maroon text-white rounded-lg hover:bg-opacity-90">
          Go to Login
        </a>
      </div>
    </main>
  )
}
