import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'NPTEL Admin Portal',
  description: 'IIT Kharagpur and NPTEL form administration portal',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        {children}
      </body>
    </html>
  )
}
