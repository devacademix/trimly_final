'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { toast } from 'sonner';

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from '@/components/ui/select';
import { useCreatePlan, useUpdatePlan } from '@/lib/hooks/use-admin';

const planSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  description: z.string().optional(),
  price: z.coerce.number().min(0, 'Price must be non-negative'),
  billingPeriod: z.enum(['MONTHLY', 'YEARLY']),
  branchLimit: z.coerce.number().min(1, 'At least 1 branch'),
  staffLimit: z.coerce.number().min(1, 'At least 1 staff'),
  bookingLimit: z.coerce.number().min(1, 'At least 1 booking'),
  storageLimitMb: z.coerce.number().min(100, 'At least 100MB'),
  isActive: z.boolean(),
});

type PlanFormValues = z.infer<typeof planSchema>;

interface PlanDialogProps {
  plan: any | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function PlanDialog({ plan, open, onOpenChange }: PlanDialogProps) {
  const createPlan = useCreatePlan();
  const updatePlan = useUpdatePlan();

  const { register, handleSubmit, reset, setValue, formState: { errors } } = useForm<PlanFormValues>({
    resolver: zodResolver(planSchema),
    defaultValues: {
      name: '',
      description: '',
      price: 0,
      billingPeriod: 'MONTHLY',
      branchLimit: 1,
      staffLimit: 5,
      bookingLimit: 100,
      storageLimitMb: 500,
      isActive: true,
    }
  });

  useEffect(() => {
    if (plan && open) {
      reset({
        name: plan.name,
        description: plan.description || '',
        price: Number(plan.price),
        billingPeriod: plan.billingPeriod as any,
        branchLimit: plan.branchLimit,
        staffLimit: plan.staffLimit,
        bookingLimit: plan.bookingLimit,
        storageLimitMb: plan.storageLimitMb,
        isActive: plan.isActive,
      });
    } else if (!plan && open) {
      reset({
        name: '',
        description: '',
        price: 0,
        billingPeriod: 'MONTHLY',
        branchLimit: 1,
        staffLimit: 5,
        bookingLimit: 100,
        storageLimitMb: 500,
        isActive: true,
      });
    }
  }, [plan, open, reset]);

  const onSubmit = async (data: PlanFormValues) => {
    try {
      if (plan) {
        await updatePlan.mutateAsync({ id: plan.id, data });
        toast.success('Plan updated successfully');
      } else {
        await createPlan.mutateAsync(data);
        toast.success('Plan created successfully');
      }
      onOpenChange(false);
    } catch (error: any) {
      toast.error(error.message || 'Failed to save plan');
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>{plan ? 'Edit Plan' : 'Create New Plan'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="name">Name</Label>
              <Input id="name" {...register('name')} />
              {errors.name && <p className="text-xs text-red-500">{errors.name.message}</p>}
            </div>
            <div className="space-y-2">
              <Label htmlFor="price">Price (₹)</Label>
              <Input id="price" type="number" step="0.01" {...register('price')} />
              {errors.price && <p className="text-xs text-red-500">{errors.price.message}</p>}
            </div>
            <div className="space-y-2">
              <Label htmlFor="billingPeriod">Billing Period</Label>
              <Select defaultValue={plan?.billingPeriod || 'MONTHLY'} onValueChange={(v) => setValue('billingPeriod', v as any)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="MONTHLY">Monthly</SelectItem>
                  <SelectItem value="YEARLY">Yearly</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2 flex items-center justify-between mt-6 border p-2 rounded">
              <Label htmlFor="isActive" className="cursor-pointer">Is Active</Label>
              <input type="checkbox" id="isActive" {...register('isActive')} className="h-4 w-4" />
            </div>
            <div className="space-y-2 col-span-2">
              <Label htmlFor="description">Description</Label>
              <Input id="description" {...register('description')} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="branchLimit">Branch Limit</Label>
              <Input id="branchLimit" type="number" {...register('branchLimit')} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="staffLimit">Staff Limit</Label>
              <Input id="staffLimit" type="number" {...register('staffLimit')} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="bookingLimit">Booking Limit (per month)</Label>
              <Input id="bookingLimit" type="number" {...register('bookingLimit')} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="storageLimitMb">Storage Limit (MB)</Label>
              <Input id="storageLimitMb" type="number" {...register('storageLimitMb')} />
            </div>
          </div>
          <div className="flex justify-end gap-3 mt-4">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={createPlan.isPending || updatePlan.isPending}>
              {plan ? 'Save Changes' : 'Create Plan'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
