import { Badge, type BadgeProps } from '@/components/ui/badge';
import { BookingStatus } from '@/types/admin';

const STATUS_VARIANT: Record<BookingStatus, BadgeProps['variant']> = {
  [BookingStatus.PENDING]: 'warning',
  [BookingStatus.CONFIRMED]: 'info',
  [BookingStatus.COMPLETED]: 'success',
  [BookingStatus.CANCELLED]: 'destructive',
  [BookingStatus.NO_SHOW]: 'destructive',
};

export function BookingStatusBadge({ status }: { status: BookingStatus }) {
  return <Badge variant={STATUS_VARIANT[status]}>{status.replace('_', ' ').toLowerCase()}</Badge>;
}
