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
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Trash2 } from 'lucide-react';
import { SalonStatusBadge } from './status-badge';
import { SalonStatusDialog } from './salon-status-dialog';
import { SalonCommissionDialog } from './salon-commission-dialog';
import { SalonDetailDialog } from './salon-detail-dialog';
import { useSalons, useDeleteSalon } from '@/lib/hooks/use-admin';
import { formatDate } from '@/lib/utils';
import type { Salon } from '@/types/admin';

export function SalonsTable() {
  const { data, isLoading, isError } = useSalons();
  const [search, setSearch] = useState('');
  const [statusTarget, setStatusTarget] = useState<Salon | null>(null);
  const [commissionTarget, setCommissionTarget] = useState<Salon | null>(null);
  const [detailTarget, setDetailTarget] = useState<Salon | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Salon | null>(null);
  const deleteMutation = useDeleteSalon();

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
        id: 'onboarding',
        header: 'Onboarding',
        cell: ({ row }) => {
          const step = row.original.onboardingStep;
          const kyc = row.original.kycStatus;
          return (
            <div className="text-xs">
              <div className="text-slate-700 dark:text-slate-300">{step || '—'}</div>
              {kyc && <div className={`${kyc === 'APPROVED' ? 'text-green-600' : kyc === 'REJECTED' ? 'text-red-600' : 'text-yellow-600'}`}>{kyc}</div>}
            </div>
          );
        },
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
            <Button variant="outline" size="sm" onClick={() => setDetailTarget(row.original)}>
              Review
            </Button>
            <Button variant="outline" size="sm" onClick={() => setCommissionTarget(row.original)}>
              Commission
            </Button>
            <Button variant="outline" size="sm" onClick={() => setStatusTarget(row.original)}>
              Status
            </Button>
            <Button variant="outline" size="sm" className="text-red-500 hover:text-red-600 border-red-200 hover:bg-red-50" onClick={() => setDeleteTarget(row.original)}>
              <Trash2 className="size-4" />
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
      {detailTarget && (
        <SalonDetailDialog
          salon={detailTarget}
          open={!!detailTarget}
          onOpenChange={(o) => !o && setDetailTarget(null)}
        />
      )}

      {deleteTarget && (
        <Dialog open={!!deleteTarget} onOpenChange={(o) => !o && setDeleteTarget(null)}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="text-red-600">Hard Delete Salon</DialogTitle>
              <DialogDescription>
                Are you absolutely sure you want to delete <strong>{deleteTarget.name}</strong>?
                This action cannot be undone. It will permanently delete this tenant, all their bookings, users, and data.
              </DialogDescription>
            </DialogHeader>
            <DialogFooter>
              <Button variant="outline" onClick={() => setDeleteTarget(null)} disabled={deleteMutation.isPending}>
                Cancel
              </Button>
              <Button
                variant="destructive"
                onClick={() => {
                  deleteMutation.mutate(deleteTarget.id, {
                    onSuccess: () => setDeleteTarget(null),
                  });
                }}
                disabled={deleteMutation.isPending}
              >
                {deleteMutation.isPending ? 'Deleting...' : 'Yes, delete everything'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
}
