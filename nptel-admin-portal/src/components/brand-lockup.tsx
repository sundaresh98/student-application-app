import { GraduationCap, Radio } from 'lucide-react'

export function BrandLockup() {
  return (
    <div className="flex items-center gap-3">
      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-maroon text-white shadow-sm">
        <GraduationCap size={22} />
      </div>
      <div className="flex h-10 w-10 items-center justify-center rounded-lg border border-saffron bg-white text-maroon">
        <Radio size={21} />
      </div>
      <div className="hidden md:block">
        <div className="text-xs font-bold text-white">IIT KHARAGPUR</div>
        <div className="text-xs font-bold text-white">NPTEL ADMIN</div>
      </div>
    </div>
  )
}
