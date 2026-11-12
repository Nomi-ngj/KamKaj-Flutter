'use client';

/**
 * Small fetch wrapper for the KamKaj API.
 * - Adds the admin's bearer token
 * - Refreshes it once on 401, then sends the admin to /login if that fails
 * - Throws ApiError with the API's user-facing `message`
 */
export const API_URL = (process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000/v1').replace(/\/$/, '');
export const APP_ENV = process.env.NEXT_PUBLIC_APP_ENV ?? 'staging';

const ACCESS_KEY = 'kamkaj.admin.access';
const REFRESH_KEY = 'kamkaj.admin.refresh';
const USER_KEY = 'kamkaj.admin.user';

export interface AdminUser {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  role: 'admin' | 'staff' | 'customer';
}

export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
  ) {
    super(message);
  }
}

function storage(): Storage | null {
  try {
    return typeof window === 'undefined' ? null : window.localStorage;
  } catch {
    return null;
  }
}

export const session = {
  get access() {
    return storage()?.getItem(ACCESS_KEY) ?? null;
  },
  get refresh() {
    return storage()?.getItem(REFRESH_KEY) ?? null;
  },
  get user(): AdminUser | null {
    try {
      const raw = storage()?.getItem(USER_KEY);
      return raw ? (JSON.parse(raw) as AdminUser) : null;
    } catch {
      return null;
    }
  },
  save(access: string, refresh: string, user?: AdminUser) {
    const s = storage();
    s?.setItem(ACCESS_KEY, access);
    s?.setItem(REFRESH_KEY, refresh);
    if (user) s?.setItem(USER_KEY, JSON.stringify(user));
  },
  clear() {
    const s = storage();
    s?.removeItem(ACCESS_KEY);
    s?.removeItem(REFRESH_KEY);
    s?.removeItem(USER_KEY);
  },
};

let refreshing: Promise<boolean> | null = null;

async function refreshTokens(): Promise<boolean> {
  const refresh = session.refresh;
  if (!refresh) return false;
  refreshing ??= (async () => {
    try {
      const res = await fetch(`${API_URL}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: refresh }),
      });
      if (!res.ok) return false;
      const data = (await res.json()) as { accessToken: string; refreshToken: string };
      session.save(data.accessToken, data.refreshToken);
      return true;
    } catch {
      return false;
    } finally {
      setTimeout(() => (refreshing = null), 0);
    }
  })();
  return refreshing;
}

function goToLogin() {
  session.clear();
  if (typeof window !== 'undefined' && !window.location.pathname.startsWith('/login')) {
    window.location.href = `/login?next=${encodeURIComponent(window.location.pathname)}`;
  }
}

type Query = Record<string, string | number | boolean | undefined | null>;

export async function api<T = unknown>(
  path: string,
  opts: { method?: string; body?: unknown; query?: Query; form?: FormData; retry?: boolean } = {},
): Promise<T> {
  const url = new URL(`${API_URL}${path}`);
  for (const [k, v] of Object.entries(opts.query ?? {})) {
    if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v));
  }
  const headers: Record<string, string> = { Accept: 'application/json' };
  if (session.access) headers.Authorization = `Bearer ${session.access}`;
  if (opts.body !== undefined) headers['Content-Type'] = 'application/json';

  let res: Response;
  try {
    res = await fetch(url, {
      method: opts.method ?? 'GET',
      headers,
      body: opts.form ?? (opts.body !== undefined ? JSON.stringify(opts.body) : undefined),
    });
  } catch {
    throw new ApiError(`Can't reach the API at ${API_URL}. Is the backend running?`, 0);
  }

  if (res.status === 401 && opts.retry !== false && !path.startsWith('/admin/auth')) {
    if (await refreshTokens()) return api<T>(path, { ...opts, retry: false });
    goToLogin();
    throw new ApiError('Your session has expired. Please sign in again.', 401);
  }

  if (res.status === 204) return undefined as T;
  const text = await res.text();
  const data = text ? JSON.parse(text) : undefined;
  if (!res.ok) {
    const message = (data as { message?: string } | undefined)?.message ?? `Request failed (${res.status})`;
    throw new ApiError(message, res.status);
  }
  return data as T;
}

export async function signIn(email: string, password: string) {
  const data = await api<{ accessToken: string; refreshToken: string; user: AdminUser }>('/admin/auth/sign-in', {
    method: 'POST',
    body: { email, password },
  });
  session.save(data.accessToken, data.refreshToken, data.user);
  return data.user;
}

export async function signOut() {
  try {
    await api('/auth/sign-out', { method: 'POST', body: { refreshToken: session.refresh ?? undefined } });
  } catch {
    // Signing out locally is enough if the API is unreachable.
  }
  session.clear();
  window.location.href = '/login';
}

export async function uploadImage(file: File): Promise<string> {
  const form = new FormData();
  form.append('file', file);
  const { url } = await api<{ url: string }>('/admin/uploads', { method: 'POST', form });
  return url;
}

export interface Page<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
}
