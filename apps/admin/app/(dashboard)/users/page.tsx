import { UsersTable } from '@/components/users/users-table';

export default function UsersPage() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-50">Users</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">All registered platform users, across every salon.</p>
      </div>
      <UsersTable />
    </div>
  );
}
