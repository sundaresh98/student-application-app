# PowerShell script to recreate nptel-admin-portal Next.js project structure
# Run from the nptel-admin-portal directory

Set-Location $PSScriptRoot

# Create directory structure
$directories = @(
  'src/app/access-control',
  'src/app/api/auth',
  'src/app/api/forms/[slug]',
  'src/app/forms/[slug]/responses',
  'src/app/forms/new',
  'src/app/insights',
  'src/app/login',
  'src/app/p/[code]',
  'src/app/public/[slug]',
  'src/app/settings',
  'src/components',
  'src/lib',
  'data',
  'prisma'
)

foreach ($dir in $directories) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  Write-Host "Created directory: $dir"
}

# === CONFIG FILES ===

# next.config.mjs
@"
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    remotePatterns: [],
  },
};

export default nextConfig;
"@ | Out-File -FilePath 'next.config.mjs' -Encoding UTF8

# postcss.config.mjs
@"
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
"@ | Out-File -FilePath 'postcss.config.mjs' -Encoding UTF8

# tailwind.config.ts
@"
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        navy: '#1a2332',
        maroon: '#862141',
        saffron: '#fdb913',
      },
      fontFamily: {
        display: 'system-ui, -apple-system, sans-serif',
      },
    },
  },
  plugins: [],
};

export default config;
"@ | Out-File -FilePath 'tailwind.config.ts' -Encoding UTF8

# middleware.ts
@"
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('auth_token')?.value;
  
  if (!token && !request.nextUrl.pathname.startsWith('/login') && !request.nextUrl.pathname.startsWith('/public')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico|public).*)',
  ],
};
"@ | Out-File -FilePath 'middleware.ts' -Encoding UTF8

# .env.local.example
@"
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/nptel_admin"

# Auth
AUTH_SECRET="your-secret-key-here"

# API
NEXT_PUBLIC_API_URL="http://localhost:3000/api"
"@ | Out-File -FilePath '.env.local.example' -Encoding UTF8

# === APP FILES ===

# src/app/globals.css
@"
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-white text-navy;
  }
}

.grid-paper {
  background-image: 
    linear-gradient(0deg, transparent 24%, rgba(255, 255, 255, .05) 25%, rgba(255, 255, 255, .05) 26%, transparent 27%, transparent 74%, rgba(255, 255, 255, .05) 75%, rgba(255, 255, 255, .05) 76%, transparent 77%, transparent),
    linear-gradient(90deg, transparent 24%, rgba(255, 255, 255, .05) 25%, rgba(255, 255, 255, .05) 26%, transparent 27%, transparent 74%, rgba(255, 255, 255, .05) 75%, rgba(255, 255, 255, .05) 76%, transparent 77%, transparent);
  background-size: 50px 50px;
}
"@ | Out-File -FilePath 'src/app/globals.css' -Encoding UTF8

# src/app/layout.tsx
@"
import type { Metadata } from 'next';
import { AppShell } from '@/components/app-shell';
import './globals.css';

export const metadata: Metadata = {
  title: 'NPTEL Admin Portal',
  description: 'Forms administration for IIT Kharagpur and NPTEL programmes',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AppShell>{children}</AppShell>
      </body>
    </html>
  );
}
"@ | Out-File -FilePath 'src/app/layout.tsx' -Encoding UTF8

# src/app/page.tsx
@"
'use client';

import { Dashboard } from '@/components/dashboard';

export default function Home() {
  return <Dashboard />;
}
"@ | Out-File -FilePath 'src/app/page.tsx' -Encoding UTF8

# src/app/login/page.tsx
@"
'use client';

import { useState } from 'react';
import { ArrowRight, Eye, EyeOff, LockKeyhole } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { BrandLockup } from '@/components/brand-lockup';

