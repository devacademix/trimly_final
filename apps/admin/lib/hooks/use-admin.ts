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

export function usePlans() {
  return useQuery({
    queryKey: ['admin', 'plans'],
    queryFn: () => apiClient<any[]>('/api/admin/plans'),
  });
}

export function useCreatePlan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) =>
      apiClient<any>('/api/admin/plans', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'plans'] }),
  });
}

export function useUpdatePlan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) =>
      apiClient<any>(`/api/admin/plans/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'plans'] }),
  });
}

export function useDeleteSalon() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) =>
      apiClient<any>(`/api/admin/salons/${id}`, {
        method: 'DELETE',
      }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'salons'] }),
  });
}

export function useUpdateUserStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      apiClient<any>(`/api/admin/users/${id}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      }),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
    },
  });
}

export function useUpdateUserRole() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, role }: { id: string; role: string }) =>
      apiClient<any>(`/api/admin/users/${id}/role`, {
        method: 'PATCH',
        body: JSON.stringify({ role }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
    },
  });
}

export function useDeleteUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) =>
      apiClient<any>(`/api/admin/users/${id}`, {
        method: 'DELETE',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
    },
  });
}

