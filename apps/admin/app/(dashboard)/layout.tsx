import { redirect } from 'next/navigation';
import { backendFetch, BackendError } from '@/lib/backend';
import { Sidebar } from '@/components/layout/sidebar';
import { Topbar } from '@/components/layout/topbar';
import type { AdminUser } from '@/types/admin';
import { UserRole } from '@/types/admin';

async function getCurrentUser(): Promise<AdminUser | null> {
  try {
    return await backendFetch<AdminUser>('/auth/me');
  } catch (err) {
    if (err instanceof BackendError && err.status === 401) {
      return null;
    }
    throw err;
  }
}

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();

  // proxy.ts already redirects unauthenticated/non-admin requests before
  // this ever renders — this is the real authorization check (the backend
  // itself has already validated the token and role by the time
  // getCurrentUser() succeeds), proxy is just the UX-level fast path.
  if (!user || user.role !== UserRole.SUPER_ADMIN) {
    redirect('/login');
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex flex-1 flex-col">
        <Topbar user={user} />
        <main className="flex-1 p-4 md:p-6">{children}</main>
      </div>
    </div>
  );
}
