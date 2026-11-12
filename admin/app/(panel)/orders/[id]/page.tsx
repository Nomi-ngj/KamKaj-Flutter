'use client';

import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useState } from 'react';
import { api } from '@/lib/api';
import { useApi } from '@/lib/hooks';
import { dateTime, money, ORDER_STATUS_LABEL, ORDER_STATUS_TONE } from '@/lib/format';
import { Badge, Button, Card, ErrorBox, Field, Input, Loading, Modal, Notice, PageHeader, Table, Td, Textarea } from '@/components/ui';

interface OrderDetail {
  id: string;
  number: number;
  status: string;
  userId: string;
  storeId: string;
  storeName: string;
  storeAddress: string;
  customerName: string;
  customerEmail: string;
  fromText: string;
  toText: string;
  distanceKm: number | null;
  subtotal: number;
  deliveryFee: number;
  serviceFee: number;
  total: number;
  courierName: string | null;
  courierInfo: string | null;
  statusNote: string | null;
  cancelReason: string | null;
  createdAt: string;
  estimatedAt: string | null;
  paidAt: string | null;
  deliveredAt: string | null;
  payment: { type: string; brand: string; last4: string } | null;
  items: { id: string; productName: string; unitPrice: number; quantity: number; note: string | null; lineTotal: number }[];
  events: { id: string; status: string; note: string | null; actor: string; createdAt: string }[];
  allowedNextStatuses: string[];
}

