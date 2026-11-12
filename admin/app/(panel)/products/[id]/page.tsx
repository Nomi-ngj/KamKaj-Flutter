'use client';

import { Suspense, FormEvent, useEffect, useState } from 'react';
import { useParams, useRouter, useSearchParams } from 'next/navigation';
import { api, Page } from '@/lib/api';
import { useApi } from '@/lib/hooks';
import { toMajor, toMinor } from '@/lib/format';
import type { ProductRow, StoreRow } from '@/lib/types';
import { Button, Card, ErrorBox, Field, Input, Loading, Notice, PageHeader, Select, Textarea, Toggle } from '@/components/ui';
import { ImageField } from '@/components/extras';

function ProductEditor() {
  const { id } = useParams<{ id: string }>();
  const isNew = id === 'new';
  const router = useRouter();
  const params = useSearchParams();
  const product = useApi<ProductRow>(isNew ? null : `/admin/products/${id}`);
  const stores = useApi<Page<StoreRow>>('/admin/stores', { pageSize: 100 });
  const [form, setForm] = useState({
    storeId: params.get('storeId') ?? '',
    name: '',
    description: '',
    shortDescription: '',
    price: '',
    section: '',
    unit: '',
    imageUrl: '',
    isDailyPick: false,
    isAvailable: true,
    sortOrder: '0',
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const p = product.data;
    if (p) {
      setForm({
        storeId: p.storeId,
        name: p.name,
        description: p.description,
        shortDescription: p.shortDescription ?? '',
        price: toMajor(p.price),
        section: p.section ?? '',
        unit: p.unit ?? '',
        imageUrl: p.imageUrl ?? '',
        isDailyPick: p.isDailyPick,
        isAvailable: p.isAvailable,
        sortOrder: String(p.sortOrder),
      });
    }
  }, [product.data]);

  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => {
    setSaved(false);
    setForm((f) => ({ ...f, [key]: value }));
  };
  const store = stores.data?.data.find((s) => s.id === form.storeId);

  async function save(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const body = { ...form, price: toMinor(form.price), sortOrder: Number(form.sortOrder) || 0 };
      const result = await api<ProductRow>(isNew ? '/admin/products' : `/admin/products/${id}`, { method: isNew ? 'POST' : 'PATCH', body });
      if (isNew) router.replace(`/products/${result.id}`);
      else {
        product.setData(result);
        setSaved(true);
      }
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!confirm(`Delete ${form.name}? Past orders keep their copy of the item.`)) return;
    try {
      await api(`/admin/products/${id}`, { method: 'DELETE' });
      router.replace(`/products?storeId=${form.storeId}`);
    } catch (err) {
      setError((err as Error).message);
    }
  }

  if (!isNew && product.loading && !product.data) return <Loading />;
  if (product.error) return <ErrorBox message={product.error} onRetry={product.reload} />;

  return (
    <form onSubmit={save}>
      <PageHeader
        back={`/products${form.storeId ? `?storeId=${form.storeId}` : ''}`}
        title={isNew ? 'Add product' : form.name || 'Product'}
        actions={
          <>
            {!isNew && <Button type="button" variant="ghost" onClick={remove}>Delete</Button>}
            <Button type="submit" loading={busy}>{isNew ? 'Create product' : 'Save changes'}</Button>
          </>
        }
      />
      {error && <div className="mb-4"><ErrorBox message={error} /></div>}
      {saved && <div className="mb-4"><Notice tone="green">Saved.</Notice></div>}
      <div className="grid gap-6 lg:grid-cols-3">
        <Card title="Details" className="lg:col-span-2">
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Store" className="sm:col-span-2">
              <Select value={form.storeId} onChange={(e) => set('storeId', e.target.value)} required>
                <option value="">Choose a store…</option>
                {stores.data?.data.map((s) => (
                  <option key={s.id} value={s.id}>{s.name} ({s.city})</option>
                ))}
              </Select>
            </Field>
            <Field label="Name"><Input value={form.name} onChange={(e) => set('name', e.target.value)} required /></Field>
            <Field label="Price (PKR)"><Input type="number" min="0" step="0.01" value={form.price} onChange={(e) => set('price', e.target.value)} required /></Field>
            <Field label="Section" hint={store?.menuSections.length ? `Store sections: ${store.menuSections.join(', ')}` : 'e.g. Pastries'}>
              <Input value={form.section} onChange={(e) => set('section', e.target.value)} list="sections" />
              <datalist id="sections">{store?.menuSections.map((s) => <option key={s} value={s} />)}</datalist>
            </Field>
            <Field label="Unit" hint="Optional, e.g. KG, Dozen, 1 L"><Input value={form.unit} onChange={(e) => set('unit', e.target.value)} /></Field>
            <Field label="Short description" hint="One line under the name, e.g. “Flaky & buttery”" className="sm:col-span-2">
              <Input value={form.shortDescription} onChange={(e) => set('shortDescription', e.target.value)} />
            </Field>
            <Field label="Description" className="sm:col-span-2"><Textarea rows={4} value={form.description} onChange={(e) => set('description', e.target.value)} /></Field>
            <Field label="Sort order" hint="Lower numbers show first within a section"><Input type="number" value={form.sortOrder} onChange={(e) => set('sortOrder', e.target.value)} /></Field>
          </div>
        </Card>
        <div className="space-y-6">
          <Card title="Availability">
            <div className="space-y-4">
              <Toggle checked={form.isAvailable} onChange={(v) => set('isAvailable', v)} label="In stock" hint="Out-of-stock items show but can’t be ordered" />
              <Toggle checked={form.isDailyPick} onChange={(v) => set('isDailyPick', v)} label="Daily pick" hint="Shown on the home screen" />
            </div>
          </Card>
          <Card title="Image"><ImageField value={form.imageUrl} onChange={(v) => set('imageUrl', v)} /></Card>
        </div>
      </div>
    </form>
  );
}

export default function ProductEditPage() {
  return (
    <Suspense fallback={<Loading />}>
      <ProductEditor />
    </Suspense>
  );
}
