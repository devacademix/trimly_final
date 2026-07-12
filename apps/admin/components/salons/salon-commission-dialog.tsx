'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useUpdateSalonCommission } from '@/lib/hooks/use-admin';
import type { Salon } from '@/types/admin';

const schema = z.object({
  commissionPct: z.coerce.number().min(0, 'Must be 0 or higher').max(100, 'Must be 100 or lower'),
});
type FormValues = z.infer<typeof schema>;

export function SalonCommissionDialog({
  salon,
  open,
  onOpenChange,
}: {
  salon: Salon;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const mutation = useUpdateSalonCommission();
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    values: { commissionPct: salon.commissionPct ? Number(salon.commissionPct) : 15 },
  });

  function onSubmit(values: FormValues) {
    mutation.mutate(
      { id: salon.id, commissionPct: values.commissionPct },
      {
        onSuccess: () => {
          toast.success(`Commission for ${salon.name} set to ${values.commissionPct}%`);
          onOpenChange(false);
        },
        onError: (err) => toast.error(err instanceof Error ? err.message : 'Failed to update commission'),
      },
    );
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Commission override</DialogTitle>
          <DialogDescription>{salon.name}</DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="commissionPct">Commission percentage</Label>
            <Input
              id="commissionPct"
              type="number"
              step="0.1"
              min={0}
              max={100}
              {...register('commissionPct')}
            />
            {errors.commissionPct && <p className="text-xs text-red-600">{errors.commissionPct.message}</p>}
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={mutation.isPending}>
              {mutation.isPending ? 'Saving…' : 'Save'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
