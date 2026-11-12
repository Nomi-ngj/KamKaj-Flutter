'use client';

import { useState } from 'react';
import { api, Page } from '@/lib/api';
import { useApi } from '@/lib/hooks';
import { timeAgo, Tone } from '@/lib/format';
import { Badge, Card, ErrorBox, Loading, PageHeader, Pagination, Select, Table, Td } from '@/components/ui';

interface RideRow {
  id: string;
  status: string;
  vehicle: string;
  customerName: string;
  customerEmail: string;
  pickupLat: number | null;
  pickupLng: number | null;
  note: string | null;
  createdAt: string;
}

const STATUSES = ['requested', 'accepted', 'inProgress', 'completed', 'cancelled'];
const TONE: Record<string, Tone> = { requested: 'amber', accepted: 'blue', inProgress: 'violet', completed: 'green', cancelled: 'red' };

export default function RidesPage() {
  const [status, setStatus] = useState('');
  const [page, setPage] = useState(1);
  const { data, setData, error, loading, reload } = useApi<Page<RideRow>>('/admin/rides', { status, page, pageSize: 25 });
  const [rowError, setRowError] = useState<string | null>(null);

  async function update(id: string, next: string) {
    setRowError(null);
    try {
      await api(`/admin/rides/${id}`, { method: 'PATCH', body: { status: next } });
      if (data) setData({ ...data, data: data.data.map((r) => (r.id === id ? { ...r, status: next } : r)) });
    } catch (e) {
      setRowError((e as Error).message);
    }
  }

  return (
    <>
      <PageHeader title="Ride requests" subtitle="Rides are requested from the Services tab in the app. Driver matching isn’t automated yet." />
      <div className="mb-4">
        <Select className="max-w-48" value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
          <option value="">All statuses</option>
          {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
        </Select>
      </div>
      {(error || rowError) && <ErrorBox message={(error || rowError)!} onRetry={reload} />}
      <Card padded={false}>
        {loading && !data ? (
          <Loading />
        ) : (
          <Table head={['Customer', 'Vehicle', 'Pickup', 'Requested', 'Status']} empty={!data?.data.length}>
            {data?.data.map((r) => (
              <tr key={r.id}>
                <Td>
                  <div className="font-medium text-gray-800">{r.customerName}</div>
                  <div className="text-xs text-gray-500">{r.customerEmail}</div>
                </Td>
                <Td>{r.vehicle}</Td>
                <Td className="text-xs text-gray-500">
                  {r.pickupLat != null ? (
                    <a className="text-brand hover:underline" href={`https://www.google.com/maps?q=${r.pickupLat},${r.pickupLng}`} target="_blank" rel="noreferrer">
                      {r.pickupLat.toFixed(4)}, {r.pickupLng?.toFixed(4)}
                    </a>
                  ) : 'Not sent'}
                </Td>
                <Td className="text-gray-500">{timeAgo(r.createdAt)}</Td>
                <Td>
                  <div className="flex items-center gap-2">
                    <Badge tone={TONE[r.status]}>{r.status}</Badge>
                    <Select className="w-36 py-1 text-xs" value={r.status} onChange={(e) => update(r.id, e.target.value)}>
                      {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
                    </Select>
                  </div>
                </Td>
              </tr>
            ))}
          </Table>
        )}
        {data && <Pagination page={data.page} pageSize={data.pageSize} total={data.total} onPage={setPage} />}
      </Card>
    </>
  );
}
