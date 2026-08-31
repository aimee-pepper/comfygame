import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: { default: 'Bookbinder Player Wiki', template: '%s · Bookbinder Player Wiki' },
  description: 'Player-focused guides and reference pages for Bookbinder.',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
