'use client';

import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { FormEvent, useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { useApi } from '@/lib/hooks';
import { toMajor, toMinor } from '@/lib/format';
import { Button, Card, ErrorBox, Field, Input, Loading, Notice, PageHeader, Toggle } from '@/components/ui';
import { ImageField, MapPreview } from '@/components/extras';
import type { StoreRow } from '@/lib/types';

interface Category {
  id: string;
  name: string;
}

const EMPTY = {
  name: '',
  categoryLabel: '',
  tagline: '',
  address: '',
  city: 'Karachi',
  latitude: '24.8607',
  longitude: '67.0011',
  deliveryRadiusKm: '5',
  rating: '4.5',
  deliveryTime: '20-30 min',
  deliveryFee: '100',
  imageUrl: '',
  opensAt: '09:00',
  closesAt: '22:00',
  menuSections: '',
  isFeatured: false,
  isActive: true,
  categoryIds: [] as string[],
};
type Form = typeof EMPTY;

function fromStore(s: StoreRow): Form {
  return {
    name: s.name,
    categoryLabel: s.categoryLabel,
    tagline: s.tagline ?? '',
    address: s.address,
    city: s.city,
    latitude: String(s.latitude),
    longitude: String(s.longitude),
    deliveryRadiusKm: String(s.deliveryRadiusKm),
    rating: String(s.rating),
    deliveryTime: s.deliveryTime,
    deliveryFee: toMajor(s.deliveryFee),
    imageUrl: s.imageUrl ?? '',
    opensAt: s.opensAt ?? '',
    closesAt: s.closesAt ?? '',
    menuSections: s.menuSections.join(', '),
    isFeatured: s.isFeatured,
    isActive: s.isActive,
    categoryIds: s.categoryIds,
  };
}

export default function StoreEditPage() {
  const { id } = useParams<{ id: string }>();
  const isNew = id === 'new';
  const router = useRouter();
  const store = useApi<StoreRow>(isNew ? null : `/admin/stores/${id}`);
  const categories = useApi<Category[]>('/admin/categories');
  const [form, setForm] = useState<Form>(EMPTY);
  const [alwaysOpen, setAlwaysOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (store.data) {
      setForm(fromStore(store.data));
      setAlwaysOpen(!store.data.opensAt || !store.data.closesAt);
    }
  }, [store.data]);

  const set = <K extends keyof Form>(key: K, value: Form[K]) => {
    setSaved(false);
    setForm((f) => ({ ...f, [key]: value }));
  };

  async function save(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const body = {
      ...form,
      latitude: Number(form.latitude),
      longitude: Number(form.longitude),
      deliveryRadiusKm: Number(form.deliveryRadiusKm),
      rating: Number(form.rating),
      deliveryFee: toMinor(form.deliveryFee),
      opensAt: alwaysOpen ? null : form.opensAt,
      closesAt: alwaysOpen ? null : form.closesAt,
      menuSections: form.menuSections.split(',').map((s) => s.trim()).filter(Boolean),
    };
    try {
      const result = await api<StoreRow>(isNew ? '/admin/stores' : `/admin/stores/${id}`, { method: isNew ? 'POST' : 'PATCH', body });
      if (isNew) router.replace(`/stores/${result.id}`);
      else {
        store.setData(result);
        setSaved(true);
      }
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!confirm(`Delete ${form.name}? This can’t be undone.`)) return;
    try {
      await api(`/admin/stores/${id}`, { method: 'DELETE' });
      router.replace('/stores');
    } catch (err) {
      setError((err as Error).message);
    }
  }

  if (!isNew && store.loading && !store.data) return <Loading />;
  if (store.error) return <ErrorBox message={store.error} onRetry={store.reload} />;

  return (
    <form onSubmit={save}>
      <PageHeader
        back="/stores"
        title={isNew ? 'Add store' : form.name || 'Store'}
        subtitle={!isNew && store.data ? `${store.data.productCount} products · ${store.data.orderCount} orders` : undefined}
        actions={
          <>
            {!isNew && <Link href={`/products?storeId=${id}`} className="rounded-lg px-3.5 py-2 text-sm font-medium text-brand hover:bg-brand-soft">Manage products</Link>}
            {!isNew && <Button type="button" variant="ghost" onClick={remove}>Delete</Button>}
            <Button type="submit" loading={busy}>{isNew ? 'Create store' : 'Save changes'}</Button>
          </>
        }
      />
      {error && <div className="mb-4"><ErrorBox message={error} /></div>}
      {saved && <div className="mb-4"><Notice tone="green">Saved. The app shows the change on its next refresh.</Notice></div>}

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card title="Details">
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Store name"><Input value={form.name} onChange={(e) => set('name', e.target.value)} required /></Field>
              <Field label="Type label" hint="Shown under the name, e.g. “Breads & Pastries”"><Input value={form.categoryLabel} onChange={(e) => set('categoryLabel', e.target.value)} /></Field>
              <Field label="Tagline" hint="Optional badge, e.g. “Local Favorite”"><Input value={form.tagline} onChange={(e) => set('tagline', e.target.value)} /></Field>
              <Field label="Rating (0–5)"><Input type="number" step="0.1" min="0" max="5" value={form.rating} onChange={(e) => set('rating', e.target.value)} /></Field>
              <Field label="Delivery time"><Input value={form.deliveryTime} onChange={(e) => set('deliveryTime', e.target.value)} placeholder="20-30 min" /></Field>
              <Field label="Delivery fee (PKR)" hint="Free when the order subtotal reaches the threshold in Settings"><Input type="number" min="0" value={form.deliveryFee} onChange={(e) => set('deliveryFee', e.target.value)} /></Field>
              <Field label="Menu sections" hint="Comma-separated, in display order" className="sm:col-span-2">
                <Input value={form.menuSections} onChange={(e) => set('menuSections', e.target.value)} placeholder="Pastries, Bread, Coffee" />
              </Field>
            </div>
          </Card>

          <Card title="Location & delivery area">
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Address" className="sm:col-span-2"><Input value={form.address} onChange={(e) => set('address', e.target.value)} required /></Field>
              <Field label="City"><Input value={form.city} onChange={(e) => set('city', e.target.value)} /></Field>
              <Field label="Delivery radius (km)" hint="The store only appears for customers within this distance">
                <Input type="number" step="0.5" min="0.5" max="50" value={form.deliveryRadiusKm} onChange={(e) => set('deliveryRadiusKm', e.target.value)} />
              </Field>
              <Field label="Latitude"><Input value={form.latitude} onChange={(e) => set('latitude', e.target.value)} required /></Field>
              <Field label="Longitude"><Input value={form.longitude} onChange={(e) => set('longitude', e.target.value)} required /></Field>
            </div>
            <p className="mt-3 text-xs text-gray-500">Tip: in Google Maps, right-click the shop and click the coordinates to copy them, then paste the two numbers here.</p>
            <div className="mt-3">
              <MapPreview lat={Number(form.latitude)} lng={Number(form.longitude)} radiusKm={Number(form.deliveryRadiusKm)} />
            </div>
          </Card>
        </div>

        <div className="space-y-6">
          <Card title="Visibility">
            <div className="space-y-4">
              <Toggle checked={form.isActive} onChange={(v) => set('isActive', v)} label="Active" hint="Inactive stores are hidden from the app" />
              <Toggle checked={form.isFeatured} onChange={(v) => set('isFeatured', v)} label="Featured" hint="Shown in “Featured stores” on the home screen" />
            </div>
          </Card>
          <Card title="Opening hours">
            <div className="space-y-4">
              <Toggle checked={alwaysOpen} onChange={setAlwaysOpen} label="Open 24/7" />
              {!alwaysOpen && (
                <div className="grid grid-cols-2 gap-3">
                  <Field label="Opens"><Input type="time" value={form.opensAt} onChange={(e) => set('opensAt', e.target.value)} /></Field>
                  <Field label="Closes"><Input type="time" value={form.closesAt} onChange={(e) => set('closesAt', e.target.value)} /></Field>
                </div>
              )}
              <p className="text-xs text-gray-500">Pakistan time. Closing after midnight (e.g. 18:00–03:00) is supported. Customers can’t order while a store is closed.</p>
            </div>
          </Card>
          <Card title="Image">
            <ImageField value={form.imageUrl} onChange={(v) => set('imageUrl', v)} />
          </Card>
          <Card title="Categories">
            {categories.loading && !categories.data ? (
              <Loading />
            ) : (
              <div className="max-h-72 space-y-1 overflow-y-auto">
                {categories.data?.map((c) => (
                  <label key={c.id} className="flex items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      className="accent-brand"
                      checked={form.categoryIds.includes(c.id)}
                      onChange={(e) =>
                        set('categoryIds', e.target.checked ? [...form.categoryIds, c.id] : form.categoryIds.filter((x) => x !== c.id))
                      }
                    />
                    {c.name}
                  </label>
                ))}
              </div>
            )}
          </Card>
        </div>
      </div>
    </form>
  );
}
