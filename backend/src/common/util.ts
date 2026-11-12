import { NotFoundException } from '@nestjs/common';

export function orNotFound<T>(value: T | undefined | null, what = 'item'): T {
  if (value === undefined || value === null) throw new NotFoundException(`That ${what} could not be found.`);
  return value;
}

export interface Page<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
}

export function pageParams(page?: string | number, pageSize?: string | number) {
  const p = Math.max(1, Number(page) || 1);
  const size = Math.min(100, Math.max(1, Number(pageSize) || 20));
  return { page: p, pageSize: size, offset: (p - 1) * size };
}

/** Major → minor units (PKR 650 → 65000). */
export const pkr = (major: number) => Math.round(major * 100);

const TIME_ZONE = 'Asia/Karachi';

/** Current "HH:mm" in Pakistan time. */
function nowHhMm(now = new Date()): string {
  return new Intl.DateTimeFormat('en-GB', { timeZone: TIME_ZONE, hour: '2-digit', minute: '2-digit', hour12: false }).format(now);
}

/** True when a store with these hours is open now. Null hours = always open. Handles overnight hours. */
export function isOpenNow(opensAt: string | null, closesAt: string | null, now = new Date()): boolean {
  if (!opensAt || !closesAt) return true;
  const t = nowHhMm(now);
  return opensAt <= closesAt ? t >= opensAt && t < closesAt : t >= opensAt || t < closesAt;
}

/** "21:00" → "9:00 PM" (format the app shows as "Open until 9:00 PM"). */
export function to12h(hhmm: string | null): string | null {
  if (!hhmm) return null;
  const [h, m] = hhmm.split(':').map(Number);
  const suffix = h >= 12 ? 'PM' : 'AM';
  const hour = h % 12 === 0 ? 12 : h % 12;
  return `${hour}:${String(m).padStart(2, '0')} ${suffix}`;
}

export function round1(n: number): number {
  return Math.round(n * 10) / 10;
}
