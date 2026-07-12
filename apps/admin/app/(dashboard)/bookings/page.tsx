import { BookingsTable } from '@/components/bookings/bookings-table';

export default function BookingsPage() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-50">Bookings</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">Cross-tenant view of every appointment on the platform.</p>
      </div>
      <BookingsTable />
    </div>
  );
}
