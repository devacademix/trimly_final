'use client';

import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell, TableEmpty } from '@/components/ui/table';
import { Skeleton } from '@/components/ui/skeleton';
import { BookingStatusBadge } from './booking-status-badge';
import { useBookings } from '@/lib/hooks/use-admin';
import { formatCurrency, formatDate } from '@/lib/utils';

export function BookingsTable() {
  const { data, isLoading, isError } = useBookings();

  if (isLoading) {
    return (
      <div className="flex flex-col gap-2">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} className="h-12 w-full" />
        ))}
      </div>
    );
  }

  if (isError) {
    return <p className="text-sm text-red-600">Failed to load bookings.</p>;
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Salon</TableHead>
          <TableHead>Customer</TableHead>
          <TableHead>Start time</TableHead>
          <TableHead>Status</TableHead>
          <TableHead>Amount</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {(!data || data.length === 0) && <TableEmpty colSpan={5}>No bookings found.</TableEmpty>}
        {data?.map((booking) => (
          <TableRow key={booking.id}>
            <TableCell className="font-medium text-slate-900 dark:text-slate-100">{booking.tenant.name}</TableCell>
            <TableCell>{booking.customer.fullName ?? booking.customer.email ?? '—'}</TableCell>
            <TableCell>{formatDate(booking.startTime)}</TableCell>
            <TableCell>
              <BookingStatusBadge status={booking.status} />
            </TableCell>
            <TableCell>{formatCurrency(Number(booking.totalPrice))}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