const ACTION_LABEL: Record<string, string> = {
  pending: 'Mark as paid',
  inTransit: 'Send out for delivery',
  delivered: 'Mark delivered',
  cancelled: 'Cancel order',
};

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: order, setData, error, loading, reload } = useApi<OrderDetail>(`/admin/orders/${id}`);
  const [target, setTarget] = useState<string | null>(null);
  const [form, setForm] = useState({ note: '', cancelReason: '', courierName: '', courierInfo: '' });
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  if (loading && !order) return <Loading />;
  if (error) return <ErrorBox message={error} onRetry={reload} />;
  if (!order) return null;

  function open(status: string) {
    setActionError(null);
    setForm({ note: '', cancelReason: '', courierName: order!.courierName ?? '', courierInfo: order!.courierInfo ?? '' });
    setTarget(status);
  }

  async function submit() {
    if (!target) return;
    setBusy(true);
    setActionError(null);
    try {
      const updated = await api<OrderDetail>(`/admin/orders/${id}/status`, { method: 'PATCH', body: { status: target, ...form } });
      setData(updated);
      setTarget(null);
    } catch (e) {
      setActionError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <PageHeader
        back="/orders"
        title={
          <span className="flex items-center gap-3">
            Order #{order.number} <Badge tone={ORDER_STATUS_TONE[order.status]}>{ORDER_STATUS_LABEL[order.status]}</Badge>
          </span>
        }
        subtitle={`Placed ${dateTime(order.createdAt)}`}
        actions={order.allowedNextStatuses.map((s) => (
          <Button key={s} variant={s === 'cancelled' ? 'danger' : 'primary'} onClick={() => open(s)}>
            {ACTION_LABEL[s] ?? s}
          </Button>
        ))}
      />

      {order.statusNote && <div className="mb-4"><Notice>Customer sees: “{order.statusNote}”</Notice></div>}
      {order.cancelReason && <div className="mb-4"><Notice tone="amber">Cancel reason: {order.cancelReason}</Notice></div>}

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card title="Items" padded={false}>
            <Table head={['Item', 'Price', 'Qty', 'Total']}>
              {order.items.map((i) => (
                <tr key={i.id}>
                  <Td>
                    <div className="font-medium text-gray-800">{i.productName}</div>
                    {i.note && <div className="text-xs text-gray-500">Note: {i.note}</div>}
                  </Td>
                  <Td>{money(i.unitPrice)}</Td>
                  <Td>{i.quantity}</Td>
                  <Td>{money(i.lineTotal)}</Td>
                </tr>
              ))}
            </Table>
            <dl className="space-y-1 border-t border-gray-100 px-4 py-3 text-sm">
              <Row label="Subtotal" value={money(order.subtotal)} />
              <Row label="Delivery fee" value={order.deliveryFee ? money(order.deliveryFee) : 'Free'} />
              <Row label="Service fee" value={money(order.serviceFee)} />
              <Row label={<strong>Total</strong>} value={<strong>{money(order.total)}</strong>} />
            </dl>
          </Card>

          <Card title="History">
            <ol className="space-y-3">
              {order.events.map((e) => (
                <li key={e.id} className="flex gap-3 text-sm">
                  <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-brand" />
                  <div>
                    <div className="font-medium text-gray-800">
                      {ORDER_STATUS_LABEL[e.status]} <span className="font-normal text-gray-500">· {dateTime(e.createdAt)}</span>
                    </div>
                    <div className="text-gray-500">
                      {e.note ? `${e.note} · ` : ''}by {e.actor}
                    </div>
                  </div>
                </li>
              ))}
            </ol>
          </Card>
        </div>

        <div className="space-y-6">
          <Card title="Customer">
            <Link href={`/users/${order.userId}`} className="font-medium text-brand hover:underline">{order.customerName}</Link>
            <p className="text-sm text-gray-500">{order.customerEmail}</p>
          </Card>
          <Card title="Delivery">
            <dl className="space-y-3 text-sm">
              <div>
                <dt className="text-gray-500">From</dt>
                <dd><Link href={`/stores/${order.storeId}`} className="text-brand hover:underline">{order.storeName}</Link><br />{order.storeAddress}</dd>
              </div>
              <div>
                <dt className="text-gray-500">To</dt>
                <dd>{order.toText}</dd>
              </div>
              {order.distanceKm != null && <Row label="Distance" value={`${order.distanceKm.toFixed(1)} km`} />}
              <Row label="ETA" value={dateTime(order.estimatedAt)} />
              {order.deliveredAt && <Row label="Delivered" value={dateTime(order.deliveredAt)} />}
              <Row label="Courier" value={[order.courierName, order.courierInfo].filter(Boolean).join(' · ') || '—'} />
            </dl>
          </Card>
          <Card title="Payment">
            <p className="text-sm">
              {order.payment ? `${order.payment.brand}${order.payment.last4 ? ` •••• ${order.payment.last4}` : ''}` : '—'}
            </p>
            <p className="text-xs text-gray-500">{order.paidAt ? `Paid ${dateTime(order.paidAt)}` : order.payment?.type === 'cash' ? 'Collect cash on delivery' : 'Not paid'}</p>
          </Card>
        </div>
      </div>

      <Modal
        open={!!target}
        title={target ? ACTION_LABEL[target] ?? target : ''}
        onClose={() => setTarget(null)}
        footer={
          <>
            <Button variant="secondary" onClick={() => setTarget(null)}>Close</Button>
            <Button variant={target === 'cancelled' ? 'danger' : 'primary'} loading={busy} onClick={submit}>Confirm</Button>
          </>
        }
      >
        {actionError && <ErrorBox message={actionError} />}
        {target === 'cancelled' ? (
          <Field label="Cancel reason" hint="The customer sees this in the app.">
            <Textarea value={form.cancelReason} onChange={(e) => setForm({ ...form, cancelReason: e.target.value })} placeholder="e.g. Item out of stock" />
          </Field>
        ) : (
          <>
            {target === 'inTransit' && (
              <div className="grid grid-cols-2 gap-3">
                <Field label="Courier name">
                  <Input value={form.courierName} onChange={(e) => setForm({ ...form, courierName: e.target.value })} />
                </Field>
                <Field label="Courier info" hint="Shown in the app">
                  <Input value={form.courierInfo} placeholder="Express Courier • 2 parcels" onChange={(e) => setForm({ ...form, courierInfo: e.target.value })} />
                </Field>
              </div>
            )}
            <Field label="Status message (optional)" hint="Shown under the order in the app, e.g. “Driver assigned • On schedule”.">
              <Input value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} />
            </Field>
          </>
        )}
      </Modal>
    </>
  );
}

function Row({ label, value }: { label: React.ReactNode; value: React.ReactNode }) {
  return (
    <div className="flex justify-between gap-4">
      <dt className="text-gray-500">{label}</dt>
      <dd className="text-right text-gray-800">{value}</dd>
    </div>
  );
}
