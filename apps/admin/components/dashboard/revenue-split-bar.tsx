'use client';

import { useState } from 'react';
import { formatCurrency } from '@/lib/utils';

interface Segment {
  key: string;
  label: string;
  value: number;
}

export function RevenueSplitBar({
  salonRevenue,
  platformCommission,
}: {
  salonRevenue: number;
  platformCommission: number;
}) {
  const [hovered, setHovered] = useState<string | null>(null);
  const total = salonRevenue + platformCommission;

  const segments: Segment[] = [
    { key: 'salon', label: 'Salon revenue', value: salonRevenue },
    { key: 'commission', label: 'Platform commission', value: platformCommission },
  ];

  if (total <= 0) {
    return <p className="text-sm text-slate-500 dark:text-slate-400">No captured revenue yet.</p>;
  }

  return (
    <div className="revenue-split">
      <style>{`
        .revenue-split { --seg-salon: #2a78d6; --seg-commission: #1baf7a; --ink-primary: #0b0b0b; --ink-secondary: #52514e; --surface: #fcfcfb; }
        @media (prefers-color-scheme: dark) {
          .revenue-split { --seg-salon: #3987e5; --seg-commission: #199e70; --ink-primary: #ffffff; --ink-secondary: #c3c2b7; --surface: #1a1a19; }
        }
      `}</style>

      {/* Legend — always present for 2+ series */}
      <div className="mb-3 flex flex-wrap gap-4">
        {segments.map((s) => (
          <div key={s.key} className="flex items-center gap-1.5 text-sm">
            <span
              className="inline-block h-2.5 w-2.5 rounded-[2px]"
              style={{ background: s.key === 'salon' ? 'var(--seg-salon)' : 'var(--seg-commission)' }}
            />
            <span className="text-slate-600 dark:text-slate-400">{s.label}</span>
            <span className="font-medium text-slate-900 dark:text-slate-100">{formatCurrency(s.value)}</span>
          </div>
        ))}
      </div>

      {/* Single stacked bar, part-to-whole */}
      <div className="relative flex h-6 w-full overflow-visible">
        {segments.map((s, i) => {
          const pct = (s.value / total) * 100;
          const isFirst = i === 0;
          const isLast = i === segments.length - 1;
          return (
            <div
              key={s.key}
              className="relative h-6 transition-[filter] duration-150"
              style={{
                width: `${pct}%`,
                background: s.key === 'salon' ? 'var(--seg-salon)' : 'var(--seg-commission)',
                marginRight: isLast ? 0 : 2,
                borderTopLeftRadius: isFirst ? 4 : 0,
                borderBottomLeftRadius: isFirst ? 4 : 0,
                borderTopRightRadius: isLast ? 4 : 0,
                borderBottomRightRadius: isLast ? 4 : 0,
                filter: hovered && hovered !== s.key ? 'brightness(0.92)' : undefined,
              }}
              onMouseEnter={() => setHovered(s.key)}
              onMouseLeave={() => setHovered(null)}
              onFocus={() => setHovered(s.key)}
              onBlur={() => setHovered(null)}
              tabIndex={0}
              role="img"
              aria-label={`${s.label}: ${formatCurrency(s.value)}, ${pct.toFixed(1)} percent`}
            >
              {pct >= 14 && (
                <span className="absolute inset-0 flex items-center justify-center text-xs font-medium text-white">
                  {pct.toFixed(0)}%
                </span>
              )}

              {hovered === s.key && (
                <div
                  className="pointer-events-none absolute -top-14 left-1/2 z-10 w-max -translate-x-1/2 rounded-md border px-2.5 py-1.5 text-xs shadow-md"
                  style={{ background: 'var(--surface)', borderColor: 'rgba(11,11,11,0.10)' }}
                >
                  <div className="font-semibold" style={{ color: 'var(--ink-primary)' }}>
                    {formatCurrency(s.value)}
                  </div>
                  <div style={{ color: 'var(--ink-secondary)' }}>{s.label}</div>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
