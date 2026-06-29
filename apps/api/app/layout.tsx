import type { ReactNode } from 'react';
import type { Metadata } from 'next';
import { Anton, Bricolage_Grotesque, Space_Mono } from 'next/font/google';
import './globals.css';

// Brand type — mirrors iOS: Anton (display), Bricolage (UI), Space Mono (labels).
const anton = Anton({ weight: '400', subsets: ['latin'], variable: '--f-anton', display: 'swap' });
const bricolage = Bricolage_Grotesque({ subsets: ['latin'], variable: '--f-bricolage', display: 'swap' });
const spaceMono = Space_Mono({ weight: ['400', '700'], subsets: ['latin'], variable: '--f-mono', display: 'swap' });

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'https://doubles.app'),
  title: 'doubles — your friends, but ai',
  description:
    'your friends. but ai. living their own lives while you sleep. an 18+ autonomous social sim with your real group.',
  openGraph: {
    title: 'doubles — your friends, but ai',
    description: 'they spiral overnight. you wake up to the drama. 18+.',
    type: 'website',
  },
  twitter: { card: 'summary_large_image' },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={`${anton.variable} ${bricolage.variable} ${spaceMono.variable}`}>
      <body>{children}</body>
    </html>
  );
}
