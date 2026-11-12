'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { api } from './api';

type Query = Record<string, string | number | boolean | undefined | null>;

/** Loads `path` (re-loads when path or query change). `reload()` fetches again. */
export function useApi<T>(path: string | null, query?: Query) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const key = path ? `${path}?${JSON.stringify(query ?? {})}` : null;
  const latest = useRef(0);

  const load = useCallback(async () => {
    if (!path) return;
    const id = ++latest.current;
    setLoading(true);
    setError(null);
    try {
      const result = await api<T>(path, { query });
      if (id === latest.current) setData(result);
    } catch (e) {
      if (id === latest.current) setError((e as Error).message);
    } finally {
      if (id === latest.current) setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  useEffect(() => {
    void load();
  }, [load]);

  return { data, setData, error, loading, reload: load };
}

/** Debounced value for search boxes. */
export function useDebounced<T>(value: T, ms = 300) {
  const [v, setV] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setV(value), ms);
    return () => clearTimeout(t);
  }, [value, ms]);
  return v;
}