export default function LoginPage() {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function signIn(event: React.FormEvent) {
    event.preventDefault();
    setError('');
    setLoading(true);
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    setLoading(false);
    if (!response.ok) {
      const result = await response.json();
      setError(result.error ?? 'Unable to sign in.');
      return;
    }
    router.push('/');
  }

  return <main className="grid min-h-screen lg:grid-cols-[1.05fr_.95fr]">
    <section className="grid-paper relative hidden overflow-hidden bg-navy p-12 text-white lg:flex lg:flex-col lg:justify-between">
      <BrandLockup />
      <div className="relative max-w-lg pb-10"><p className="mb-5 text-xs font-bold uppercase tracking-[.24em] text-saffron">Institutional workspace</p><h1 className="font-display text-5xl font-bold leading-[1.05] tracking-tight">Forms that move learning forward.</h1><p className="mt-6 max-w-md text-sm leading-7 text-white/65">A focused administration layer for IIT Kharagpur and NPTEL programmes, from first question to final response export.</p></div>
      <p className="text-[11px] text-white/35">IIT Kharagpur · National Programme on Technology Enhanced Learning</p>
    </section>
    <section className="flex items-center justify-center bg-[#fbfcfd] px-6 py-12"><div className="w-full max-w-[390px]">
      <div className="mb-12 lg:hidden"><BrandLockup /></div><p className="text-xs font-bold uppercase tracking-[.2em] text-maroon">Admin access</p><h2 className="mt-3 font-display text-3xl font-bold tracking-tight text-navy">Welcome back.</h2><p className="mt-2 text-sm leading-6 text-[#7f8b9a]">Sign in to manage your forms, responses, and schedules.</p>
      <form onSubmit={signIn} className="mt-8 space-y-5"><label className="block text-xs font-bold text-navy">Institutional email<input type="email" required value={email} onChange={(event) => setEmail(event.target.value)} placeholder="name@iitkgp.ac.in" className="mt-2 h-12 w-full rounded-lg border border-[#dce2e9] bg-white px-4 text-sm outline-none focus:border-maroon" /></label><label className="block text-xs font-bold text-navy">Password<div className="relative mt-2"><input type={showPassword ? 'text' : 'password'} required value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Enter your password" className="h-12 w-full rounded-lg border border-[#dce2e9] bg-white px-4 pr-12 text-sm outline-none focus:border-maroon" /><button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-3 text-[#8993a1]">{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></div></label>
        {error && <p role="alert" className="rounded-lg border border-[#f1d7df] bg-[#fff8fa] px-3 py-2 text-xs font-semibold text-maroon">{error}</p>}
        <button disabled={loading} className="flex h-12 w-full items-center justify-center gap-2 rounded-lg bg-maroon text-sm font-bold text-white shadow-[0_5px_12px_rgba(134,31,65,.18)] disabled:cursor-wait disabled:opacity-70">{loading ? 'Signing in...' : 'Sign in securely'} {!loading && <ArrowRight size={17} />}</button>
      </form><div className="mt-8 flex items-center justify-center gap-2 text-[11px] text-[#9aa3af]"><LockKeyhole size={13} /> Protected administrative access</div>
    </div></section>
  </main>;
}
"@ | Out-File -FilePath 'src/app/login/page.tsx' -Encoding UTF8

# src/app/access-control/page.tsx
@"
'use client';

export default function AccessControlPage() {
  return (
    <main className="p-8">
      <h1 className="text-3xl font-bold mb-6">Access Control</h1>
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <p className="text-gray-600">Manage user roles and permissions here.</p>
      </div>
    </main>
  );
}
"@ | Out-File -FilePath 'src/app/access-control/page.tsx' -Encoding UTF8

# src/app/insights/page.tsx
@"
'use client';

export default function InsightsPage() {
  return (
    <main className="p-8">
      <h1 className="text-3xl font-bold mb-6">Insights</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="font-semibold text-lg mb-4">Forms Overview</h2>
          <p className="text-gray-600">Form statistics and analytics will appear here.</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="font-semibold text-lg mb-4">Response Metrics</h2>
          <p className="text-gray-600">Response data and trends will be displayed here.</p>
        </div>
      </div>
    </main>
  );
}
"@ | Out-File -FilePath 'src/app/insights/page.tsx' -Encoding UTF8

# src/app/settings/page.tsx
@"
'use client';

export default function SettingsPage() {
  return (
    <main className="p-8">
      <h1 className="text-3xl font-bold mb-6">Settings</h1>
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <p className="text-gray-600">Settings and configuration options will appear here.</p>
      </div>
    </main>
  );
}
"@ | Out-File -FilePath 'src/app/settings/page.tsx' -Encoding UTF8

# src/app/forms/[slug]/new/page.tsx
@"
'use client';

import { FormBuilder } from '@/components/form-builder';

export default function NewFormPage() {
  return (
    <main className="p-8">
      <h1 className="text-3xl font-bold mb-6">Create New Form</h1>
      <FormBuilder />
    </main>
  );
}
"@ | Out-File -FilePath 'src/app/forms/[slug]/new/page.tsx' -Encoding UTF8

# src/app/forms/[slug]/responses/page.tsx
@"
'use client';

import { useParams } from 'next/navigation';

export default function FormResponsesPage() {
  const params = useParams();
  const slug = params.slug as string;

  return (
    <main className="p-8">
      <h1 className="text-3xl font-bold mb-6">Form Responses: {slug}</h1>
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <p className="text-gray-600">Responses for this form will appear here.</p>
      </div>
    </main>
  );
}
"@ | Out-File -FilePath 'src/app/forms/[slug]/responses/page.tsx' -Encoding UTF8

# src/app/p/[code]/page.tsx
@"
'use client';

import { useParams } from 'next/navigation';

export default function PublicFormPage() {
  const params = useParams();
  const code = params.code as string;

  return (
    <main className="flex flex-col items-center justify-center min-h-screen bg-gray-50 p-8">
      <div className="bg-white rounded-lg border border-gray-200 p-8 max-w-2xl">
        <p className="text-gray-600">Public form with code: {code}</p>
      </div>
    </main>
  );
}
"@ | Out-File -FilePath 'src/app/p/[code]/page.tsx' -Encoding UTF8

# src/app/public/[slug]/page.tsx
@"
'use client';

import { useParams } from 'next/navigation';

export default function PublicFormBySlugPage() {
  const params = useParams();
  const slug = params.slug as string;

  return (
    <main className="flex flex-col items-center justify-center min-h-screen bg-gray-50 p-8">
      <div className="bg-white rounded-lg border border-gray-200 p-8 max-w-2xl">
        <p className="text-gray-600">Public form: {slug}</p>
      </div>
    </main>
  );
}
"@ | Out-File -FilePath 'src/app/public/[slug]/page.tsx' -Encoding UTF8

# === API ROUTES ===

# src/app/api/auth/login/route.ts
@"
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();

    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email and password are required' },
        { status: 400 }
      );
    }

    // TODO: Implement actual authentication logic with database
    // For now, return a mock response
    const response = NextResponse.json({
      success: true,
      user: { email },
    });

    response.cookies.set('auth_token', 'mock_token', {
      httpOnly: true,
      maxAge: 60 * 60 * 24 * 7, // 7 days
    });

    return response;
  } catch (error) {
    return NextResponse.json(
      { error: 'Authentication failed' },
      { status: 500 }
    );
  }
}
"@ | Out-File -FilePath 'src/app/api/auth/login/route.ts' -Encoding UTF8

