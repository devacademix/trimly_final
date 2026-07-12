'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { LogOut } from 'lucide-react';
import { Button } from '@/components/ui/button';
import type { AdminUser } from '@/types/admin';

export function Topbar({ user }: { user: AdminUser | null }) {
  const router = useRouter();
  const [loggingOut, setLoggingOut] = useState(false);

  async function handleLogout() {
    setLoggingOut(true);
    await fetch('/api/auth/logout', { method: 'POST' });
    router.replace('/login');
    router.refresh();
  }

  return (
    <header className="flex h-14 items-center justify-between border-b border-slate-200 bg-white px-4 dark:border-slate-800 dark:bg-slate-900 md:px-6">
      <div className="md:hidden text-sm font-semibold text-slate-900 dark:text-slate-50">Trimly Admin</div>
      <div className="ml-auto flex items-center gap-3">
        {user && (
          <span className="hidden text-sm text-slate-600 dark:text-slate-400 sm:inline">
            {user.fullName ?? user.email}
          </span>
        )}
        <Button variant="ghost" size="sm" onClick={handleLogout} disabled={loggingOut}>
          <LogOut className="size-4" />
          {loggingOut ? 'Signing out…' : 'Sign out'}
        </Button>
      </div>
    </header>
  );
}
