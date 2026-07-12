'use client';

import { useState } from 'react';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from '@/components/ui/select';
import { useUpdateSalonStatus } from '@/lib/hooks/use-admin';
import { TenantStatus, type Salon } from '@/types/admin';

const STATUS_OPTIONS: { value: TenantStatus; label: string }[] = [
  { value: TenantStatus.PENDING_APPROVAL, label: 'Pending approval' },
  { value: TenantStatus.APPROVED, label: 'Approved' },
  { value: TenantStatus.SUSPENDED, label: 'Suspended' },
  { value: TenantStatus.REJECTED, label: 'Rejected' },
];

export function SalonStatusDialog({
  salon,
  open,
  onOpenChange,
}: {
  salon: Salon;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const [status, setStatus] = useState<TenantStatus>(salon.status as TenantStatus);
  const mutation = useUpdateSalonStatus();

  function handleSave() {
    mutation.mutate(
      { id: salon.id, status, isActive: status === TenantStatus.APPROVED },
      {
        onSuccess: () => {
          toast.success(`${salon.name} is now ${status.toLowerCase().replace('_', ' ')}`);
          onOpenChange(false);
        },
        onError: (err) => toast.error(err instanceof Error ? err.message : 'Failed to update status'),
      },
    );
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Update salon status</DialogTitle>
          <DialogDescription>{salon.name}</DialogDescription>
        </DialogHeader>

        <Select value={status} onValueChange={(v) => setStatus(v as TenantStatus)}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {STATUS_OPTIONS.map((opt) => (
              <SelectItem key={opt.value} value={opt.value}>
                {opt.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={mutation.isPending}>
            {mutation.isPending ? 'Saving…' : 'Save'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
