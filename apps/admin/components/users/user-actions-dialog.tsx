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
import { useUpdateUserStatus, useUpdateUserRole, useDeleteUser } from '@/lib/hooks/use-admin';
import { UserRole, UserStatus, type PlatformUser } from '@/types/admin';
import { formatDate } from '@/lib/utils';

export function UserActionsDialog({
  user,
  open,
  onOpenChange,
}: {
  user: PlatformUser;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const [role, setRole] = useState<UserRole>(user.role);
  const [status, setStatus] = useState<UserStatus>(user.status);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [loading, setLoading] = useState(false);

  const updateStatus = useUpdateUserStatus();
  const updateRole = useUpdateUserRole();
  const deleteUser = useDeleteUser();

  async function handleSave() {
    setLoading(true);
    try {
      if (status !== user.status) {
        await updateStatus.mutateAsync({ id: user.id, status });
      }
      if (role !== user.role) {
        await updateRole.mutateAsync({ id: user.id, role });
      }
      toast.success('User updated successfully');
      onOpenChange(false);
    } catch (err: any) {
      toast.error(err?.message || 'Failed to update user');
    } finally {
      setLoading(false);
    }
  }

  async function handleDelete() {
    setLoading(true);
    try {
      await deleteUser.mutateAsync(user.id);
      toast.success('User purged from database');
      onOpenChange(false);
    } catch (err: any) {
      toast.error(err?.message || 'Failed to delete user');
    } finally {
      setLoading(false);
      setShowDeleteConfirm(false);
    }
  }

  return (
    <>
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>User Profile & Actions</DialogTitle>
            <DialogDescription>
              View profile details and modify permissions or delete this user.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2">
            {/* Profile Info */}
            <div className="grid grid-cols-2 gap-2 text-sm border-b pb-4">
              <div>
                <span className="text-slate-500 block text-xs">Full Name</span>
                <span className="font-semibold text-slate-800 dark:text-slate-200">
                  {user.fullName ?? '—'}
                </span>
              </div>
              <div>
                <span className="text-slate-500 block text-xs">Contact</span>
                <span className="font-semibold text-slate-800 dark:text-slate-200">
                  {user.email ?? user.phone ?? '—'}
                </span>
              </div>
              <div className="col-span-2 mt-1">
                <span className="text-slate-500 block text-xs">User ID</span>
                <span className="font-mono text-xs break-all text-slate-600 dark:text-slate-400">
                  {user.id}
                </span>
              </div>
              <div className="mt-1">
                <span className="text-slate-500 block text-xs">Joined Date</span>
                <span className="text-slate-800 dark:text-slate-200">
                  {formatDate(user.createdAt)}
                </span>
              </div>
              {user.tenantId && (
                <div className="mt-1">
                  <span className="text-slate-500 block text-xs">Salon ID</span>
                  <span className="font-mono text-xs break-all text-slate-600 dark:text-slate-400">
                    {user.tenantId}
                  </span>
                </div>
              )}
            </div>

            {/* Change Role */}
            <div className="space-y-1.5">
              <label className="text-xs font-medium text-slate-600 dark:text-slate-400">
                User Role / Access Level
              </label>
              <Select value={role} onValueChange={(v) => setRole(v as UserRole)}>
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={UserRole.SUPER_ADMIN}>Super Admin</SelectItem>
                  <SelectItem value={UserRole.SALON_OWNER}>Salon Owner</SelectItem>
                  <SelectItem value={UserRole.STAFF}>Staff</SelectItem>
                  <SelectItem value={UserRole.CUSTOMER}>Customer</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Change Status */}
            <div className="space-y-1.5">
              <label className="text-xs font-medium text-slate-600 dark:text-slate-400">
                Account Status (Block/Suspend)
              </label>
              <Select value={status} onValueChange={(v) => setStatus(v as UserStatus)}>
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={UserStatus.ACTIVE}>Active</SelectItem>
                  <SelectItem value={UserStatus.INACTIVE}>Inactive</SelectItem>
                  <SelectItem value={UserStatus.SUSPENDED}>Suspended / Blocked</SelectItem>
                  <SelectItem value={UserStatus.PENDING_VERIFICATION}>Pending Verification</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <DialogFooter className="flex justify-between items-center sm:justify-between border-t pt-4">
            <Button
              variant="destructive"
              size="sm"
              onClick={() => setShowDeleteConfirm(true)}
              disabled={loading}
            >
              Hard Delete User
            </Button>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" onClick={() => onOpenChange(false)} disabled={loading}>
                Cancel
              </Button>
              <Button size="sm" onClick={handleSave} disabled={loading}>
                {loading ? 'Saving...' : 'Save Changes'}
              </Button>
            </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={showDeleteConfirm} onOpenChange={setShowDeleteConfirm}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="text-red-600">Confirm Hard Delete</DialogTitle>
            <DialogDescription>
              Are you absolutely sure you want to permanently delete **{user.fullName || 'this user'}**?
              <br />
              <span className="text-red-500 font-bold block mt-2 text-xs">
                ⚠️ WARNING: This action will permanently purge their profile, sessions, reviews, and staff schedules directly from the database. This cannot be undone!
              </span>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="gap-2 sm:gap-0 sm:flex-row justify-end">
            <Button variant="outline" onClick={() => setShowDeleteConfirm(false)} disabled={loading}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete} disabled={loading}>
              {loading ? 'Purging...' : 'Purge from DB'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
