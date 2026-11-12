/** Paisa → "PKR 1,250" (or "PKR 1,250.50" when there are paisa). */
export function money(minor: number | null | undefined): string {
  if (minor === null || minor === undefined) return '—';
  const major = minor / 100;
  return `PKR ${major.toLocaleString('en-PK', { minimumFractionDigits: major % 1 ? 2 : 0, maximumFractionDigits: 2 })}`;
}

/** "PKR" input (major units, e.g. "650") → paisa. */
export function toMinor(major: string | number): number {
  const n = typeof major === 'number' ? major : Number(String(major).replace(/,/g, ''));
  return Number.isFinite(n) ? Math.round(n * 100) : 0;
}

export function toMajor(minor: number | null | undefined): string {
  return minor === null || minor === undefined ? '' : String(minor / 100);
}

const dateFmt = new Intl.DateTimeFormat('en-PK', {
  timeZone: 'Asia/Karachi',
  day: 'numeric',
  month: 'short',
  hour: 'numeric',
  minute: '2-digit',
});

export function dateTime(iso: string | null | undefined): string {
  return iso ? dateFmt.format(new Date(iso)) : '—';
}

export function timeAgo(iso: string | null | undefined): string {
  if (!iso) return '—';
  const s = Math.round((Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return 'just now';
  if (s < 3600) return `${Math.floor(s / 60)} min ago`;
  if (s < 86400) return `${Math.floor(s / 3600)} h ago`;
  return `${Math.floor(s / 86400)} d ago`;
}

export const ORDER_STATUS_LABEL: Record<string, string> = {
  awaitingPayment: 'Awaiting payment',
  pending: 'Pending',
  inTransit: 'In transit',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
};

export const ORDER_STATUS_TONE: Record<string, Tone> = {
  awaitingPayment: 'amber',
  pending: 'blue',
  inTransit: 'violet',
  delivered: 'green',
  cancelled: 'red',
};

export type Tone = 'gray' | 'green' | 'red' | 'amber' | 'blue' | 'violet';
