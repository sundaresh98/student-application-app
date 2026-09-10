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
