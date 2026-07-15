import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatDate(value: string | Date): string {
  const date = typeof value === 'string' ? new Date(value) : value;
  return new Intl.DateTimeFormat('en-IN', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
}

export function getPublicImageUrl(url: string | null | undefined): string | undefined {
  if (!url) return undefined;
  if (typeof window !== 'undefined') {
    const publicHost = `${window.location.hostname}:4000`;
    return url
      .replace(/localhost:4000/g, publicHost)
      .replace(/127\.0\.0\.1:4000/g, publicHost)
      .replace(/10\.0\.2\.2:4000/g, publicHost)
      .replace(/trimly-backend:4000/g, publicHost);
  }
  return url;
}
