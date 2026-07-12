import { SalonsTable } from '@/components/salons/salons-table';

export default function SalonsPage() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-50">Salons</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          Approve, suspend, and set commission overrides for tenants on the platform.
        </p>
      </div>
      <SalonsTable />
    </div>
  );
}
