'use client';

import { useState } from 'react';
import { api } from '@/lib/api';
import { useApi } from '@/lib/hooks';
import { money, toMajor, toMinor } from '@/lib/format';
import { Badge, Button, Card, ErrorBox, Field, Input, Loading, Modal, PageHeader, Table, Td, Toggle } from '@/components/ui';

interface Service { id: string; name: string; image: string; sortOrder: number; isActive: boolean }
interface Vehicle { id: string; name: string; image: string; capacity: string; baseFare: number; perKmFare: number; sortOrder: number; isActive: boolean }

type Draft =
  | { kind: 'service'; isNew: boolean; id: string; name: string; image: string; sortOrder: number; isActive: boolean }
  | { kind: 'vehicle'; isNew: boolean; id: string; name: string; image: string; capacity: string; baseFare: string; perKmFare: string; sortOrder: number; isActive: boolean };

export default function ServicesPage() {
  const services = useApi<Service[]>('/admin/services');
  const vehicles = useApi<Vehicle[]>('/admin/vehicle-types');
  const [draft, setDraft] = useState<Draft | null>(null);
  const [busy, setBusy] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  async function save() {
    if (!draft) return;
    setBusy(true);
    setFormError(null);
    const base = draft.kind === 'service' ? '/admin/services' : '/admin/vehicle-types';
    const { kind: _k, isNew, id, ...rest } = draft;
    const body =
      draft.kind === 'vehicle'
        ? { ...rest, baseFare: toMinor(draft.baseFare), perKmFare: toMinor(draft.perKmFare) }
        : rest;
    try {
      if (isNew) await api(base, { method: 'POST', body: { ...body, ...(id ? { id } : {}) } });
      else await api(`${base}/${id}`, { method: 'PATCH', body });
      setDraft(null);
      await (draft.kind === 'service' ? services.reload() : vehicles.reload());
    } catch (e) {
      setFormError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!draft || draft.isNew || !confirm(`Delete “${draft.name}”?`)) return;
    try {
      await api(`${draft.kind === 'service' ? '/admin/services' : '/admin/vehicle-types'}/${draft.id}`, { method: 'DELETE' });
      setDraft(null);
      await (draft.kind === 'service' ? services.reload() : vehicles.reload());
    } catch (e) {
      setFormError((e as Error).message);
    }
  }

  return (
    <>
      <PageHeader title="Services & vehicles" subtitle="The image key must match an image bundled in the app (e.g. express_ride, sedan)." />
      <div className="grid gap-6 lg:grid-cols-2">
        <Card title="Services" padded={false} actions={<Button variant="ghost" onClick={() => setDraft({ kind: 'service', isNew: true, id: '', name: '', image: 'express_ride', sortOrder: 0, isActive: true })}>+ Add</Button>}>
          {services.error && <ErrorBox message={services.error} onRetry={services.reload} />}
          {services.loading && !services.data ? <Loading /> : (
            <Table head={['Service', 'Image key', 'Status', '']} empty={!services.data?.length}>
              {services.data?.map((s) => (
                <tr key={s.id}>
                  <Td><div className="font-medium">{s.name}</div><div className="text-xs text-gray-500">id: {s.id}</div></Td>
                  <Td><code className="text-xs">{s.image}</code></Td>
                  <Td><Badge tone={s.isActive ? 'green' : 'gray'}>{s.isActive ? 'Active' : 'Hidden'}</Badge></Td>
                  <Td><Button variant="ghost" onClick={() => { setFormError(null); setDraft({ kind: 'service', isNew: false, ...s }); }}>Edit</Button></Td>
                </tr>
              ))}
            </Table>
          )}
        </Card>
        <Card title="Ride vehicle types" padded={false} actions={<Button variant="ghost" onClick={() => setDraft({ kind: 'vehicle', isNew: true, id: '', name: '', image: 'sedan', capacity: '', baseFare: '0', perKmFare: '0', sortOrder: 0, isActive: true })}>+ Add</Button>}>
          {vehicles.error && <ErrorBox message={vehicles.error} onRetry={vehicles.reload} />}
          {vehicles.loading && !vehicles.data ? <Loading /> : (
            <Table head={['Vehicle', 'Fare', 'Status', '']} empty={!vehicles.data?.length}>
              {vehicles.data?.map((v) => (
                <tr key={v.id}>
                  <Td><div className="font-medium">{v.name}</div><div className="text-xs text-gray-500">{v.capacity} · image {v.image}</div></Td>
                  <Td className="text-xs">{money(v.baseFare)} + {money(v.perKmFare)}/km</Td>
                  <Td><Badge tone={v.isActive ? 'green' : 'gray'}>{v.isActive ? 'Active' : 'Hidden'}</Badge></Td>
                  <Td><Button variant="ghost" onClick={() => { setFormError(null); setDraft({ kind: 'vehicle', isNew: false, ...v, baseFare: toMajor(v.baseFare), perKmFare: toMajor(v.perKmFare) }); }}>Edit</Button></Td>
                </tr>
              ))}
            </Table>
          )}
        </Card>
      </div>

      <Modal
        open={!!draft}
        title={draft ? `${draft.isNew ? 'Add' : 'Edit'} ${draft.kind === 'service' ? 'service' : 'vehicle type'}` : ''}
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
              <Field label="Image key"><Input value={draft.image} onChange={(e) => setDraft({ ...draft, image: e.target.value })} /></Field>
              {draft.isNew && <Field label="Id (optional)"><Input value={draft.id} onChange={(e) => setDraft({ ...draft, id: e.target.value })} /></Field>}
              <Field label="Sort order"><Input type="number" value={draft.sortOrder} onChange={(e) => setDraft({ ...draft, sortOrder: Number(e.target.value) })} /></Field>
              {draft.kind === 'vehicle' && (
                <>
                  <Field label="Capacity"><Input value={draft.capacity} placeholder="Up to 4 riders" onChange={(e) => setDraft({ ...draft, capacity: e.target.value })} /></Field>
                  <Field label="Base fare (PKR)"><Input type="number" value={draft.baseFare} onChange={(e) => setDraft({ ...draft, baseFare: e.target.value })} /></Field>
                  <Field label="Per km (PKR)"><Input type="number" value={draft.perKmFare} onChange={(e) => setDraft({ ...draft, perKmFare: e.target.value })} /></Field>
                </>
              )}
            </div>
            <Toggle checked={draft.isActive} onChange={(v) => setDraft({ ...draft, isActive: v })} label="Active" hint="Hidden items don’t show in the app" />
          </>
        )}
      </Modal>
    </>
  );
}
