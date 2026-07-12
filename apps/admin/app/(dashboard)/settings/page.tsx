'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { useSetGlobalCommission } from '@/lib/hooks/use-admin';

const schema = z.object({
  commissionPct: z.coerce.number().min(0, 'Must be 0 or higher').max(100, 'Must be 100 or lower'),
});
type FormValues = z.infer<typeof schema>;

export default function SettingsPage() {
  const mutation = useSetGlobalCommission();
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: { commissionPct: 15 } });

  function onSubmit(values: FormValues) {
    mutation.mutate(values.commissionPct, {
      onSuccess: () => toast.success(`Default platform commission set to ${values.commissionPct}%`),
      onError: (err) => toast.error(err instanceof Error ? err.message : 'Failed to update setting'),
    });
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-50">Settings</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">Platform-wide defaults.</p>
      </div>

      <Card className="max-w-md">
        <CardHeader>
          <CardTitle>Default commission</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="mb-4 text-sm text-slate-500 dark:text-slate-400">
            Applied to any salon that doesn&apos;t have a per-salon commission override set on the Salons page.
          </p>
          <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="commissionPct">Commission percentage</Label>
              <Input id="commissionPct" type="number" step="0.1" min={0} max={100} {...register('commissionPct')} />
              {errors.commissionPct && <p className="text-xs text-red-600">{errors.commissionPct.message}</p>}
            </div>
            <Button type="submit" disabled={mutation.isPending} className="self-start">
              {mutation.isPending ? 'Saving…' : 'Save'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
