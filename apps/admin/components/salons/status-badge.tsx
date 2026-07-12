import { Badge, type BadgeProps } from '@/components/ui/badge';

const STATUS_VARIANT: Record<string, BadgeProps['variant']> = {
  PENDING_APPROVAL: 'warning',
  APPROVED: 'success',
  SUSPENDED: 'destructive',
  REJECTED: 'destructive',
};

const STATUS_LABEL: Record<string, string> = {
  PENDING_APPROVAL: 'Pending approval',
  APPROVED: 'Approved',
  SUSPENDED: 'Suspended',
  REJECTED: 'Rejected',
};

export function SalonStatusBadge({ status }: { status: string }) {
  return <Badge variant={STATUS_VARIANT[status] ?? 'default'}>{STATUS_LABEL[status] ?? status}</Badge>;
}
