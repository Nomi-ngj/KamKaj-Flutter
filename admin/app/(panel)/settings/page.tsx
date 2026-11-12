'use client';

import { FormEvent, useEffect, useState } from 'react';
import { api, session } from '@/lib/api';
import { useApi } from '@/lib/hooks';
import { money, toMajor, toMinor } from '@/lib/format';
import { Button, Card, ErrorBox, Field, Input, Loading, Notice, PageHeader } from '@/components/ui';
import { MapPreview } from '@/components/extras';

interface Settings {
  searchRadiusKm: number;
  defaultLatitude: number;
  defaultLongitude: number;
  defaultCityName: string;
  freeDeliveryThreshold: number;
  serviceFee: number;
  nearbyLimit: number;
  supportPhone: string | null;
  updatedAt: string;
}

export default function SettingsPage() {
  const { data, setData, error, loading, reload } = useApi<Settings>('/admin/settings');
  const [form, setForm] = useState<Record<string, string>>({});
  const [busy, setBusy] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const canEdit = session.user?.role === 'admin';

  useEffect(() => {
    if (data) {
      setForm({
        searchRadiusKm: String(data.searchRadiusKm),
        defaultLatitude: String(data.defaultLatitude),
        defaultLongitude: String(data.defaultLongitude),
        defaultCityName: data.defaultCityName,
        freeDeliveryThreshold: toMajor(data.freeDeliveryThreshold),
        serviceFee: toMajor(data.serviceFee),
        nearbyLimit: String(data.nearbyLimit),
        supportPhone: data.supportPhone ?? '',
      });
    }
  }, [data]);

  const set = (k: string, v: string) => {
    setSaved(false);
    setForm((f) => ({ ...f, [k]: v }));
  };

  async function save(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setSaveError(null);
    try {
      const updated = await api<Settings>('/admin/settings', {
        method: 'PUT',
        body: {
          searchRadiusKm: Number(form.searchRadiusKm),
          defaultLatitude: Number(form.defaultLatitude),
          defaultLongitude: Number(form.defaultLongitude),
          defaultCityName: form.defaultCityName,
          freeDeliveryThreshold: toMinor(form.freeDeliveryThreshold),
          serviceFee: toMinor(form.serviceFee),
          nearbyLimit: Number(form.nearbyLimit),
          supportPhone: form.supportPhone,
        },
      });
      setData(updated);
      setSaved(true);
    } catch (err) {
      setSaveError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  if (loading && !data) return <Loading />;
  if (error) return <ErrorBox message={error} onRetry={reload} />;

  return (
    <form onSubmit={save}>
      <PageHeader title="Settings" subtitle="Applies to every customer within about 15 seconds." actions={canEdit && <Button type="submit" loading={busy}>Save settings</Button>} />
      {!canEdit && <div className="mb-4"><Notice tone="amber">Only admins can change settings.</Notice></div>}
      {saveError && <div className="mb-4"><ErrorBox message={saveError} /></div>}
      {saved && <div className="mb-4"><Notice tone="green">Settings saved.</Notice></div>}
      <fieldset disabled={!canEdit} className="grid gap-6 lg:grid-cols-2">
        <Card title="Location & search radius">
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Search radius (km)" hint="Stores further than this never show, even if their own radius is bigger." className="sm:col-span-2">
              <Input type="number" step="0.5" min="0.5" max="100" value={form.searchRadiusKm ?? ''} onChange={(e) => set('searchRadiusKm', e.target.value)} />
            </Field>
            <Field label="Nearby stores shown" hint="Max stores in “Nearby” on the home screen">
              <Input type="number" min="1" max="50" value={form.nearbyLimit ?? ''} onChange={(e) => set('nearbyLimit', e.target.value)} />
            </Field>
            <Field label="Default city"><Input value={form.defaultCityName ?? ''} onChange={(e) => set('defaultCityName', e.target.value)} /></Field>
            <Field label="Default latitude" hint="Used when a customer has no location yet"><Input value={form.defaultLatitude ?? ''} onChange={(e) => set('defaultLatitude', e.target.value)} /></Field>
            <Field label="Default longitude"><Input value={form.defaultLongitude ?? ''} onChange={(e) => set('defaultLongitude', e.target.value)} /></Field>
          </div>
          <div className="mt-4">
            <MapPreview lat={Number(form.defaultLatitude)} lng={Number(form.defaultLongitude)} radiusKm={Number(form.searchRadiusKm)} />
          </div>
        </Card>
        <Card title="Fees">
          <div className="space-y-4">
            <Field label="Free delivery from (PKR)" hint={`Orders with a subtotal of ${money(toMinor(form.freeDeliveryThreshold ?? '0'))} or more pay no delivery fee. Otherwise the store’s own fee applies.`}>
              <Input type="number" min="0" value={form.freeDeliveryThreshold ?? ''} onChange={(e) => set('freeDeliveryThreshold', e.target.value)} />
            </Field>
            <Field label="Service fee (PKR)" hint="Added to every order">
              <Input type="number" min="0" value={form.serviceFee ?? ''} onChange={(e) => set('serviceFee', e.target.value)} />
            </Field>
            <Field label="Support phone">
              <Input value={form.supportPhone ?? ''} onChange={(e) => set('supportPhone', e.target.value)} />
            </Field>
          </div>
        </Card>
      </fieldset>
    </form>
  );
}
