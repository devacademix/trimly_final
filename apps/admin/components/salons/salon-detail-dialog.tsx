'use client';

import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useUpdateSalonStatus, useDeleteSalon } from '@/lib/hooks/use-admin';
import type { Salon, TenantStatus } from '@/types/admin';
import { toast } from 'sonner';

interface Props {
  salon: Salon | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const statusColors: Record<string, string> = {
  PENDING_APPROVAL: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
  APPROVED: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  SUSPENDED: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
  REJECTED: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
};

const stepLabels: Record<string, string> = {
  WELCOME: 'Welcome',
  MOBILE_VERIFICATION: 'Mobile Verified',
  BASIC_INFO: 'Basic Info',
  LOCATION: 'Location',
  DETAILS: 'Business Details',
  TIMING: 'Business Hours',
  PHOTOS: 'Photos',
  SERVICES: 'Services',
  STAFF: 'Staff',
  BANK: 'Bank Details',
  KYC: 'KYC Submitted',
  SUBSCRIPTION: 'Subscription',
  TOUR: 'Tour',
  COMPLETED: 'Completed',
};

export function SalonDetailDialog({ salon, open, onOpenChange }: Props) {
  const updateStatus = useUpdateSalonStatus();
  const deleteSalon = useDeleteSalon();
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'details' | 'services' | 'staff' | 'timing'>('details');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  if (!salon) return null;

  const handleStatus = async (status: TenantStatus, isActive: boolean) => {
    setActionLoading(status);
    try {
      await updateStatus.mutateAsync({ id: salon.id, status, isActive });
      toast.success(`Salon is now ${status.toLowerCase()}`);
      onOpenChange(false);
    } catch (e: any) {
      toast.error(e?.message || 'Failed to update status');
    } finally {
      setActionLoading(null);
    }
  };

  const handleDelete = async () => {
    setActionLoading('delete');
    try {
      await deleteSalon.mutateAsync(salon.id);
      toast.success('Salon fully purged from database');
      onOpenChange(false);
    } catch (e: any) {
      toast.error(e?.message || 'Failed to hard-delete salon');
    } finally {
      setActionLoading(null);
      setShowDeleteConfirm(false);
    }
  };

  // Find staff users (users with staff profile)
  const staffMembers = salon.users?.filter(u => u.staffProfile || u.role === 'STAFF') || [];

  return (
    <>
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          {/* Header cover image */}
          <div className="relative h-32 w-full rounded-t-lg bg-slate-900 overflow-hidden -mx-6 -mt-6 mb-4">
            {salon.coverImageUrl ? (
              <img src={salon.coverImageUrl} className="h-full w-full object-cover opacity-80" alt="Cover" />
            ) : (
              <div className="h-full w-full bg-slate-800 flex items-center justify-center text-slate-500 font-bold text-lg">
                Trimly Salon Profile
              </div>
            )}
            {/* Logo overlay */}
            <div className="absolute bottom-2 left-4 flex items-center gap-3">
              <div className="h-16 w-16 rounded-full border-2 border-white bg-white overflow-hidden shadow-md">
                {salon.logoUrl ? (
                  <img src={salon.logoUrl} className="h-full w-full object-cover" alt="Logo" />
                ) : (
                  <div className="h-full w-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-lg">
                    {salon.name[0]}
                  </div>
                )}
              </div>
              <div className="text-white drop-shadow-md">
                <h3 className="font-bold text-lg">{salon.name}</h3>
                <p className="text-xs text-slate-200">{salon.primaryCity}, {salon.country || salon.primaryCountry}</p>
              </div>
            </div>
          </div>

          <DialogHeader className="pt-2">
            <DialogDescription className="flex items-center justify-between text-xs">
              <span className="inline-flex items-center gap-1.5">
                Onboarding: <Badge variant="outline" className="font-semibold">{stepLabels[salon.onboardingStep ?? 'WELCOME'] || salon.onboardingStep}</Badge>
              </span>
              <span>Joined: {new Date(salon.createdAt).toLocaleDateString()}</span>
            </DialogDescription>
          </DialogHeader>

          {/* Simple state tabs */}
          <div className="flex border-b mb-4">
            <button
              className={`px-4 py-2 text-sm font-medium border-b-2 transition-all ${
                activeTab === 'details'
                  ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400'
                  : 'border-transparent text-slate-500 hover:text-slate-700'
              }`}
              onClick={() => setActiveTab('details')}
            >
              Overview & KYC
            </button>
            <button
              className={`px-4 py-2 text-sm font-medium border-b-2 transition-all ${
                activeTab === 'services'
                  ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400'
                  : 'border-transparent text-slate-500 hover:text-slate-700'
              }`}
              onClick={() => setActiveTab('services')}
            >
              Services ({salon.services?.length || 0})
            </button>
            <button
              className={`px-4 py-2 text-sm font-medium border-b-2 transition-all ${
                activeTab === 'staff'
                  ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400'
                  : 'border-transparent text-slate-500 hover:text-slate-700'
              }`}
              onClick={() => setActiveTab('staff')}
            >
              Staff ({staffMembers.length})
            </button>
            <button
              className={`px-4 py-2 text-sm font-medium border-b-2 transition-all ${
                activeTab === 'timing'
                  ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400'
                  : 'border-transparent text-slate-500 hover:text-slate-700'
              }`}
              onClick={() => setActiveTab('timing')}
            >
              Branches & Hours
            </button>
          </div>

          <div className="space-y-4">
            {/* 1. DETAILS TAB */}
            {activeTab === 'details' && (
              <div className="grid grid-cols-2 gap-4">
                <Card>
                  <CardHeader className="pb-2"><CardTitle className="text-xs text-slate-500">Status Info</CardTitle></CardHeader>
                  <CardContent className="space-y-2">
                    <div>
                      <span className="text-xs text-slate-400 block">Salon Status</span>
                      <Badge className={statusColors[salon.status] || ''}>{salon.status}</Badge>
                    </div>
                    {salon.kycStatus && (
                      <div>
                        <span className="text-xs text-slate-400 block">KYC Status</span>
                        <Badge variant="outline">{salon.kycStatus}</Badge>
                      </div>
                    )}
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="pb-2"><CardTitle className="text-xs text-slate-500">Contact Details</CardTitle></CardHeader>
                  <CardContent className="text-sm space-y-1">
                    <div><span className="text-slate-400">Email:</span> {salon.ownerEmail || '—'}</div>
                    <div><span className="text-slate-400">Phone:</span> {salon.ownerPhone || '—'}</div>
                    {salon.websiteUrl && <div><span className="text-slate-400">Website:</span> <a href={salon.websiteUrl} target="_blank" rel="noopener noreferrer" className="text-indigo-600 underline">{salon.websiteUrl}</a></div>}
                  </CardContent>
                </Card>

                <Card className="col-span-2">
                  <CardHeader className="pb-2"><CardTitle className="text-xs text-slate-500">Business Registry Info</CardTitle></CardHeader>
                  <CardContent className="text-sm">
                    <div className="grid grid-cols-2 gap-2">
                      <div><span className="text-slate-400">Legal Name:</span> {salon.legalName || '—'}</div>
                      <div><span className="text-slate-400">Business Category:</span> {salon.businessCategory || '—'}</div>
                      <div><span className="text-slate-400">GST Number:</span> {salon.gstNumber || '—'}</div>
                      <div><span className="text-slate-400">PAN Number:</span> {salon.panNumber || '—'}</div>
                      <div><span className="text-slate-400">Business Reg Number:</span> {salon.businessRegNumber || '—'}</div>
                      <div><span className="text-slate-400">Commission split rate:</span> {salon.commissionPct ? `${salon.commissionPct}%` : 'Platform Default'}</div>
                    </div>
                  </CardContent>
                </Card>

                {/* Bank Details */}
                <Card className="col-span-2">
                  <CardHeader className="pb-2"><CardTitle className="text-xs text-slate-500">Settlement Bank Account</CardTitle></CardHeader>
                  <CardContent className="text-sm">
                    {salon.bankDetails ? (
                      <div className="grid grid-cols-2 gap-2">
                        <div><span className="text-slate-400">Account Holder:</span> {salon.bankDetails.accountHolder}</div>
                        <div><span className="text-slate-400">Bank Name:</span> {salon.bankDetails.bankName}</div>
                        <div><span className="text-slate-400">Account Number:</span> {salon.bankDetails.accountNumber}</div>
                        <div><span className="text-slate-400">IFSC Code:</span> {salon.bankDetails.ifsc}</div>
                        {salon.bankDetails.upiId && <div className="col-span-2"><span className="text-slate-400">UPI ID:</span> {salon.bankDetails.upiId}</div>}
                      </div>
                    ) : (
                      <span className="text-slate-400 text-xs">No bank account details filled yet.</span>
                    )}
                  </CardContent>
                </Card>

                {/* KYC Documents */}
                <Card className="col-span-2">
                  <CardHeader className="pb-2"><CardTitle className="text-xs text-slate-500">Uploaded KYC Verification Documents</CardTitle></CardHeader>
                  <CardContent className="text-sm">
                    {salon.kycDocuments && salon.kycDocuments.length > 0 ? (
                      <div className="space-y-2">
                        {salon.kycDocuments.map((doc) => (
                          <div key={doc.id} className="flex items-center justify-between p-2 rounded-lg border">
                            <div>
                              <span className="font-medium text-slate-800 dark:text-slate-200">{doc.documentType}</span>
                              <Badge className="ml-2" variant="outline">{doc.status}</Badge>
                              {doc.remarks && <p className="text-xs text-red-500 mt-1">Remarks: {doc.remarks}</p>}
                            </div>
                            <a href={doc.fileUrl} target="_blank" rel="noopener noreferrer" className="text-indigo-600 hover:underline text-xs font-semibold">
                              View File
                            </a>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <span className="text-slate-400 text-xs">No KYC documents uploaded yet.</span>
                    )}
                  </CardContent>
                </Card>
              </div>
            )}

            {/* 2. SERVICES TAB */}
            {activeTab === 'services' && (
              <Card>
                <CardContent className="pt-4">
                  {salon.services && salon.services.length > 0 ? (
                    <div className="overflow-x-auto">
                      <table className="w-full text-sm text-left text-slate-500 dark:text-slate-400">
                        <thead className="text-xs text-slate-700 uppercase bg-slate-50 dark:bg-slate-800 dark:text-slate-400">
                          <tr>
                            <th className="px-4 py-2">Service Name</th>
                            <th className="px-4 py-2">Category</th>
                            <th className="px-4 py-2">Duration</th>
                            <th className="px-4 py-2">Price (INR)</th>
                          </tr>
                        </thead>
                        <tbody>
                          {salon.services.map((svc) => (
                            <tr key={svc.id} className="border-b dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800">
                              <td className="px-4 py-2 font-medium text-slate-900 dark:text-slate-100">{svc.name}</td>
                              <td className="px-4 py-2">{svc.category?.name || '—'}</td>
                              <td className="px-4 py-2">{svc.duration} mins</td>
                              <td className="px-4 py-2">₹{svc.price}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  ) : (
                    <p className="text-sm text-slate-400 text-center py-4">No services configured yet.</p>
                  )}
                </CardContent>
              </Card>
            )}

            {/* 3. STAFF TAB */}
            {activeTab === 'staff' && (
              <Card>
                <CardContent className="pt-4">
                  {staffMembers.length > 0 ? (
                    <div className="overflow-x-auto">
                      <table className="w-full text-sm text-left text-slate-500 dark:text-slate-400">
                        <thead className="text-xs text-slate-700 uppercase bg-slate-50 dark:bg-slate-800 dark:text-slate-400">
                          <tr>
                            <th className="px-4 py-2">Staff Member</th>
                            <th className="px-4 py-2">Bio</th>
                            <th className="px-4 py-2">Base Salary</th>
                            <th className="px-4 py-2">Commission Rate</th>
                          </tr>
                        </thead>
                        <tbody>
                          {staffMembers.map((u) => (
                            <tr key={u.id} className="border-b dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800">
                              <td className="px-4 py-2 font-medium text-slate-900 dark:text-slate-100">
                                <div>{u.fullName}</div>
                                <div className="text-xs text-slate-400">{u.email || u.phone}</div>
                              </td>
                              <td className="px-4 py-2 text-xs truncate max-w-[150px]">{u.staffProfile?.bio || '—'}</td>
                              <td className="px-4 py-2">₹{u.staffProfile?.baseSalary || '0.00'}</td>
                              <td className="px-4 py-2">{u.staffProfile?.commissionRate || '0'}%</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  ) : (
                    <p className="text-sm text-slate-400 text-center py-4">No staff profiles found.</p>
                  )}
                </CardContent>
              </Card>
            )}

            {/* 4. TIMING & ADDRESS TAB */}
            {activeTab === 'timing' && (
              <div className="space-y-4">
                <Card>
                  <CardHeader className="pb-2"><CardTitle className="text-xs text-slate-500">Address & Coordinates</CardTitle></CardHeader>
                  <CardContent className="text-sm">
                    <div><span className="font-semibold text-slate-800 dark:text-slate-200">{salon.fullAddress}</span></div>
                    {salon.area && <div className="text-slate-400 mt-1">Area: {salon.area}</div>}
                    {salon.latitude && salon.longitude && (
                      <div className="text-xs text-slate-400 mt-2">
                        Geocode Coordinates: {salon.latitude}, {salon.longitude}
                      </div>
                    )}
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="pb-2"><CardTitle className="text-xs text-slate-500">Working / Business Hours</CardTitle></CardHeader>
                  <CardContent className="text-sm">
                    {salon.workingHours && salon.workingHours.length > 0 ? (
                      <div className="grid grid-cols-2 gap-2">
                        {salon.workingHours.map((wh) => (
                          <div key={wh.id} className="flex justify-between border-b py-1">
                            <span className="font-semibold capitalize text-slate-700 dark:text-slate-300">{wh.dayOfWeek.toLowerCase()}</span>
                            <span className="text-slate-500">
                              {wh.isOpen ? `${wh.openTime} - ${wh.closeTime}` : <span className="text-red-500 font-medium">CLOSED</span>}
                            </span>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <span className="text-slate-400 text-xs">No business hours configured yet.</span>
                    )}
                  </CardContent>
                </Card>

                {salon.holidays && salon.holidays.length > 0 && (
                  <Card>
                    <CardHeader className="pb-2"><CardTitle className="text-xs text-slate-500">Business Holidays</CardTitle></CardHeader>
                    <CardContent className="text-sm">
                      <div className="flex flex-wrap gap-1.5">
                        {salon.holidays.map((h) => (
                          <Badge key={h.id} variant="outline">
                            {new Date(h.date).toLocaleDateString()}: {h.description || 'Holiday'}
                          </Badge>
                        ))}
                      </div>
                    </CardContent>
                  </Card>
                )}
              </div>
            )}
          </div>

          <DialogFooter className="flex justify-between items-center sm:justify-between border-t pt-4">
            <Button
              variant="destructive"
              size="sm"
              onClick={() => setShowDeleteConfirm(true)}
              disabled={actionLoading !== null}
            >
              Hard Delete Salon
            </Button>
            <div className="flex gap-2">
              {salon.status === 'PENDING_APPROVAL' || salon.status === 'REJECTED' ? (
                <>
                  <Button
                    variant="default"
                    className="bg-green-600 hover:bg-green-700 text-white"
                    size="sm"
                    onClick={() => handleStatus('APPROVED' as TenantStatus, true)}
                    disabled={actionLoading !== null}
                  >
                    {actionLoading === 'APPROVED' ? 'Approving...' : 'Approve'}
                  </Button>
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => handleStatus('REJECTED' as TenantStatus, false)}
                    disabled={actionLoading !== null}
                  >
                    {actionLoading === 'REJECTED' ? 'Rejecting...' : 'Reject'}
                  </Button>
                </>
              ) : salon.status === 'APPROVED' ? (
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={() => handleStatus('SUSPENDED' as TenantStatus, false)}
                  disabled={actionLoading !== null}
                >
                  {actionLoading === 'SUSPENDED' ? 'Suspending...' : 'Suspend'}
                </Button>
              ) : null}
              <Button variant="outline" size="sm" onClick={() => onOpenChange(false)}>Close</Button>
            </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={showDeleteConfirm} onOpenChange={setShowDeleteConfirm}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="text-red-600">Confirm Hard Delete Salon</DialogTitle>
            <DialogDescription>
              Are you absolutely sure you want to permanently delete **{salon.name}**?
              <br />
              <span className="text-red-500 font-bold block mt-2 text-xs">
                ⚠️ WARNING: This action will permanently purge this salon (tenant), its branch locations, staff profiles, bookings, payments, and all salon users directly from the database. This cannot be undone!
              </span>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="gap-2 sm:gap-0 sm:flex-row justify-end">
            <Button variant="outline" onClick={() => setShowDeleteConfirm(false)} disabled={actionLoading !== null}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete} disabled={actionLoading !== null}>
              {actionLoading === 'delete' ? 'Purging...' : 'Purge from DB'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
