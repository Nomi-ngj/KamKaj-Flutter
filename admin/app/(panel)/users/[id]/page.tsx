'use client';

import { useParams } from 'next/navigation';
import { useState } from 'react';
import { api, session } from '@/lib/api';
import { useApi } from '@/lib/hooks';
import { dateTime } from '@/lib/format';
import { Badge, Button, Card, ErrorBox, Field, Input, Loading, Modal, PageHeader, Select } from '@/components/ui';
import { OrderRow, OrdersTable } from '@/components/orders-table';

interface UserDetail {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  emailVerified: boolean;
  role: 'customer' | 'staff' | 'admin';
  status: 'active' | 'blocked';
  phone: string | null;
  createdAt: string;
  lastLoginAt: string | null;
  addresses: { id: string; type: string; label: string; street: string; city: string; apartment: string | null; latitude: number | null; longitude: number | null; isDefault: boolean }[];
  paymentMethods: { id: string; type: string; brand: string; last4: string; expiry: string; isDefault: boolean }[];
  orders: OrderRow[];
}

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: user, error, loading, reload } = useApi<UserDetail>(`/admin/users/${id}`);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [cardOpen, setCardOpen] = useState(false);
  const [card, setCard] = useState({ type: 'card', brand: 'Visa', last4: '4242', expiry: '12/29' });
  const me = session.user;

  if (loading && !user) return <Loading />;
  if (error) return <ErrorBox message={error} onRetry={reload} />;
  if (!user) return null;

  async function patch(body: Record<string, unknown>) {
    setBusy(true);
    setActionError(null);
    try {
      await api(`/admin/users/${id}`, { method: 'PATCH', body });
      await reload();
    } catch (e) {
      setActionError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function addCard() {
    setActionError(null);
    try {
      await api(`/admin/users/${id}/payment-methods`, {
        method: 'POST',
        body: card.type === 'cash' ? { type: 'cash', brand: 'Cash on Delivery' } : card,
      });
      setCardOpen(false);
      await reload();
    } catch (e) {
      setActionError((e as Error).message);
    }
  }

  async function removeCard(pmId: string) {
    if (!confirm('Remove this payment method?')) return;
    await api(`/admin/payment-methods/${pmId}`, { method: 'DELETE' }).catch((e) => setActionError(e.message));
    await reload();
  }

  return (
    <>
      <PageHeader
        back="/users"
        title={
          <span className="flex items-center gap-3">
            {user.firstName} {user.lastName}
            <Badge tone={user.status === 'active' ? 'green' : 'red'}>{user.status === 'active' ? 'Active' : 'Blocked'}</Badge>
          </span>
        }
        subtitle={`${user.email} · joined ${dateTime(user.createdAt)} · last sign-in ${dateTime(user.lastLoginAt)}`}
        actions={
          user.status === 'active' ? (
            <Button variant="danger" loading={busy} onClick={() => confirm('Block this account? They are signed out right away.') && patch({ status: 'blocked' })}>Block account</Button>
          ) : (
            <Button loading={busy} onClick={() => patch({ status: 'active' })}>Unblock account</Button>
          )
        }
      />
      {actionError && <div className="mb-4"><ErrorBox message={actionError} /></div>}

      <div className="grid gap-6 lg:grid-cols-3">
        <Card title="Account">
          <div className="space-y-4">
            <Field label="Role" hint={me?.role !== 'admin' ? 'Only admins can change roles' : 'Staff and admins can sign in to this panel'}>
              <Select value={user.role} disabled={me?.role !== 'admin' || busy} onChange={(e) => patch({ role: e.target.value })}>
                <option value="customer">Customer</option>
                <option value="staff">Staff</option>
                <option value="admin">Admin</option>
              </Select>
            </Field>
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-500">Email verified</span>
              {user.emailVerified ? <Badge tone="green">Yes</Badge> : <Button variant="secondary" onClick={() => patch({ emailVerified: true })}>Mark verified</Button>}
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-gray-500">Phone</span>
              <span>{user.phone ?? '—'}</span>
            </div>
          </div>
        </Card>

        <Card title={`Addresses (${user.addresses.length})`}>
          <ul className="space-y-3 text-sm">
            {user.addresses.map((a) => (
              <li key={a.id}>
                <div className="font-medium text-gray-800">
                  {a.label} {a.isDefault && <Badge tone="blue">Default</Badge>}
                </div>
                <div className="text-gray-500">{[a.apartment, a.street, a.city].filter(Boolean).join(', ')}</div>
                <div className="text-xs text-gray-400">{a.latitude != null ? `${a.latitude.toFixed(4)}, ${a.longitude?.toFixed(4)}` : 'No map pin — home uses the city default'}</div>
              </li>
            ))}
            {!user.addresses.length && <li className="text-gray-500">No saved addresses.</li>}
          </ul>
        </Card>

        <Card title="Payment methods" actions={<Button variant="ghost" onClick={() => setCardOpen(true)}>+ Add</Button>}>
          <ul className="space-y-2 text-sm">
            {user.paymentMethods.map((p) => (
              <li key={p.id} className="flex items-center justify-between">
                <span>
                  {p.brand} {p.last4 && `•••• ${p.last4}`} {p.expiry && <span className="text-gray-400">({p.expiry})</span>} {p.isDefault && <Badge tone="blue">Default</Badge>}
                  {p.last4 === '0002' && <Badge tone="amber">Always declined</Badge>}
                </span>
                <button className="text-xs text-red-600 hover:underline" onClick={() => removeCard(p.id)}>Remove</button>
              </li>
            ))}
            {!user.paymentMethods.length && <li className="text-gray-500">None — the customer can’t check out yet.</li>}
          </ul>
        </Card>
      </div>

      <Card title={`Orders (${user.orders.length})`} padded={false} className="mt-6">
        <OrdersTable rows={user.orders} />
      </Card>

      <Modal open={cardOpen} title="Add test payment method" onClose={() => setCardOpen(false)} footer={<><Button variant="secondary" onClick={() => setCardOpen(false)}>Cancel</Button><Button onClick={addCard}>Add</Button></>}>
        <p className="text-sm text-gray-500">No card provider is connected yet, so this only saves a test card. Last 4 “0002” is always declined (on staging) so you can test failed payments.</p>
        <Field label="Type">
          <Select value={card.type} onChange={(e) => setCard({ ...card, type: e.target.value })}>
            <option value="card">Card</option>
            <option value="cash">Cash on delivery</option>
          </Select>
        </Field>
        {card.type === 'card' && (
          <div className="grid grid-cols-3 gap-3">
            <Field label="Brand"><Input value={card.brand} onChange={(e) => setCard({ ...card, brand: e.target.value })} /></Field>
            <Field label="Last 4"><Input value={card.last4} maxLength={4} onChange={(e) => setCard({ ...card, last4: e.target.value })} /></Field>
            <Field label="Expiry"><Input value={card.expiry} placeholder="12/29" onChange={(e) => setCard({ ...card, expiry: e.target.value })} /></Field>
          </div>
        )}
      </Modal>
    </>
  );
}
