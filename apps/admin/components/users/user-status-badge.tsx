import { Badge, type BadgeProps } from '@/components/ui/badge';
import { UserStatus } from '@/types/admin';

const STATUS_VARIANT: Record<UserStatus, BadgeProps['variant']> = {
  [UserStatus.ACTIVE]: 'success',
  [UserStatus.INACTIVE]: 'default',
  [UserStatus.SUSPENDED]: 'destructive',
  [UserStatus.PENDING_VERIFICATION]: 'warning',
};

export function UserStatusBadge({ status }: { status: UserStatus }) {
  return <Badge variant={STATUS_VARIANT[status]}>{status.replace('_', ' ').toLowerCase()}</Badge>;
}
