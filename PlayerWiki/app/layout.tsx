import type { Metadata, Viewport } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'Bookbinder Player Wiki',
    template: '%s · Bookbinder Player Wiki',
  },
  description: 'Player-focused guides and reference pages for Bookbinder.',
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  colorScheme: 'light dark',
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#f7edcf' },
    { media: '(prefers-color-scheme: dark)', color: '#111b19' },
  ],
};

const themeInitialization = `
  try {
    const theme = window.localStorage.getItem('bookbinder-wiki-theme');
    if (theme === 'light' || theme === 'dark') {
      document.documentElement.dataset.theme = theme;
    }
  } catch {}
`;

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInitialization }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
