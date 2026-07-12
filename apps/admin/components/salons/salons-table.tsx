'use client';

import { useMemo, useState } from 'react';
import {
  type ColumnDef,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  useReactTable,
} from '@tanstack/react-table';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell, TableEmpty } from '@/components/ui/table';
import { Skeleton } from '@/components/ui/skeleton';
import { SalonStatusBadge } from './status-badge';
import { SalonStatusDialog } from './salon-status-dialog';
import { SalonCommissionDialog } from './salon-commission-dialog';
import { useSalons } from '@/lib/hooks/use-admin';
import { formatDate } from '@/lib/utils';
import type { Salon } from '@/types/admin';

export function SalonsTable() {
  const { data, isLoading, isError } = useSalons();
  const [search, setSearch] = useState('');
  const [statusTarget, setStatusTarget] = useState<Salon | null>(null);
  const [commissionTarget, setCommissionTarget] = useState<Salon | null>(null);

  const columns = useMemo<ColumnDef<Salon>[]>(
    () => [
      {
        accessorKey: 'name',
        header: 'Salon',
        cell: ({ row }) => (
          <div>
            <div className="font-medium text-slate-900 dark:text-slate-100">{row.original.name}</div>
            <div className="text-xs text-slate-500 dark:text-slate-400">{row.original.primaryCity ?? row.original.slug}</div>
          </div>
        ),
      },
      {
        accessorKey: 'status',
        header: 'Status',
        cell: ({ row }) => <SalonStatusBadge status={row.original.status} />,
      },
      {
        accessorKey: 'commissionPct',
        header: 'Commission',
        cell: ({ row }) => (row.original.commissionPct != null ? `${row.original.commissionPct}%` : 'Platform default'),
      },
      {
        id: 'counts',
        header: 'Activity',
        cell: ({ row }) => {
          const c = row.original._count;
          return (
            <span className="text-sm text-slate-500 dark:text-slate-400">
              {c ? `${c.branches} branches · ${c.users} users · ${c.bookings} bookings` : '—'}
            </span>
          );
        },
      },
      {
        accessorKey: 'createdAt',
        header: 'Joined',
        cell: ({ row }) => formatDate(row.original.createdAt),
      },
      {
        id: 'actions',
        header: '',
        cell: ({ row }) => (
          <div className="flex justify-end gap-2">
            <Button variant="outline" size="sm" onClick={() => setCommissionTarget(row.original)}>
              Commission
            </Button>
            <Button variant="outline" size="sm" onClick={() => setStatusTarget(row.original)}>
              Status
            </Button>
          </div>
        ),
      },
    ],
    [],
  );

  const table = useReactTable({
    data: data ?? [],
    columns,
    state: { globalFilter: search },
    onGlobalFilterChange: setSearch,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });

  if (isLoading) {
    return (
      <div className="flex flex-col gap-2">
        {Array.from({ length: 5 }).map((_, i) => (
          <Skeleton key={i} className="h-12 w-full" />
        ))}
      </div>
    );
  }

  if (isError) {
    return <p className="text-sm text-red-600">Failed to load salons.</p>;
  }

  return (
    <div className="flex flex-col gap-3">
      <Input
        placeholder="Search salons…"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="max-w-xs"
      />

      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((hg) => (
            <TableRow key={hg.id}>
              {hg.headers.map((header) => (
                <TableHead key={header.id}>
                  {header.isPlaceholder ? null : flexRender(header.column.columnDef.header, header.getContext())}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows.length === 0 && <TableEmpty colSpan={columns.length}>No salons found.</TableEmpty>}
          {table.getRowModel().rows.map((row) => (
            <TableRow key={row.id}>
              {row.getVisibleCells().map((cell) => (
                <TableCell key={cell.id}>{flexRender(cell.column.columnDef.cell, cell.getContext())}</TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {statusTarget && (
        <SalonStatusDialog salon={statusTarget} open={!!statusTarget} onOpenChange={(o) => !o && setStatusTarget(null)} />
      )}
      {commissionTarget && (
        <SalonCommissionDialog
          salon={commissionTarget}
          open={!!commissionTarget}
          onOpenChange={(o) => !o && setCommissionTarget(null)}
        />
      )}
    </div>
  );
}