# src/app/api/auth/logout/route.ts
@"
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const response = NextResponse.json({ success: true });
  response.cookies.delete('auth_token');
  return response;
}
"@ | Out-File -FilePath 'src/app/api/auth/logout/route.ts' -Encoding UTF8

# src/app/api/forms/route.ts
@"
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    // TODO: Fetch forms from database
    const forms = [];
    return NextResponse.json(forms);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch forms' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    // TODO: Save form to database
    return NextResponse.json({ success: true, form: body }, { status: 201 });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to create form' },
      { status: 500 }
    );
  }
}
"@ | Out-File -FilePath 'src/app/api/forms/route.ts' -Encoding UTF8

# src/app/api/forms/[slug]/route.ts
@"
import { NextRequest, NextResponse } from 'next/server';

export async function GET(
  request: NextRequest,
  { params }: { params: { slug: string } }
) {
  try {
    const slug = params.slug;
    // TODO: Fetch form from database by slug
    return NextResponse.json({ slug });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch form' },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { slug: string } }
) {
  try {
    const slug = params.slug;
    const body = await request.json();
    // TODO: Update form in database
    return NextResponse.json({ success: true, slug });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to update form' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { slug: string } }
) {
  try {
    const slug = params.slug;
    // TODO: Delete form from database
    return NextResponse.json({ success: true, slug });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to delete form' },
      { status: 500 }
    );
  }
}
"@ | Out-File -FilePath 'src/app/api/forms/[slug]/route.ts' -Encoding UTF8

# src/app/api/forms/export/route.ts
@"
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { formId, format } = await request.json();
    
    if (!formId) {
      return NextResponse.json(
        { error: 'Form ID is required' },
        { status: 400 }
      );
    }

    // TODO: Implement export logic (CSV, Excel, JSON, etc.)
    const filename = \`form-responses-\${new Date().toISOString().split('T')[0]}.\${format || 'csv'}\`;
    
    return new NextResponse('No data', {
      headers: {
        'Content-Type': format === 'json' ? 'application/json' : 'text/csv',
        'Content-Disposition': \`attachment; filename="\${filename}"\`,
      },
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to export data' },
      { status: 500 }
    );
  }
}
"@ | Out-File -FilePath 'src/app/api/forms/export/route.ts' -Encoding UTF8

# === COMPONENTS ===

# src/components/app-shell.tsx
@"
'use client';

import { usePathname } from 'next/navigation';
import Link from 'next/link';

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isLoginPage = pathname === '/login';

  if (isLoginPage) {
    return <>{children}</>;
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <aside className="w-64 bg-navy text-white p-6">
        <h1 className="text-xl font-bold mb-8">NPTEL Admin</h1>
        <nav className="space-y-2">
          <Link href="/" className="block px-4 py-2 rounded hover:bg-navy/80">
            Dashboard
          </Link>
          <Link href="/access-control" className="block px-4 py-2 rounded hover:bg-navy/80">
            Access Control
          </Link>
          <Link href="/insights" className="block px-4 py-2 rounded hover:bg-navy/80">
            Insights
          </Link>
          <Link href="/settings" className="block px-4 py-2 rounded hover:bg-navy/80">
            Settings
          </Link>
        </nav>
      </aside>
      <main className="flex-1">
        {children}
      </main>
    </div>
  );
}
"@ | Out-File -FilePath 'src/components/app-shell.tsx' -Encoding UTF8

# src/components/brand-lockup.tsx
@"
export function BrandLockup() {
  return (
    <div className="flex items-center gap-3">
      <div className="w-10 h-10 bg-saffron rounded-lg flex items-center justify-center font-bold text-navy">
        N
      </div>
      <div>
        <p className="text-xs font-bold">NPTEL</p>
        <p className="text-[10px] text-white/70">Admin Portal</p>
      </div>
    </div>
  );
}
"@ | Out-File -FilePath 'src/components/brand-lockup.tsx' -Encoding UTF8

# src/components/dashboard.tsx
@"
'use client';

import Link from 'next/link';

export function Dashboard() {
  return (
    <div className="p-8">
      <h1 className="text-4xl font-bold mb-8">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">Active Forms</h2>
          <p className="text-3xl font-bold text-maroon">0</p>
        </div>
        
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">Total Responses</h2>
          <p className="text-3xl font-bold text-maroon">0</p>
        </div>
        
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">Users</h2>
          <p className="text-3xl font-bold text-maroon">0</p>
        </div>
      </div>

      <div className="mt-8">
        <Link href="/forms/new" className="inline-block px-6 py-3 bg-maroon text-white rounded-lg font-semibold hover:bg-maroon/90">
          Create New Form
        </Link>
      </div>
    </div>
  );
}
"@ | Out-File -FilePath 'src/components/dashboard.tsx' -Encoding UTF8

# src/components/form-builder.tsx
@"
'use client';

import { useState } from 'react';

interface FormField {
  id: string;
  label: string;
  type: 'text' | 'email' | 'number' | 'textarea' | 'select';
  required: boolean;
}

export function FormBuilder() {
  const [fields, setFields] = useState<FormField[]>([]);
  const [formName, setFormName] = useState('');

  const addField = () => {
    const newField: FormField = {
      id: \`field-\${Date.now()}\`,
      label: 'New Field',
      type: 'text',
      required: false,
    };
    setFields([...fields, newField]);
  };

  const removeField = (id: string) => {
    setFields(fields.filter(f => f.id !== id));
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6 max-w-2xl">
      <div className="mb-6">
        <label className="block text-sm font-semibold mb-2">Form Name</label>
        <input
          type="text"
          value={formName}
          onChange={(e) => setFormName(e.target.value)}
          placeholder="Enter form name"
          className="w-full px-4 py-2 border border-gray-300 rounded-lg"
        />
      </div>

      <div className="space-y-4 mb-6">
        {fields.map((field) => (
          <div key={field.id} className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg">
            <div className="flex-1">
              <input
                type="text"
                value={field.label}
                onChange={(e) => {
                  const updated = fields.map(f =>
                    f.id === field.id ? { ...f, label: e.target.value } : f
                  );
                  setFields(updated);
                }}
                placeholder="Field label"
                className="w-full px-3 py-2 border border-gray-300 rounded"
              />
            </div>
            <select
              value={field.type}
              onChange={(e) => {
                const updated = fields.map(f =>
                  f.id === field.id ? { ...f, type: e.target.value as FormField['type'] } : f
                );
                setFields(updated);
              }}
              className="px-3 py-2 border border-gray-300 rounded"
            >
              <option value="text">Text</option>
              <option value="email">Email</option>
              <option value="number">Number</option>
              <option value="textarea">Textarea</option>
              <option value="select">Select</option>
            </select>
            <button
              onClick={() => removeField(field.id)}
              className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
            >
              Remove
            </button>
          </div>
        ))}
      </div>

      <button
        onClick={addField}
        className="px-6 py-2 bg-maroon text-white rounded-lg font-semibold hover:bg-maroon/90"
      >
        Add Field
      </button>
    </div>
  );
}
"@ | Out-File -FilePath 'src/components/form-builder.tsx' -Encoding UTF8

# === LIB FILES ===

# src/lib/validation.ts
@"
export function validateEmail(email: string): boolean {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+\$/;
  return re.test(email);
}

export function validateForm(data: Record<string, any>): { valid: boolean; errors: Record<string, string> } {
  const errors: Record<string, string> = {};

  for (const [key, value] of Object.entries(data)) {
    if (!value) {
      errors[key] = 'This field is required';
    }
  }

  return {
    valid: Object.keys(errors).length === 0,
    errors,
  };
}
"@ | Out-File -FilePath 'src/lib/validation.ts' -Encoding UTF8

# src/lib/csv.ts
@"
export function parseCSV(csvText: string): Record<string, any>[] {
  const lines = csvText.trim().split('\n');
  if (lines.length < 2) return [];

  const headers = lines[0].split(',').map(h => h.trim());
  const data = lines.slice(1).map(line => {
    const values = line.split(',').map(v => v.trim());
    return headers.reduce((obj, header, index) => {
      obj[header] = values[index] || '';
      return obj;
    }, {} as Record<string, any>);
  });

  return data;
}

export function convertToCSV(data: Record<string, any>[]): string {
  if (data.length === 0) return '';

  const headers = Object.keys(data[0]);
  const csv = [
    headers.join(','),
    ...data.map(row => headers.map(h => JSON.stringify(row[h] || '')).join(','))
  ];

  return csv.join('\n');
}
"@ | Out-File -FilePath 'src/lib/csv.ts' -Encoding UTF8

# src/lib/forms-store.ts
@"
export interface Form {
  id: string;
  slug: string;
  name: string;
  description?: string;
  fields: FormField[];
  createdAt: Date;
  updatedAt: Date;
}

export interface FormField {
  id: string;
  label: string;
  type: string;
  required: boolean;
}

// In-memory store for development
let forms: Map<string, Form> = new Map();

export function createForm(form: Omit<Form, 'id' | 'createdAt' | 'updatedAt'>): Form {
  const newForm: Form = {
    ...form,
    id: Math.random().toString(36).substr(2, 9),
    createdAt: new Date(),
    updatedAt: new Date(),
  };
  forms.set(newForm.id, newForm);
  return newForm;
}

export function getForm(id: string): Form | undefined {
  return forms.get(id);
}

export function getAllForms(): Form[] {
  return Array.from(forms.values());
}

export function updateForm(id: string, updates: Partial<Form>): Form | undefined {
  const form = forms.get(id);
  if (!form) return undefined;
  const updated = { ...form, ...updates, updatedAt: new Date() };
  forms.set(id, updated);
  return updated;
}

export function deleteForm(id: string): boolean {
  return forms.delete(id);
}
"@ | Out-File -FilePath 'src/lib/forms-store.ts' -Encoding UTF8

# src/lib/demo-data.ts
@"
export const demoForms = [
  {
    id: '1',
    name: 'Student Feedback Survey',
    slug: 'student-feedback',
    description: 'Collect feedback from students about their learning experience',
    fields: [
      { id: 'f1', label: 'Your Name', type: 'text', required: true },
      { id: 'f2', label: 'Email', type: 'email', required: true },
      { id: 'f3', label: 'Course Name', type: 'text', required: true },
      { id: 'f4', label: 'Rating', type: 'select', required: true },
      { id: 'f5', label: 'Comments', type: 'textarea', required: false },
    ],
  },
  {
    id: '2',
    name: 'Application Form',
    slug: 'application-form',
    description: 'Program application form',
    fields: [
      { id: 'f1', label: 'Full Name', type: 'text', required: true },
      { id: 'f2', label: 'Email', type: 'email', required: true },
      { id: 'f3', label: 'Phone Number', type: 'text', required: true },
    ],
  },
];

export const demoResponses = [
  {
    formId: '1',
    responses: [
      { name: 'John Doe', email: 'john@example.com', course: 'Machine Learning', rating: '5', comments: 'Great course!' },
      { name: 'Jane Smith', email: 'jane@example.com', course: 'Web Development', rating: '4', comments: 'Very informative' },
    ],
  },
];
"@ | Out-File -FilePath 'src/lib/demo-data.ts' -Encoding UTF8

# === DATA FILES ===

# data/forms.json
@"
{
  "forms": [
    {
      "id": "1",
      "name": "Student Feedback Survey",
      "slug": "student-feedback",
      "description": "Collect feedback from students",
      "fields": [
        {
          "id": "f1",
          "label": "Your Name",
          "type": "text",
          "required": true
        },
        {
          "id": "f2",
          "label": "Email",
          "type": "email",
          "required": true
        }
      ]
    }
  ]
}
"@ | Out-File -FilePath 'data/forms.json' -Encoding UTF8

# === PRISMA ===

# prisma/schema.prisma
@"
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String     @id @default(cuid())
  email     String     @unique
  password  String
  name      String?
  role      String     @default("user")
  createdAt DateTime   @default(now())
  updatedAt DateTime   @updatedAt
  forms     Form[]
  responses FormResponse[]
}

model Form {
  id          String     @id @default(cuid())
  name        String
  slug        String     @unique
  description String?
  fields      FormField[]
  responses   FormResponse[]
  createdBy   User       @relation(fields: [createdById], references: [id])
  createdById String
  createdAt   DateTime   @default(now())
  updatedAt   DateTime   @updatedAt
}

model FormField {
  id        String   @id @default(cuid())
  label     String
  type      String
  required  Boolean  @default(false)
  order     Int
  form      Form     @relation(fields: [formId], references: [id], onDelete: Cascade)
  formId    String
}

model FormResponse {
  id        String   @id @default(cuid())
  data      Json
  form      Form     @relation(fields: [formId], references: [id], onDelete: Cascade)
  formId    String
  submittedBy User    @relation(fields: [userId], references: [id])
  userId    String
  createdAt DateTime @default(now())
}
"@ | Out-File -FilePath 'prisma/schema.prisma' -Encoding UTF8

# .gitignore
@"
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/

# Next.js
.next/
out/
build/

# Environment variables
.env
.env.local
.env.production.local
.env.development.local
.env.test.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*

# Prisma
prisma/migrations/
"@ | Out-File -FilePath '.gitignore' -Encoding UTF8

Write-Host "`n✓ Project structure recreation complete!"
Write-Host "`nNext steps:`n"
Write-Host "1. Run: npm install"
Write-Host "2. Set up your DATABASE_URL in .env.local"
Write-Host "3. Run: npx prisma migrate dev"
Write-Host "4. Run: npm run dev`n"
