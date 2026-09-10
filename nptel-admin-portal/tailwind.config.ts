import type { Config } from 'tailwindcss'

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
        saffron: '#f59e0b',
      },
      fontFamily: {
        display: ['var(--font-display)', 'system-ui'],
      },
    },
  },
  plugins: [],
}
export default config
