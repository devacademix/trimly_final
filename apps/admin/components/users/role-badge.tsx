import { Badge, type BadgeProps } from '@/components/ui/badge';
import { UserRole } from '@/types/admin';

const ROLE_VARIANT: Record<UserRole, BadgeProps['variant']> = {
  [UserRole.SUPER_ADMIN]: 'info',
  [UserRole.SALON_OWNER]: 'success',
  [UserRole.STAFF]: 'default',
  [UserRole.CUSTOMER]: 'outline',
};

const ROLE_LABEL: Record<UserRole, string> = {
  [UserRole.SUPER_ADMIN]: 'Super admin',
  [UserRole.SALON_OWNER]: 'Salon owner',
  [UserRole.STAFF]: 'Staff',
  [UserRole.CUSTOMER]: 'Customer',
};

export function RoleBadge({ role }: { role: UserRole }) {
  return <Badge variant={ROLE_VARIANT[role]}>{ROLE_LABEL[role]}</Badge>;
}
