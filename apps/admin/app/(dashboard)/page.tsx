'use client';

import { useRevenue } from '@/lib/hooks/use-admin';
import { StatCard } from '@/components/dashboard/stat-card';
import { RevenueSplitBar } from '@/components/dashboard/revenue-split-bar';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { formatCurrency } from '@/lib/utils';

export default function DashboardPage() {
  const { data: revenue, isLoading, isError } = useRevenue();

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-50">Dashboard</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">Platform-wide revenue and activity overview.</p>
      </div>

      {isLoading && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-24 w-full" />
          ))}
        </div>
      )}

      {isError && (
        <Card>
          <CardContent className="pt-6 text-sm text-red-600">Failed to load revenue statistics.</CardContent>
        </Card>
      )}

      {revenue && (
        <>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatCard label="Total captured volume" value={formatCurrency(revenue.totalVolume)} />
            <StatCard label="Platform commission" value={formatCurrency(revenue.totalPlatformCommission)} />
            <StatCard label="Salon revenue" value={formatCurrency(revenue.totalSalonRevenue)} />
            <StatCard label="Active salons" value={`${revenue.salonCount} · ${revenue.bookingCount} bookings`} />
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Revenue split</CardTitle>
            </CardHeader>
            <CardContent>
              <RevenueSplitBar
                salonRevenue={revenue.totalSalonRevenue}
                platformCommission={revenue.totalPlatformCommission}
              />
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
