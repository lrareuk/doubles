import type { ReactNode } from 'react';

export const metadata = {
  title: 'Doubles API',
  description: 'API host for Doubles — the autonomous AI social sim.',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
