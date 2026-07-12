'use client';

import { useState } from 'react';
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from '@/components/ui/select';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell, TableEmpty } from '@/components/ui/table';
import { Skeleton } from '@/components/ui/skeleton';
import { RoleBadge } from './role-badge';
import { UserStatusBadge } from './user-status-badge';
import { useUsers } from '@/lib/hooks/use-admin';
import { formatDate } from '@/lib/utils';
import { UserRole } from '@/types/admin';

const ROLE_FILTERS: { value: UserRole | 'ALL'; label: string }[] = [
  { value: 'ALL', label: 'All roles' },
  { value: UserRole.SUPER_ADMIN, label: 'Super admin' },
  { value: UserRole.SALON_OWNER, label: 'Salon owner' },
  { value: UserRole.STAFF, label: 'Staff' },
  { value: UserRole.CUSTOMER, label: 'Customer' },
];

export function UsersTable() {
  const [roleFilter, setRoleFilter] = useState<UserRole | 'ALL'>('ALL');
  const { data, isLoading, isError } = useUsers(roleFilter === 'ALL' ? undefined : roleFilter);

  return (
    <div className="flex flex-col gap-3">
      <Select value={roleFilter} onValueChange={(v) => setRoleFilter(v as UserRole | 'ALL')}>
        <SelectTrigger className="max-w-xs">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {ROLE_FILTERS.map((f) => (
            <SelectItem key={f.value} value={f.value}>
              {f.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      {isLoading && (
        <div className="flex flex-col gap-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-12 w-full" />
          ))}
        </div>
      )}

      {isError && <p className="text-sm text-red-600">Failed to load users.</p>}

      {data && (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Contact</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Joined</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.length === 0 && <TableEmpty colSpan={5}>No users found.</TableEmpty>}
            {data.map((user) => (
              <TableRow key={user.id}>
                <TableCell className="font-medium text-slate-900 dark:text-slate-100">
                  {user.fullName ?? '—'}
                </TableCell>
                <TableCell>{user.email ?? user.phone ?? '—'}</TableCell>
                <TableCell>
                  <RoleBadge role={user.role} />
                </TableCell>
                <TableCell>
                  <UserStatusBadge status={user.status} />
                </TableCell>
                <TableCell>{formatDate(user.createdAt)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}
