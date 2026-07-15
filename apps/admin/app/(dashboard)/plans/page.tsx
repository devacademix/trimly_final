import { PlansTable } from '@/components/plans/plans-table';

export default function PlansPage() {
  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-50">Subscription Plans</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">Manage SaaS plans, pricing, and limits.</p>
        </div>
      </div>
      <PlansTable />
    </div>
  );
}
