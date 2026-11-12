'use client';

import { Suspense, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Page } from '@/lib/api';
import { useApi, useDebounced } from '@/lib/hooks';
import { ORDER_STATUS_LABEL } from '@/lib/format';
import { Button, Card, ErrorBox, Input, Loading, PageHeader, Pagination } from '@/components/ui';
import { OrderRow, OrdersTable } from '@/components/orders-table';

const FILTERS = [
  { value: '', label: 'All' },
  { value: 'awaitingPayment,pending,inTransit', label: 'Active' },
  ...Object.entries(ORDER_STATUS_LABEL).map(([value, label]) => ({ value, label })),
];

function OrdersList() {
  const router = useRouter();
  const params = useSearchParams();
  const status = params.get('status') ?? '';
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const q = useDebounced(search);
  const { data, error, loading, reload } = useApi<Page<OrderRow>>('/admin/orders', { status, search: q, page, pageSize: 20 });

  return (
    <>
      <PageHeader title="Orders" subtitle="Open an order to change its status, assign a courier or cancel it." actions={<Button variant="secondary" onClick={reload}>Refresh</Button>} />
      <div className="mb-4 flex flex-wrap items-center gap-2">
        {FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => {
              setPage(1);
              router.replace(f.value ? `/orders?status=${f.value}` : '/orders');
            }}
            className={`rounded-full px-3 py-1.5 text-sm ${status === f.value ? 'bg-brand text-white' : 'bg-white text-gray-600 ring-1 ring-gray-200 hover:bg-gray-50'}`}
          >
            {f.label}
          </button>
        ))}
        <Input className="ml-auto max-w-xs" placeholder="Search # number, email or store" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
      </div>
      {error && <ErrorBox message={error} onRetry={reload} />}
      <Card padded={false}>
        {loading && !data ? <Loading /> : <OrdersTable rows={data?.data ?? []} />}
        {data && <Pagination page={data.page} pageSize={data.pageSize} total={data.total} onPage={setPage} />}
      </Card>
    </>
  );
}

export default function OrdersPage() {
  return (
    <Suspense fallback={<Loading />}>
      <OrdersList />
    </Suspense>
  );
}
