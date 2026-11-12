'use client';

import { useState } from 'react';
import { api } from '@/lib/api';
import { useApi } from '@/lib/hooks';
import type { CategoryRow } from '@/lib/types';
import { Badge, Button, Card, ErrorBox, Field, Input, Loading, Modal, PageHeader, Select, Table, Td, Toggle } from '@/components/ui';

const TINTS = ['red', 'green', 'yellow', 'blue', 'purple'] as const;
const TINT_DOT: Record<string, string> = { red: 'bg-red-400', green: 'bg-green-500', yellow: 'bg-yellow-400', blue: 'bg-blue-500', purple: 'bg-purple-500' };
const ICONS = ['food', 'grocery', 'pharmacy', 'flowers', 'pets', 'bakery', 'drinks', 'gifts', 'household', 'essentials', 'electronics', 'home_decor', 'toys', 'sports', 'healthcare', 'books', 'hardware', 'beauty', 'stationery', 'laundry', 'baby', 'party', 'garden', 'office', 'meat', 'organic', 'dessert', 'coffee', 'tailor', 'shoe', 'key', 'photo', 'fitness', 'yoga', 'auto', 'car_wash', 'bike', 'music', 'art', 'cleaning', 'electrician', 'plumber', 'store'];

type Draft = Omit<CategoryRow, 'storeCount'> & { isNew: boolean };
const blank = (): Draft => ({ isNew: true, id: '', name: '', subtitle: '', icon: 'store', tint: 'red', featured: false, sortOrder: 0, isActive: true });

export default function CategoriesPage() {
  const { data, error, loading, reload } = useApi<CategoryRow[]>('/admin/categories');
  const [draft, setDraft] = useState<Draft | null>(null);
  const [busy, setBusy] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  async function save() {
    if (!draft) return;
    setBusy(true);
    setFormError(null);
    const { isNew, id, ...body } = draft;
    try {
      if (isNew) await api('/admin/categories', { method: 'POST', body: { ...body, ...(id ? { id } : {}) } });
      else await api(`/admin/categories/${id}`, { method: 'PATCH', body });
      setDraft(null);
      await reload();
    } catch (e) {
      setFormError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!draft || draft.isNew || !confirm(`Delete “${draft.name}”? Stores lose this category.`)) return;
    try {
      await api(`/admin/categories/${draft.id}`, { method: 'DELETE' });
      setDraft(null);
      await reload();
    } catch (e) {
      setFormError((e as Error).message);
    }
  }

  return (
    <>
      <PageHeader
        title="Categories"
        subtitle="The icon key must match an icon in the app (see CategoryVisuals)."
        actions={<Button onClick={() => { setFormError(null); setDraft(blank()); }}>+ Add category</Button>}
      />
      {error && <ErrorBox message={error} onRetry={reload} />}
      <Card padded={false}>
        {loading && !data ? (
          <Loading />
        ) : (
          <Table head={['#', 'Category', 'Icon', 'Stores', 'Status', '']} empty={!data?.length}>
            {data?.map((c) => (
              <tr key={c.id} className="hover:bg-gray-50">
                <Td className="text-gray-400">{c.sortOrder}</Td>
                <Td>
                  <div className="flex items-center gap-2">
                    <span className={`h-2.5 w-2.5 rounded-full ${TINT_DOT[c.tint]}`} />
                    <span>
                      <span className="block font-medium text-gray-900">{c.name}</span>
                      <span className="block text-xs text-gray-500">{c.subtitle} · id: {c.id}</span>
                    </span>
                  </div>
                </Td>
                <Td><code className="text-xs">{c.icon}</code></Td>
                <Td>{c.storeCount}</Td>
                <Td>
                  <div className="flex gap-1">
                    <Badge tone={c.isActive ? 'green' : 'gray'}>{c.isActive ? 'Active' : 'Hidden'}</Badge>
                    {c.featured && <Badge tone="amber">Featured</Badge>}
                  </div>
                </Td>
                <Td>
                  <Button variant="ghost" onClick={() => { setFormError(null); setDraft({ ...c, isNew: false }); }}>Edit</Button>
                </Td>
              </tr>
            ))}
          </Table>
        )}
      </Card>

      <Modal
        open={!!draft}
        title={draft?.isNew ? 'Add category' : `Edit ${draft?.name ?? ''}`}
        onClose={() => setDraft(null)}
        footer={
          <>
            {draft && !draft.isNew && <Button variant="ghost" className="mr-auto text-red-600" onClick={remove}>Delete</Button>}
            <Button variant="secondary" onClick={() => setDraft(null)}>Cancel</Button>
            <Button loading={busy} onClick={save}>Save</Button>
          </>
        }
      >
        {formError && <ErrorBox message={formError} />}
        {draft && (
          <>
            <div className="grid grid-cols-2 gap-3">
              <Field label="Name"><Input value={draft.name} onChange={(e) => setDraft({ ...draft, name: e.target.value })} /></Field>
              <Field label="Subtitle"><Input value={draft.subtitle} placeholder="12 Stores" onChange={(e) => setDraft({ ...draft, subtitle: e.target.value })} /></Field>
              {draft.isNew && (
                <Field label="Id (optional)" hint="Readable id, e.g. halal_meat"><Input value={draft.id} onChange={(e) => setDraft({ ...draft, id: e.target.value })} /></Field>
              )}
              <Field label="Icon">
                <Select value={draft.icon} onChange={(e) => setDraft({ ...draft, icon: e.target.value })}>
                  {ICONS.map((i) => <option key={i}>{i}</option>)}
                </Select>
              </Field>
              <Field label="Tint">
                <Select value={draft.tint} onChange={(e) => setDraft({ ...draft, tint: e.target.value as Draft['tint'] })}>
                  {TINTS.map((t) => <option key={t}>{t}</option>)}
                </Select>
              </Field>
              <Field label="Sort order"><Input type="number" value={draft.sortOrder} onChange={(e) => setDraft({ ...draft, sortOrder: Number(e.target.value) })} /></Field>
            </div>
            <Toggle checked={draft.featured} onChange={(v) => setDraft({ ...draft, featured: v })} label="Featured" hint="Shown in the top row on the home screen" />
            <Toggle checked={draft.isActive} onChange={(v) => setDraft({ ...draft, isActive: v })} label="Active" />
          </>
        )}
      </Modal>
    </>
  );
}
