'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import type { AdminBooking, PlatformUser, RevenueStats, Salon, TenantStatus, UserRole } from '@/types/admin';

export function useSalons() {
  return useQuery({
    queryKey: ['admin', 'salons'],
    queryFn: () => apiClient<Salon[]>('/api/admin/salons'),
  });
}

export function useUpdateSalonStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status, isActive }: { id: string; status: TenantStatus; isActive: boolean }) =>
      apiClient<Salon>(`/api/admin/salons/${id}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status, isActive }),
      }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'salons'] }),
  });
}

export function useUpdateSalonCommission() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, commissionPct }: { id: string; commissionPct: number }) =>
      apiClient<Salon>(`/api/admin/salons/${id}/commission`, {
        method: 'PATCH',
        body: JSON.stringify({ commissionPct }),
      }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'salons'] }),
  });
}

export function useUsers(role?: UserRole) {
  return useQuery({
    queryKey: ['admin', 'users', role ?? 'all'],
    queryFn: () => apiClient<PlatformUser[]>(`/api/admin/users${role ? `?role=${role}` : ''}`),
  });
}

export function useBookings() {
  return useQuery({
    queryKey: ['admin', 'bookings'],
    queryFn: () => apiClient<AdminBooking[]>('/api/admin/bookings'),
  });
}

export function useRevenue() {
  return useQuery({
    queryKey: ['admin', 'revenue'],
    queryFn: () => apiClient<RevenueStats>('/api/admin/revenue'),
  });
}

export function useSetGlobalCommission() {
  return useMutation({
    mutationFn: (commissionPct: number) =>
      apiClient('/api/admin/settings/commission', {
        method: 'POST',
        body: JSON.stringify({ commissionPct }),
      }),
  });
}
