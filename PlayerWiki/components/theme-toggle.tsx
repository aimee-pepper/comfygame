'use client';

import { Moon, Sun } from 'lucide-react';
import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';

const preferenceKey = 'bookbinder-wiki-theme';

export function ThemeToggle() {
  const [isDark, setIsDark] = useState(false);

  useEffect(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)');

    const applyPreference = () => {
      const savedTheme = window.localStorage.getItem(preferenceKey);
      const dark =
        savedTheme === 'dark' || (savedTheme !== 'light' && media.matches);
      setIsDark(dark);
      if (savedTheme === 'dark' || savedTheme === 'light') {
        document.documentElement.dataset.theme = savedTheme;
      } else {
        document.documentElement.removeAttribute('data-theme');
      }
    };

    applyPreference();
    media.addEventListener('change', applyPreference);
    return () => media.removeEventListener('change', applyPreference);
  }, []);

  const toggleTheme = () => {
    const nextTheme = isDark ? 'light' : 'dark';
    window.localStorage.setItem(preferenceKey, nextTheme);
    document.documentElement.dataset.theme = nextTheme;
    setIsDark(!isDark);
  };

  return (
    <Button
      className="theme-toggle"
      variant="ghost"
      size="icon-lg"
      onClick={toggleTheme}
      aria-label={`Switch to ${isDark ? 'light' : 'dark'} mode`}
      title={`Switch to ${isDark ? 'light' : 'dark'} mode`}
    >
      {isDark ? <Sun aria-hidden="true" /> : <Moon aria-hidden="true" />}
    </Button>
  );
}
