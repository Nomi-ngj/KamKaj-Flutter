'use client';

import { useRef, useState } from 'react';
import { uploadImage } from '@/lib/api';
import { Button, Input } from './ui';

/** Image URL field with an upload button (stores files on the API server). */
export function ImageField({ value, onChange }: { value: string; onChange: (url: string) => void }) {
  const input = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function pick(file?: File) {
    if (!file) return;
    setBusy(true);
    setError(null);
    try {
      onChange(await uploadImage(file));
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
      if (input.current) input.current.value = '';
    }
  }

  return (
    <div className="space-y-2">
      <div className="flex gap-3">
        {value ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={value} alt="" className="h-16 w-16 rounded-lg border border-gray-200 object-cover" />
        ) : (
          <div className="flex h-16 w-16 items-center justify-center rounded-lg border border-dashed border-gray-300 text-xs text-gray-400">
            No image
          </div>
        )}
        <div className="flex-1 space-y-2">
          <Input value={value} placeholder="https://… or upload" onChange={(e) => onChange(e.target.value)} />
          <div className="flex gap-2">
            <Button type="button" variant="secondary" loading={busy} onClick={() => input.current?.click()}>
              Upload image
            </Button>
            {value && (
              <Button type="button" variant="ghost" onClick={() => onChange('')}>
                Remove
              </Button>
            )}
          </div>
        </div>
      </div>
      {error && <p className="text-xs text-red-600">{error}</p>}
      <input ref={input} type="file" accept="image/png,image/jpeg,image/webp,image/gif" hidden onChange={(e) => pick(e.target.files?.[0])} />
    </div>
  );
}

/**
 * Map preview from OpenStreetMap (no API key needed). Shows the pin and, roughly, the delivery radius.
 * Click "Open in Google Maps" to find coordinates: right-click a spot there and copy the numbers.
 */
export function MapPreview({ lat, lng, radiusKm }: { lat: number; lng: number; radiusKm?: number }) {
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) {
    return <div className="flex h-56 items-center justify-center rounded-lg bg-gray-100 text-sm text-gray-500">Enter valid coordinates</div>;
  }
  const r = Math.max(0.5, radiusKm ?? 2);
  const dLat = r / 111.32;
  const dLng = r / (111.32 * Math.cos((lat * Math.PI) / 180));
  const bbox = [lng - dLng, lat - dLat, lng + dLng, lat + dLat].map((n) => n.toFixed(5)).join(',');
  return (
    <div className="space-y-1">
      <iframe
        title="Store location"
        className="h-56 w-full rounded-lg border border-gray-200"
        src={`https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat},${lng}`}
      />
      <div className="flex justify-between text-xs text-gray-500">
        <span>Map area ≈ delivery radius ({r} km each side)</span>
        <a className="text-brand hover:underline" href={`https://www.google.com/maps?q=${lat},${lng}`} target="_blank" rel="noreferrer">
          Open in Google Maps
        </a>
      </div>
    </div>
  );
}

/** Simple bar chart (no chart library). */
export function BarChart({ data, format }: { data: { label: string; value: number }[]; format?: (n: number) => string }) {
  const max = Math.max(1, ...data.map((d) => d.value));
  return (
    <div className="flex h-44 items-end gap-1.5">
      {data.map((d) => (
        <div key={d.label} className="group flex h-full flex-1 flex-col items-center justify-end gap-1">
          <span className="text-[10px] text-gray-500 opacity-0 group-hover:opacity-100">{format ? format(d.value) : d.value}</span>
          <div className="w-full rounded-t bg-brand/80 transition-colors group-hover:bg-brand" style={{ height: `${Math.max(2, (d.value / max) * 100)}%` }} title={`${d.label}: ${format ? format(d.value) : d.value}`} />
          <span className="text-[10px] text-gray-400">{d.label.slice(8)}</span>
        </div>
      ))}
    </div>
  );
}
